noah-freebsd-template
=====================

creates FreeBSD template from fresh installation.

noah, not cloudstack
====================

noah, or IDCF cloud, is an IaaS cloud service provided by IDCF. it is based on
cloudstack 2.2.x, which is EoLed by citrix. although most of things that need
to be done to create a FreeBSD template are common between 2.2.x and newer
versions, there might be differences. an example is meta-data URL. newer
cloudstack still supports old URL but no one would be surprised if they drop
backward compatibility. templates created by the script may, or may not, work
on newer cloudstack.

what it does
============

* install updates by executing freebsd-update when the system first boots, then
  reboot
* install ssh key pairs from virtual router
* disable password login and allow root to login with public key
* remove host-specific files

usage
=====

* install FreeBSD on an instance as usual
* before final reboot, run (chrooted) shell
* copy this repo into the instance
* run make

    # make -C /path/to/the/repo

supported FreeBSD version
=========================

as it requires some features that are not available in older FreeBSD releases,
they are not supported. supported release includes:

* FreeBSD 10.0-RELEASE 

TODO
====

* scripts under files/usr/local/etc/rc.d should be packaged like sysutils/ec2-scripts
* import ec2\_configinit from sysutils/ec2-scripts

license
=======

see LICENSE.
