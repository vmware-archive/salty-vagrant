==============
Salty Vagrant
==============
Provision `Vagrant`_ boxes using `Saltstack`_.

.. _`Vagrant`: http://www.vagrantup.com/
.. _`Saltstack`: http://saltstack.org/

Introduction
============

Just like Chef or Puppet, Salt can be used as a provisioning tool. `Salty Vagrant`_
lets you use your salt state tree and a your minion config file to
automatically build your dev environment the same way you use salt to deploy
for other environments.

.. _`Salty Vagrant`: https://github.com/akoumjian/salty-vagrant

Quick Start
=============

1. Install `Vagrant`_
2. `vagrant box add precise64 http://files.vagrantup.com/precise64.box`
2. Download or clone this repository.
3. Place your salt state tree in salt/file_roots/salt
4. Place your minion config in salt/config/minion
5. Run `vagrant up` and you should be good to go.