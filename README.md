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
* fetch user-data from virtual router and pass it to cs\_configinit
* disable password login and allow root to login with public key
* remove host-specific files

usage
=====

* install FreeBSD on an instance as usual
* before final reboot, run (chrooted) shell
* copy this repo into the instance
* run make

<pre>
    # make -C /path/to/the/repo
</pre>

userdata
========

to configure something specific to an instance, use userdata. cs\_configinit
fetches userdata from virtual router using HTTP. if the userdata looks like a
script (the first 2 bytes is "#!"), cs\_configinit makes it executable and run
it. an example:

<pre>
    #!/bin/sh
    HOSTNAME="foo.example.com"
    echo "hostname=\"${HOSTNAME}\"" >> /etc/rc.conf
</pre>

if you have a non-default network as a primary network, you probably want to
append something like:

<pre> 
    DEFAULT_GATEWAY="192.168.1.1"
    echo "interface \"em0\" { default routers ${DEFAULT_GATEWAY}; }" >> /etc/dhclient.conf
</pre>

supported FreeBSD version
=========================

as it requires some features that are not available in older FreeBSD releases,
they are not supported. supported release includes:

* FreeBSD 10.0-RELEASE 

TODO
====

* scripts under files/usr/local/etc/rc.d should be packaged like sysutils/ec2-scripts

license
=======

see LICENSE.
