module VagrantPlugins
  module Salt
    # Takes in any number of stdout/stderr lines taken from the output of
    # 'salt-call state.highstate', via #parse.  Then the appropriate error lines
    # are made available if there were any failures.
    #
    # This completely depends on the 'highstate' format of the output of the
    # 'salt-call state.highstate' command not changing, so it could potentially be a bit
    # brittle.  We could simply use the json or yaml format but that doesn't
    # look as nice as the highstate format.
    #
    # Currently error handling has to be done this way because the
    # return code of the salt-call is always 0.  There is an issue open for
    # that, so there'll be a less brittle solution available in the future!
    # https://github.com/saltstack/salt/issues/4176
    #
    # As of right now, the output of the salt-call command looks like this when
    # there's an error:
    #
    # ----------
    # State: - cmd
    # Name:      /usr/local/bin/something
    # Function:  run
    #     Result:    False
    #     Comment:   One or more requisite failed
    #     Changes:
    class StateResultsParser

      # Takes in the type (:stdout/:stdin) and data from part of the output
      # of the salt-call state.highstate.
      def parse(type, data)
        # We only care about stdout lines.
        parse_stdout data if type == :stdout
      end

      # Returns true if there was no state output at all - usually caused by a mis-
      # configuration in the sls files or something along those lines.
      def saw_no_states?
        !any_results?
      end

      # Returns true if there were any failed states.
      def saw_failed_states?
        !failed_state_output.empty?
      end

      # Returns the complete set of stdout lines from the salt-call.
      def all_of_stdout
        @all_of_stdout ||= ""
      end

      # Returns all of the 'red' lines from the output of the salt-call (i.e. all
      # the failed states).
      def red_lines
        failed_state_output
      end

      private
      # Helper class that knows what the salt-call output looks like.  It takes
      # in one line of that output and can tell me useful stuff like the result
      # from one of the states.
      class Line

        def initialize(line_string)
          @line_string = line_string
        end

        def looks_like_a_header?
          @line_string =~ /^-+\n$/
        end

        def is_a_state_result?
          result != nil
        end

        def result
          if @line_string =~ /^\s+Result:\s+(True|False)\n$/
            $1 == "True" ? true : false
          end
        end

        def to_s
          @line_string
        end
      end

      # Reads the output from salt-call state.highstate line by line and stores
      # the parts that look like results.
      def parse_stdout(data)
        data.each_line do |line|
          parse_line Line.new(line)
        end
        save_failed_state_output!
      end

      # Looks at the current line (as a Line object) and stores the output for
      # any failed states.
      def parse_line(line)
        reset_current_state! if line.looks_like_a_header?

        # Store each line from this state in case it's a failed state.
        current_state << line.to_s
        all_of_stdout << line.to_s

        if line.is_a_state_result?
          @any_results = true
          current_state_is_unsuccessful! if line.result == false
        end
      end

      def any_results?
        @any_results == true
      end

      def failed_state_output
        @failed_state_output ||= ""
      end

      # Appends the current_state string if there is one and if it represents
      # an unsuccessful state.
      def save_failed_state_output!
        failed_state_output << current_state if current_state_is_unsuccessful?
      end

      # Resets the current_state string back to nothing.
      def reset_current_state!
        save_failed_state_output!
        @current_state = nil
        @current_state_is_unsuccessful = nil
      end

      def current_state_is_unsuccessful!
        @current_state_is_unsuccessful = true
      end

      def current_state_is_unsuccessful?
        @current_state_is_unsuccessful
      end

      def current_state
        @current_state ||= ""
      end

    end
  end
end