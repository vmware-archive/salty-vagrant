# require "../lib/vagrant-salt"

Vagrant::Config.run do |config|
  ## Chose your base box
  config.vm.box = "precise64"

  ## For masterless, mount your salt file root
  config.vm.share_folder "salt_file_root", "/srv", "/path/to/salt_file_root"


  ## Use all the defaults:
  config.vm.provision :salt do |salt|
    salt.run_highstate = true

    ## Optional Settings:
    # salt.minion_config = "salt/minion.conf"
    # salt.temp_config_dir = "/existing/folder/on/basebox/"
    # salt.salt_install_type = "git"
    # salt.salt_install_args = "develop"

    ## If you have a remote master setup, you can add
    ## your preseeded minion key
    # salt.minion_key = "salt/key/minion.pem"
    # salt.minion_pub = "salt/key/minion.pub"
  end
end