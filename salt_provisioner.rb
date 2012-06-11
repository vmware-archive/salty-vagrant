class SaltProvisioner < Vagrant::Provisioners::Base

  class Config < Vagrant::Config::Base
    attr_accessor :minion_config
    attr_accessor :local_master
    attr_accessor :master_config
    attr_accessor :salt_file_root_path
    attr_accessor :salt_file_root_guest_path
    attr_accessor :salt_pillar_root_path
    attr_accessor :salt_pillar_root_guest_path


    def minion_config; @minion_config || "salt/minion"; end
    def local_master; @local_master || true; end
    def master_config; @master_config || "salt/master"; end
    def salt_file_root_path; @salt_file_root_path || "salt/roots/salt"; end
    def salt_file_root_guest_path; @salt_file_root_guest_path || "/srv/salt"; end
    def salt_pillar_root_path; @salt_file_root_path || "salt/roots/pillar"; end
    def salt_pillar_root_guest_path; @salt_file_root_guest_path || "/srv/pillar"; end

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

    if config.use_master
      @expanded_master_config_path = config.expanded_path(env[:root_path], config.master_config)
      @expanded_salt_file_root_path = config.expanded_path(env[:root_path], config.salt_file_root_path)
      @expanded_salt_pillar_root_path = config.expanded_path(env[:root_path], config.salt_pillar_root_path)
      share_salt_file_root_path
      share_salt_pillar_root_path
    end
  end

  def share_salt_file_root_path
    env[:vm].config.vm.share_folder("salt_file_root", config.salt_file_root_guest_path, @expanded_salt_file_root_path)
  end

  def share_salt_pillar_root_path
    env[:vm].config.vm.share_folder("salt_pillar_root", config.salt_pillar_root_guest_path, @expanded_salt_pillar_root_path)
  end

  def add_salt_repo
    env[:ui].info "Adding Salt PPA."
    env[:vm].channel.sudo("apt-get -q -y install python-software-properties")
    env[:vm].channel.sudo("add-apt-repository -y ppa:saltstack/salt")
    env[:vm].channel.sudo("apt-get -q -y update")
  end

  def install_salt_master
    env[:ui].info "Installing salt master."
    env[:vm].channel.sudo("apt-get -q -y install salt-master")
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
    env[:ui].info "Calling state.highstate"
    env[:vm].channel.sudo("salt-call state.highstate")
  end

  def upload_minion_config
    env[:ui].info "Copying salt minion config to vm."
    env[:vm].channel.upload(@expanded_minion_config_path, "/etc/salt/minion")
  end

  def upload_master_config
    env[:ui].info "Copying salt master config to vm."
    env[:vm].channel.upload(@expanded_master_config_path, "/etc/salt/master")
  end

  def provision!
    add_salt_repo
    upload_minion_config
    install_salt_minion

    if config.use_master
      upload_master_config
      install_salt_master
      accept_minion_key
    end

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