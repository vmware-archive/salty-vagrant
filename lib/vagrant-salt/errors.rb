require "vagrant"

module VagrantPlugins
  module Salt
    module Errors
      class SaltError < Vagrant::Errors::VagrantError
        error_namespace("salt")
      end

      class SaltCallHighstateError < SaltError
        error_key("highstate_failed")

        def initialize(salt_call_output)
          super :salt_call_output => salt_call_output
        end
      end
    end
  end
end