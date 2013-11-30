SVN Server
==========

[![Build Status](https://travis-ci.org/TYPO3-cookbooks/site-svntypo3org.png)](https://travis-ci.org/TYPO3-cookbooks/site-svntypo3org)

That old stupid relict..

The implementation is not very flexible. Only important to keep it running for some couple of months left.


Authentication
===============

Is performed against typo3.org's auth service script.


Group Sync from Forge/Redmine
=============================

Group memberships for SVN subdirectories are synced regularly from Forge/Redmine and written to the authz file `/var/lib/svn/typo3v4/extensions/conf/authz`.

In order to let the `sync-group.php` job read all that memberships, the user `svntypo3org` needs admin rights on forge (yes, bad idea, see [redmine issue](http://www.redmine.org/issues/7773)).

The scripts are located in `/opt/svn-helpers/`.

Only the `TYPO3v4/Extensions/*` projects are updated. No `TYPO3v4/CoreProjects` etc (only gridelements is still used and that has to be changed manually on the server).


Credentials
===========

Credentials in use:

- API token for the `svntypo3org` user on forge
- API token for the auth service on typo3.org
