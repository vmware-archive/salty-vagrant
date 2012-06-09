require './salt_provisioner.rb'

Vagrant::Config.run do |config|
  config.vm.box = "precise64"
  config.vm.provision SaltProvisioner do |salt|
    salt.minion_config = "minion"
    salt.salt_config_path = "salt/config"
    salt.salt_file_root_path = "salt/file_root"
  end
end