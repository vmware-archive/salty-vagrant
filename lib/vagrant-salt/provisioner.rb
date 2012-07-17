module VagrantSalt
  class Provisioner < Vagrant::Provisioners::Base
    class Config < Vagrant::Config::Base
      attr_accessor :minion_config
      attr_accessor :minion_key
      attr_accessor :minion_pub
      attr_accessor :master
      attr_accessor :run_highstate
      attr_accessor :salt_file_root_path
      attr_accessor :salt_file_root_guest_path
      attr_accessor :salt_pillar_root_path
      attr_accessor :salt_pillar_root_guest_path

      def minion_config; @minion_config || "salt/minion.conf"; end
      def minion_key; @minion_key || false; end
      def minion_pub; @minion_pub || false; end
      def master; @master || false; end
      def run_highstate; @run_highstate || false; end
      def salt_file_root_path; @salt_file_root_path || "salt/roots/salt"; end
      def salt_file_root_guest_path; @salt_file_root_guest_path || "/srv/salt"; end
      def salt_pillar_root_path; @salt_pillar_root_path || "salt/roots/pillar"; end
      def salt_pillar_root_guest_path; @salt_pillar_root_guest_path || "/srv/pillar"; end

      def expanded_path(root_path, rel_path)
        Pathname.new(rel_path).expand_path(root_path)
      end
    end

    def self.config_class
      Config
    end

    def prepare
      # Calculate the paths we're going to use based on the environment
      @expanded_minion_config_path = config.expanded_path(env[:root_path], config.minion_config)
      if !config.master
        env[:ui].info "Adding state tree folders."
        @expanded_salt_file_root_path = config.expanded_path(env[:root_path], config.salt_file_root_path)
        @expanded_salt_pillar_root_path = config.expanded_path(env[:root_path], config.salt_pillar_root_path)
        share_salt_file_root_path
        share_salt_pillar_root_path
      end

      if config.minion_key
        @expanded_minion_key_path = config.expanded_path(env[:root_path], config.minion_key)
        @expanded_minion_pub_path = config.expanded_path(env[:root_path], config.minion_pub)
      end
    end

    def share_salt_file_root_path
      env[:ui].info "Sharing file root folder."
      env[:vm].config.vm.share_folder("salt_file_root", config.salt_file_root_guest_path, @expanded_salt_file_root_path)
    end

    def share_salt_pillar_root_path
      env[:ui].info "Sharing pillar root path."
      env[:vm].config.vm.share_folder("salt_pillar_root", config.salt_pillar_root_guest_path, @expanded_salt_pillar_root_path)
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

    def add_salt_repo
      env[:ui].info "Adding Salt PPA."
      env[:vm].channel.sudo("apt-get -q -y install python-software-properties")
      env[:vm].channel.sudo("add-apt-repository -y ppa:saltstack/salt")
      env[:vm].channel.sudo("apt-get -q -y update")
    end

    def install_salt_minion
      env[:ui].info "Installing salt minion."
      env[:vm].channel.sudo("apt-get -q -y install salt-minion")
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
      env[:vm].channel.upload(@expanded_minion_config_path.to_s, "/tmp/minion")
      env[:vm].channel.sudo("mv /tmp/minion /etc/salt/minion")
    end

    def upload_minion_keys
      env[:ui].info "Uploading minion key."
      env[:vm].channel.upload(@expanded_minion_key_path.to_s, "/tmp/minion.pem")
      env[:vm].channel.sudo("mv /tmp/minion.pem /etc/salt/pki/minion.pem")
      env[:vm].channel.upload(@expanded_minion_pub_path.to_s, "/tmp/minion.pub")
      env[:vm].channel.sudo("mv /tmp/minion.pub /etc/salt/pki/minion.pub")
    end

    def provision!

      verify_shared_folders([config.salt_file_root_guest_path, config.salt_pillar_root_guest_path])

      if !salt_exists
        add_salt_repo
        install_salt_minion
      end

      upload_minion_config

      if config.minion_key
        upload_minion_keys
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