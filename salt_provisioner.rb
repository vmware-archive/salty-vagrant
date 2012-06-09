class SaltProvisioner < Vagrant::Provisioners::Base

  class Config < Vagrant::Config::Base
    attr_accessor :minion_config
    attr_accessor :salt_config_path
    attr_accessor :salt_config_guest_path
    attr_accessor :salt_file_root_path
    attr_accessor :salt_file_root_guest_path

    def minion_config; @minion_config || "minion"; end
    def salt_config_path; @salt_config_path || "salt/config"; end
    def salt_config_guest_path; @salt_config_guest_path || "/etc/salt/"; end
    def salt_file_root_path; @salt_file_root_path || "salt/file_root"; end
    def salt_file_root_guest_path; @salt_file_root_guest_path || "/srv/"; end

    # Returns the manifests path expanded relative to the root path of the
    # environment.
    def expanded_salt_config_path(root_path)
      Pathname.new(salt_config_path).expand_path(root_path)
    end

    def expanded_salt_file_root_path(root_path)
      Pathname.new(salt_file_root_path).expand_path(root_path)
    end
  end

  def self.config_class
    Config
  end

  def share_salt_config_path
    env[:vm].config.vm.share_folder("salt_config", config.salt_config_guest_path, @expanded_salt_config_path)
  end

  def share_salt_file_root_path
    env[:vm].config.vm.share_folder("salt_file_root", config.salt_file_root_guest_path, @expanded_salt_file_root_path)
  end

  def add_salt_repo
    env[:vm].channel.sudo("apt-get -q -y install python-software-properties")
    env[:vm].channel.sudo("add-apt-repository -y ppa:saltstack/salt")
    env[:vm].channel.sudo("apt-get -q -y update")
  end

  def install_salt_master
    env[:vm].channel.sudo("apt-get -q -y install salt-master")
  end

  def install_salt_minion
    env[:vm].channel.sudo("apt-get -q -y install salt-minion")
  end

  def accept_minion_key
    env[:vm].channel.sudo("salt-key -A")
  end

  def call_highstate
    env[:vm].channel.sudo("salt-call state.highstate")
  end


  def prepare
    # Calculate the paths we're going to use based on the environment
    @expanded_salt_config_path = config.expanded_salt_config_path(env[:root_path])
    @expanded_salt_file_root_path = config.expanded_salt_file_root_path(env[:root_path])
    share_salt_config_path
    share_salt_file_root_path
  end

  def provision!
    env[:ui].info "Adding Salt PPA."
    add_salt_repo
    env[:ui].info "Installing salt master."
    install_salt_master
    env[:ui].info "Installing salt minion."
    install_salt_minion
    env[:ui].info "Accepting minion key."
    accept_minion_key
    env[:ui].info "Calling state.highstate"
    call_highstate

  end

  def verify_shared_folders(folders)
    folders.each do |folder|
      @logger.debug("Checking for shared folder: #{folder}")
      if !env[:vm].channel.test("test -d #{folder}")
        raise PuppetError, :missing_shared_folders
      end
    end
  end
end