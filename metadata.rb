name             "site-svntypo3org"
maintainer       "TYPO3 Association"
maintainer_email "steffen.gebert@typo3.org"
license          "Apache 2.0"
description      "Installs/Configures svn.typo3.org"
long_description IO.read(File.join(File.dirname(__FILE__), 'README.md'))
version          "0.1.6"

depends "ssl_certificates"
depends "apache2"
depends "chef-vault"
depends "t3-chef-vault"

# for rabbitmq consumer
depends "runit"
depends "python"
