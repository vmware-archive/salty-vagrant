==============
Salty Vagrant
==============
Provision `Vagrant`_ boxes using `Saltstack`_.

Discussion and questions happen in ``#salt`` on Freenode IRC. ping ``akoumjian``.

.. _`Vagrant`: http://www.vagrantup.com/
.. _`Saltstack`: http://saltstack.org/
.. _`Salt`: http://saltstack.org/

Introduction
============

Just like Chef or Puppet, Salt can be used as a provisioning tool. 
`Salty Vagrant`_ lets you use your salt state tree and a your minion config 
file to automatically build your dev environment the same way you use salt 
to deploy for other environments.

.. _`Salty Vagrant`: https://github.com/akoumjian/salty-vagrant

There are two different ways to use `Salty Vagrant`_. The simplest way uses 
the salt minion in a masterless configuration. With this option you distribute 
your state tree along with your Vagrantfile and a dev minion config. The 
minion will bootstrap itself and apply all necessary states.

The second method lets you specify a remote salt master, which assures that 
the vagrant minion will always be able to fetch your most up to date state 
tree. If you use a salt master, you will either need to manually accept 
new vagrant minions on the master, or distribute preseeded keys along with 
your vagrant files.

Masterless (Quick Start)
========================

1. Install `Vagrant`_
2. Get the Ubuntu 12.04 base box: ``vagrant box add precise64 http://files.vagrantup.com/precise64.box``
3. Download or clone this repository.
4. Place your salt state tree in ``salt/roots/salt``
5. Place your minion config in ``salt/minion`` [#file_client]_
6. Run ``vagrant up`` and you should be good to go.

.. [#file_client] Make sure your minion config sets ``file_client: local`` for masterless

Using Remote Salt Master
========================

If you are already using `Salt`_ for deployment, you can use your existing 
master to provision your vagrant boxes as well. You will need to do one of the
following:

#. Manually accept the vagrant's minion key after it boots. [#accept_key]_
#. Preseed the Vagrant box with minion keys pre-generated on the master

.. [#accept_key] This is not recommended. If your developers need to destroy and rebuild their VM, you will have to repeat the process.

Preseeding Vagrant Minion Keys
------------------------------

On the master, create the keypair and add the public key to the accepted minions 
folder::

    root@saltmaster# salt-key --gen-keys=[minion_id]
    root@saltmaster# cp minion_id.pub /etc/salt/pki/minions/[minion_id]

Replace ``[minion_id]`` with the id you would like to assign the minion. 

Next you want to bundle the key pair along with your Vagrantfile, 
the salt_provisioner.rb, and your minion config. The directory should look 
something like this::

    myvagrant/
        Vagrantfile
        salt_provisioner.rb
        salt/
            minion.conf
            key/
                minion.pem
                minion.pub

You will need to determine your own secure method of transferring this 
package. Leaking the minion's private key poses a security risk to your salt 
network.

The are two required settings for your ``minion.conf`` file::

    master: [master_fqdn]
    id: [minion_id]

Make sure you use the same ``[minion_id]`` that you used on the master or 
it will not match with the key.

Your ``Vagrantfile`` will need to contain three settings, and should look 
roughly like this::

    require './salt_provisioner.rb'

    Vagrant::Config.run do |config|
      config.vm.box = "precise64"

      config.vm.provision SaltProvisioner do |salt|
        salt.master = true
        salt.minion_key = "salt/key/minion_id.pem"
        salt.minion_pub = "salt/key/minion_id.pub"
      end
    end

Now you should be able to run ``vagrant up`` and the salt should put your 
vagrant minion in state.highstate.


Configuration
==============

Inside of your Vagrantfile, there are a few parameters you can assign 
depending on whether you are running masterless or with a remote master.

minion_config : "salt/minion.conf"
    Path to your minion configuration file.

minion_key : false
    String path to your minion key. Only useful with ``master=true``

minion_pub : false
    String path to your minion public key. Only useful with ``master=true``

master : false
    Boolean whether or not you want to use a remote master. If set to false,
    make sure your minion config file has ``file_client: local`` set.

salt_file_root_path : "salt/roots/salt"
    String path to your salt state tree. Only useful with ``master=false``.

salt_file_root_guest_path : "/srv/salt"
    Path to share the file root state tree on the VM. Only use with ``master=false``.

salt_pillar_root_path : "salt/roots/pillar"
    Path to share your pillar tree. Only useful with ``master=false``.

salt_pillar_root_guest_path : "/srv/pillar"
    Path on VM where pillar tree will be shared. Only use with ``master=true``


