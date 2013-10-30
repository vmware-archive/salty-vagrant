==============
Salty Vagrant
==============

Provision `Vagrant`_ boxes using `Saltstack`_.

Help and discussion can be found at ``#salt`` on Freenode IRC (just ping ``akoumjian``)
or the `salt-users mailing list`_.

.. _`Vagrant`: http://www.vagrantup.com/
.. _`Saltstack`: http://saltstack.org/
.. _`bootstrap`: https://github.com/saltstack/salt-bootstrap
.. _`Salt`: http://saltstack.org/
.. _`salt-users mailing list`: https://groups.google.com/forum/#!forum/salt-users

Warning
=======

**DEPRECATED**: Vagrant includes a salt provisioner for versions 1.3.0 and above

Introduction
============

`Salty Vagrant`_ is a plugin for Vagrant which lets you use salt as a
provisioning tool. You can use your existing salt formulas and configs
to build up development environments.

.. _`Salty Vagrant`: https://github.com/saltstack/salty-vagrant

The simplest way to use `Salty Vagrant`_ is by configuring it for
masterless mode. With this setup, you use a standalone minion along
with your file_roots and/or pillar_roots. See the ``examples/`` folder
for more details.

Masterless (Quick Start)
========================

1. Install `Vagrant`_
2. Install `Salty Vagrant`_ (``vagrant plugin install vagrant-salt``)
3. Get the Ubuntu 12.04 base box: ``vagrant box add precise64 http://files.vagrantup.com/precise64.box``
4. Create/Update your ``Vagrantfile`` (Detailed in `Configuration`_) [#shared_folders]_
5. Place your minion config in ``salt/minion`` [#file_client]_
6. Run ``vagrant up`` and you should be good to go.

.. [#file_client] Make sure your minion config sets ``file_client: local`` for masterless
.. [#shared_folders] Don't forget to create a shared folder for your salt file root


Configuration
=============

Here is an extremely simple ``Vagrantfile``, to be used with
the above masterless setup::

    Vagrant.configure("2") do |config|
      ## Choose your base box
      config.vm.box = "precise64"

      ## For masterless, mount your salt file root
      config.vm.synced_folder "salt/roots/", "/srv/salt/"

      ## Use all the defaults:
      config.vm.provision :salt do |salt|

        salt.minion_config = "salt/minion"
        salt.run_highstate = true

      end
    end

Actions
-------

run_highstate    (true/false)
    Executes ``state.highstate`` on vagrant up

accept_keys      (true/false)
    Accept all keys if running a master. DEPRECATED: use `seed_master`


Install Options
---------------

install_master   (true/false)
    Install the salt-master

no_minion        (true/false)
    Don't install the minion

install_syndic   (true/false)
    Install the salt-syndic

install_type     (stable | git | daily)
    Whether to install from a distribution's stable package manager, a
    daily ppa, or git treeish.

install_args     (develop)
    When performing a git install, you can specify a branch, tag, or
    any treeish.

always_install   (true/false)
    Installs salt binaries even if they are already detected


Minion Options
--------------

minion_config    (salt/minion)
    Path to a custom salt minion config file.

minion_key       (salt/key/minion.pem)
    Path to your minion key

minion_pub       (salt/key/minion.pub)
    Path to your minion public key


Master Options
--------------

master_config    (salt/minion)
  Path to a custom salt master config file

master_key       (salt/key/master.pem)
  Path to your master key

master_pub       (salt/key/master.pub)
  Path to your master public key

seed_master  {minion_name:/path/to/key.pub}
  Upload keys to master, thereby pre-seeding it
  before use.


Other
-----
bootstrap_script (salt/bootstrap_salt.sh)
    Path to a custom `bootstrap`_ script

temp_config_dir  (/tmp)
    Path on the guest box that config and bootstrap files will be copied
    to before placing in the salt directories

pillar_data
    Get pillar data that has been set (this is read only because data
    should be set using the ``pillar`` command referenced below)

verbose          (true/false)
    Prints bootstrap script output to screen


Installation Notes
==================

Supported Operating Systems
---------------------------
- Ubuntu 10.x/11.x/12.x
- Debian 6.x/7.x
- CentOS 6.3
- Fedora
- Arch
- FreeBSD 9.0

Installing from source
----------------------

1. ``git clone https://github.com/saltstack/salty-vagrant.git``
2. ``cd salty-vagrant``
3. ``git submodule init``
4. ``git submodule update``
5. ``gem install rubygems-bundler``
6. ``gem build vagrant-salt.gemspec``
7. ``vagrant plugin install vagrant-salt-[version].gem``

If you'd like to include the latest stable revision of the salt-bootstrap script, run the following after step 5:

1. ``cd scripts``
2. ``git pull origin stable``
3. Rebuild the gem if you had built it previously.


Miscellaneous
=============

Pillar Data
-----------

You can export pillar data for use during provisioning by using the ``pillar``
command. Each call will merge the data so you can safely call it multiple
times. The data passed in should only be hashes and lists. Here is an example::

      config.vm.provision :salt do |salt|

        # Export hostnames for webserver config
        salt.pillar({
          "hostnames" => {
            "www" => "www.example.com",
            "intranet" => "intranet.example.com"
          }
        })

        # Export database credentials
        salt.pillar({
          "database" => {
            "user" => "jdoe",
            "password" => "topsecret"
          }
        })

        salt.run_highstate = true

      end

Using Remote Salt Master
------------------------

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
    root@saltmaster# cp [minion_id].pub /etc/salt/pki/master/minions/[minion_id]

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
