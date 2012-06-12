require './salt_provisioner.rb'

Vagrant::Config.run do |config|
  config.vm.box = "precise64"
  ## Use all the defaults:
  config.vm.provision SaltProvisioner

  ## SaltProvisioner settings are set like this:
  # config.vm.provision SaltProvisioner do |salt|
  	# salt.minion_config = "salt/minion"

  	## Only Use these with a masterless setup to
  	## load your state tree:
  	# salt.salt_file_root_path = "salt/roots/salt"
  	# salt.salt_pillar_root_path = "salt/roots/pillar"

  	## If you have a remote master setup, you can add
  	## your preseeded minion key
    # salt.master = true
    # salt.minion_key = "salt/testing.pem"
    # salt.minion_pub = "salt/testing.pub"
  # end
end