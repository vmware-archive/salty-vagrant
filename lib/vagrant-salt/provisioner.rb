module Vagrant
  module Provisioners

    class Salt < Base

      def self.source_root
        @source_root ||= Pathname.new(File.expand_path('../../../', __FILE__))
      end

      I18n.load_path << File.expand_path("templates/locales/en.yml", Salt.source_root)
      I18n.reload!

      class SaltError < Vagrant::Errors::VagrantError
        error_namespace("vagrant.provisioners.salt")
      end

      class Config < Vagrant::Config::Base
        ## salty-vagrant options
        attr_accessor :minion_config
        attr_accessor :minion_key
        attr_accessor :minion_pub
        attr_accessor :master_config
        attr_accessor :master_key
        attr_accessor :master_pub
        attr_accessor :run_highstate
        attr_accessor :always_install
        attr_accessor :accept_keys
        attr_accessor :bootstrap_script
        attr_accessor :verbose

        ## bootstrap options
        attr_accessor :temp_config_dir
        attr_accessor :install_type
        attr_accessor :install_args
        attr_accessor :install_master
        attr_accessor :install_syndic
        attr_accessor :no_minion
        attr_accessor :bootstrap_options
      end

      def self.config_class()
        Config
      end

      ## Utilities
      def expanded_path(rel_path)
        Pathname.new(rel_path).expand_path(env[:root_path])
      end

      def binaries_found()
        ## Determine States, ie: install vs configure
        desired_binaries = []
        if !config.no_minion
          desired_binaries.push('salt-minion')
          desired_binaries.push('salt-call')
        end

        if config.install_master
          desired_binaries.push('salt-master')
        end

        if config.install_syndic
          desired_binaries.push('salt-syndic')
        end

        found = true
        for binary in desired_binaries
          env[:ui].info "Checking if %s is installed" % binary
          if !env[:vm].channel.test("which %s" % binary)
            env[:ui].info "%s was not found." % binary
            found = false
          else
            env[:ui].info "%s found" % binary
          end
        end

        return found
      end

      def need_configure()
        config.minion_config or config.minion_key
      end

      def need_install()
        if config.always_install
          return true
        else
          return !binaries_found()
        end
      end

      def temp_config_dir()
        return config.temp_config_dir || "/tmp"
      end

      def bootstrap_options(install, configure, config_dir)
        options = ""

        ## Any extra options passed to bootstrap
        if config.bootstrap_options
          options = "%s %s" % [options, config.bootstrap_options]
        end

        if configure
          options = "%s -c %s" % [options, config_dir]
        end

        if configure and !install
          options = "%s -C" % options
        else

          if config.install_master
            options = "%s -M" % options
          end

          if config.install_syndic
            options = "%s -S" % options
          end

          if config.no_minion
            options = "%s -N" % options
          end

          if config.install_type
            options = "%s %s" % [options, config.install_type]
          end

          if config.install_args
            options = "%s %s" % [options, config.install_args]
          end 
        end

        return options
      end

      def sanity_check()
        # Make sure all config options work together
        if config.minion_key or config.minion_pub
          if !config.minion_key or !config.minion_pub
            raise SaltError, :missing_key
          end
        end

        if config.master_key or config.master_pub
          if !config.minion_key or !config.minion_pub
            raise SaltError, :missing_key
          end
        end

        if config.accept_keys and config.no_minion
          raise SaltError, :accept_key_no_minion
        elsif config.accept_keys and !config.install_master
          raise SaltError, :accept_key_no_master
        end

        if config.install_master and \
          !config.no_minion and \
          !config.accept_keys and \
          config.run_highstate
          raise SaltError, :must_accept_keys
        end


      end

      ## Actions
      def upload_configs()
        if config.minion_config
          env[:ui].info "Copying salt minion config to vm."
          env[:vm].channel.upload(expanded_path(config.minion_config).to_s, temp_config_dir + "/minion")
        end

        if config.master_config
          env[:ui].info "Copying salt master config to vm."
          env[:vm].channel.upload(expanded_path(config.master_config).to_s, temp_config_dir + "/master")
        end
      end


      def upload_keys()
        if config.minion_key and config.minion_pub
          env[:ui].info "Uploading minion keys."
          env[:vm].channel.upload(expanded_path(config.minion_key).to_s, temp_config_dir + "/minion.pem")
          env[:vm].channel.upload(expanded_path(config.minion_pub).to_s, temp_config_dir + "/minion.pub")
        end

        if config.master_key and config.master_pub
          env[:ui].info "Uploading master keys."
          env[:vm].channel.upload(expanded_path(config.master_key).to_s, temp_config_dir + "/master.pem")
          env[:vm].channel.upload(expanded_path(config.master_pub).to_s, temp_config_dir + "/master.pub")
        end
      end

      def get_bootstrap()
        if config.bootstrap_script
          bootstrap_abs_path = expanded_path(config.bootstrap_script)
        else
          bootstrap_abs_path = Pathname.new("../../../scripts/bootstrap-salt.sh").expand_path(__FILE__)
        end
        return bootstrap_abs_path
      end

      def run_bootstrap_script()
        install = need_install()
        configure = need_configure()
        config_dir = temp_config_dir()
        options = bootstrap_options(install, configure, config_dir)

        if configure or install

          if configure and !install
            env[:ui].info "Salt binaries found. Configuring only."
          else
            env[:ui].info "Bootstrapping Salt... (this may take a while)"
          end
          
          bootstrap_path = get_bootstrap()
          bootstrap_destination = File.join(config_dir, "bootstrap_salt.sh")
          env[:vm].channel.upload(bootstrap_path.to_s, bootstrap_destination)
          env[:vm].channel.sudo("chmod +x %s" % bootstrap_destination)
          bootstrap = env[:vm].channel.sudo("%s %s" % [bootstrap_destination, options]) do |type, data|
            if data[0] == "\n"
              # Remove any leading newline but not whitespace. If we wanted to
              # remove newlines and whitespace we would have used data.lstrip
              data = data[1..-1]
            end
            if config.verbose
              env[:ui].info(data.rstrip)
            end
          end
          if !bootstrap
            raise SaltError, :bootstrap_failed
          end

          if configure and !install
            env[:ui].info "Salt successfully configured!"
          elsif configure and install
            env[:ui].info "Salt successfully configured and installed!"
          elsif !configure and install
            env[:ui].info "Salt successfully installed!"
          end
        
        else
          env[:ui].info "Salt did not need installing or configuring."
        end
      end

      def accept_keys()
        if config.accept_keys
          if !env[:vm].channel.test("which salt-key")
            env[:ui].info "Salt-key not installed!"
          else
            env[:ui].info "Waiting for minion key..."
            key_staged = false
            attempts = 0
            while !key_staged
              attempts += 1 
              env[:vm].channel.sudo("salt-key -l pre | wc -l") do |type, output|
                begin
                  output = Integer(output)
                  if output > 1
                    key_staged = true
                  end
                rescue
                end
              end
              sleep 1
              if attempts > 10
                raise SaltError, :not_received_minion_key
              end
            end

            env[:ui].info "Accepting minion key."
            env[:vm].channel.sudo("salt-key -A")
          end
        end
      end

      def call_highstate()
        if config.run_highstate
          env[:ui].info "Calling state.highstate... (this may take a while)"
          env[:vm].channel.sudo("salt-call saltutil.sync_all")
          env[:vm].channel.sudo("salt-call state.highstate -l debug") do |type, data|
            if config.verbose
              env[:ui].info(data)
            end
          end
        else
          env[:ui].info "run_highstate set to false. Not running state.highstate."
        end
      end

      def prepare
        sanity_check
      end


      ## Run the provisioner!
      def provision!
        upload_configs
        upload_keys
        run_bootstrap_script
        accept_keys
        call_highstate
      end
    end
  end
end