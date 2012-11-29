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

.. _`Salty Vagrant`: https://github.com/saltstack/salty-vagrant

There are two different ways to use `Salty Vagrant`_. The simplest way uses 
the salt minion in a masterless configuration. With this option you distribute 
your state tree along with your Vagrantfile and a minion config. The 
minion will bootstrap itself and apply all necessary states.

The second method lets you specify a remote salt master, which assures that 
the vagrant minion will always be able to fetch your most up to date state 
tree. If you use a salt master, you will either need to manually accept 
new vagrant minions on the master, or distribute preseeded keys along with 
your vagrant files.

Masterless (Quick Start)
========================

1. Install `Vagrant`_
2. Install `Salty Vagrant`_ (``vagrant gem install vagrant-salt``)
3. Get the Ubuntu 12.04 base box: ``vagrant box add precise64 http://files.vagrantup.com/precise64.box``
4. Create/Update your ``Vagrantfile`` (Detailed in `Configuration`_) [#shared_folders]_
5. Place your minion config in ``salt/minion`` [#file_client]_
6. Run ``vagrant up`` and you should be good to go.

.. [#file_client] Make sure your minion config sets ``file_client: local`` for masterless
.. [#shared_folders] Don't forget to create a shared folder for your salt file root

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
    root@saltmaster# cp [minion_id].pub /etc/salt/pki/minions/[minion_id]

Replace ``[minion_id]`` with the id you would like to assign the minion. 

Next you want to bundle the key pair along with your Vagrantfile, 
the salt_provisioner.rb, and your minion config. The directory should look 
something like this::

    myvagrant/
        Vagrantfile
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

Create/Update your ``Vagrantfile`` per the example provided in the `Configuration`_ section.

Finally, you should be able to run ``vagrant up`` and the salt should put your 
vagrant minion in state.highstate.


Configuration
=============

Your ``Vagrantfile`` should look roughly like this::

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

Inside of your Vagrantfile, there are a few parameters you can assign 
depending on whether you are running masterless or with a remote master.

minion_config : "salt/minion.conf"
    Path to your minion configuration file.

temp_config_dir : "/tmp"
    Path on the guest box that the minion files will be copied to before
    placing in the salt directories. (Not all distros support "/tmp")

minion_key : false
    String path to your minion key. Only useful with ``master=true``

minion_pub : false
    String path to your minion public key. Only useful with ``master=true``

salt_install_type : "stable" : "daily" : "git"
    Whether to install from a distribution's stable package manager, a
    daily ppa, or git treeish.

salt_install_args : ""
    When performing a git install, you can specify a branch, tag, or 
    any treeish.


Bootstrapping Salt
==================

Before `Salt`_ can be used for provisioning on the target virtual box, the 
binaries need to be installed. Since `Vagrant`_ and `Salt`_ support many 
different distributions and versions of operating systems, the `Salt`_ 
installation process is handled by the shell script 
``scripts/bootstrap-salt-minion.sh``. This script runs through a series of 
checks to determine operating system type and version to then install the 
`Salt`_ binaries using the appropriate methods.

Adding support for other operating systems
------------------------------------------
In order to install salt for a distribution you need to define:

   To Install Dependencies, which is required, one of:
       1. install_<distro>_<distro_version>_<install_type>_deps
       2. install_<distro>_<distro_version>_deps
       3. install_<distro>_<install_type>_deps
       4. install_<distro>_deps


   To install salt, which, of course, is required, one of:
       1. install_<distro>_<distro_version>_<install_type>
       2. install_<distro>_<install_type>

   Optionally, define a minion configuration function, which will be called if
   the -c|config-dir option is passed. One of:
       1. config_<distro>_<distro_version>_<install_type>_minion
       2. config_<distro>_<distro_version>_minion
       3. config_<distro>_<install_type>_minion
       4. config_<distro>_minion
       5. config_minion [THIS ONE IS ALREADY DEFINED AS THE DEFAULT]

   Also optionally, define a post install function, one of:
       1. install_<distro>_<distro_versions>_<install_type>_post
       2. install_<distro>_<distro_versions>_post
       3. install_<distro>_<install_type>_post
       4. install_<distro>_post

Below is an example for Ubuntu Oneiric:

    install_ubuntu_1110_deps() {
        apt-get update
        apt-get -y install python-software-properties
        add-apt-repository -y 'deb http://us.archive.ubuntu.com/ubuntu/ oneiric universe'
        add-apt-repository -y ppa:saltstack/salt
    }

    install_ubuntu_1110_post() {
        add-apt-repository -y --remove 'deb http://us.archive.ubuntu.com/ubuntu/ oneiric universe'
    }

    install_ubuntu_stable() {
        apt-get -y install salt-minion
    }

Since there is no ``install_ubuntu_1110_stable()`` it defaults to the 
unspecified version script.

The bootstrapping script must be plain POSIX sh only, **not** bash or another 
shell script. By design the targeting for each operating system and version is 
very specific. Assumptions of supported versions or variants should not be 
made, to avoid failed or broken installations.

Supported Operating Systems
---------------------------
- Ubuntu 10.x/11.x/12.x
- Debian 6.x
- CentOS 6.3
- Fedora
- Arch
- FreeBSD 9.0

Installation Notes
==================
Ubuntu & Debian
---------------

Users have reported that vagrant plugins do not work with the debian packaged vagrant
(such as Ubuntu repository). Installing vagrant with gem should work.

1. ``sudo apt-get remove vagrant``
2. ``sudo gem install vagrant``
3. ``vagrant gem install vagrant-salt``

That should get you up and running.

Installing from source
----------------------

1. ``wget https://github.com/saltstack/salty-vagrant/tarball/master -O salty-vagrant.tar.gz``
2. ``tar zxf salty-vagrant.tar.gz``
3. ``cd saltstack-salty-vagrant-[hash]``
4. ``git submodule init``
4. ``git submodule update``
5. ``gem build vagrant-salt.gemspec``
6. ``vagrant gem install vagrant-salt-[version].gem``

.. vim: fenc=utf-8 spell spl=en cc=80 tw=79 fo=want sts=2 sw=2 et
