name             "site-svntypo3org"
maintainer       "TYPO3 Association"
maintainer_email "steffen.gebert@typo3.org"
license          "Apache 2.0"
description      "Installs/Configures svn.typo3.org"
version          "0.1.0"

depends "ssl_certificates"
depends "apache2"
depends "chef-vault"

# for rabbitmq consumer
depends "runit"
depends "python"
