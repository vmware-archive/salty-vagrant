module VagrantSalt
  class Provisioner < Vagrant::Provisioners::Base
    class Config < Vagrant::Config::Base
      attr_accessor :minion_config
      attr_accessor :temp_config_dir
      attr_accessor :minion_key
      attr_accessor :minion_pub
      attr_accessor :run_highstate
      attr_accessor :salt_install_type
      attr_accessor :salt_install_args

      def minion_config; @minion_config || "salt/minion.conf"; end
      def temp_config_dir; @temp_config_dir || "/tmp/"; end
      def minion_key; @minion_key || false; end
      def minion_pub; @minion_pub || false; end
      def run_highstate; @run_highstate || false; end
      def salt_install_type; @salt_install_type || ''; end
      def salt_install_args; @salt_install_args || ''; end


      def expanded_path(root_path, rel_path)
        Pathname.new(rel_path).expand_path(root_path)
      end

      def bootstrap_options
        options = ''
        if temp_config_dir
          options = options + '-c %s' % temp_config_dir
        end
        options = options + ' %s %s' % [salt_install_type, salt_install_args]
        return options
      end
    end

    def self.config_class
      Config
    end

    def prepare
      # Calculate the paths we're going to use based on the environment
      @expanded_minion_config_path = config.expanded_path(env[:root_path], config.minion_config)

      if config.minion_key
        @expanded_minion_key_path = config.expanded_path(env[:root_path], config.minion_key)
        @expanded_minion_pub_path = config.expanded_path(env[:root_path], config.minion_pub)
      end
    end

    def salt_exists
      env[:ui].info "Checking for salt binaries..."
      if env[:vm].channel.test("which salt-call") and
         env[:vm].channel.test("which salt-minion")
        return true
      end
      env[:ui].info "Salt binaries not found."
      return false
    end

    def bootstrap_salt_minion
      env[:ui].info "Bootstrapping salt-minion on VM..."
      @expanded_bootstrap_script_path = config.expanded_path(__FILE__, "../../../scripts/bootstrap-salt-minion.sh")
      env[:vm].channel.upload(@expanded_bootstrap_script_path.to_s, "/tmp/bootstrap-salt-minion.sh")
      env[:vm].channel.sudo("chmod +x /tmp/bootstrap-salt-minion.sh")
      bootstrap = env[:vm].channel.sudo("/tmp/bootstrap-salt-minion.sh %s" % config.bootstrap_options) do |type, data|
        if data[0] == "\n"
          # Remove any leading newline but not whitespace. If we wanted to
          # remove newlines and whitespace we would have used data.lstrip
          data = data[1..-1]
        end
        env[:ui].info(data.rstrip)
      end
      if !bootstrap
        raise "Failed to bootstrap salt-minion on VM, see /var/log/bootstrap-salt-minion.log on VM."
      end
      env[:ui].info "Salt binaries installed on VM."
    end

    def accept_minion_key
      env[:ui].info "Accepting minion key."
      env[:vm].channel.sudo("salt-key -A")
    end

    def call_highstate
      if config.run_highstate
        env[:ui].info "Calling state.highstate"
        env[:vm].channel.sudo("salt-call saltutil.sync_all")
        env[:vm].channel.sudo("salt-call state.highstate") do |type, data|
          env[:ui].info(data)
        end
      else
        env[:ui].info "run_highstate set to false. Not running state.highstate."
      end
    end

    def upload_minion_config
      env[:ui].info "Copying salt minion config to vm."
      env[:vm].channel.upload(@expanded_minion_config_path.to_s, config.temp_config_dir + "minion")
    end

    def upload_minion_keys
      env[:ui].info "Uploading minion key."
      env[:vm].channel.upload(@expanded_minion_key_path.to_s, config.temp_config_dir + "minion.pem")
      env[:vm].channel.upload(@expanded_minion_pub_path.to_s, config.temp_config_dir + "minion.pub")
    end

    def provision!

      upload_minion_config

      if config.minion_key
        upload_minion_keys
      end

      if !salt_exists
        bootstrap_salt_minion
      else
        # If salt is installed, we still want to copy over the minion conf if
        # it's specified in the Vagrantfile
        if config.minion_config
          env[:vm].channel.sudo("cp #{config.temp_config_dir}minion /etc/salt/minion")
        end
      end

      call_highstate
    end

    def verify_shared_folders(folders)
      folders.each do |folder|
        # @logger.debug("Checking for shared folder: #{folder}")
        env[:ui].info "Checking shared folder #{folder}"
        if !env[:vm].channel.test("test -d #{folder}")
          raise "Missing folder #{folder}"
        end
      end
    end
  end

end

# vim: fenc=utf-8 spell spl=en cc=80 sts=2 sw=2 et
