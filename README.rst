==============
Salty Vagrant
==============
Provision `Vagrant`_ boxes using `Saltstack`_.

.. _`Vagrant`: http://www.vagrantup.com/
.. _`Saltstack`: http://saltstack.org/

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

Quick Start (masterless)
=============

1. Install `Vagrant`_
2. Get the Ubuntu 12.04 base box: ``vagrant box add precise64 http://files.vagrantup.com/precise64.box``
3. Download or clone this repository.
4. Place your salt state tree in ``salt/roots/salt``
5. Place your minion config in ``salt/minion`` [#]_
6. Run ``vagrant up`` and you should be good to go.

.. [#] Make sure your minion config sets ``file_client: local`` for masterless