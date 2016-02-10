name             "site-svntypo3org"
maintainer       "TYPO3 Association"
maintainer_email "steffen.gebert@typo3.org"
license          "Apache 2.0"
description      "Installs/Configures svn.typo3.org"
long_description IO.read(File.join(File.dirname(__FILE__), 'README.md'))
version          "0.1.10"

depends          "t3-base",           "~> 0.2.0"

depends          "t3-chef-vault",     "~> 1.0.0"
depends          "ssl_certificates",  "~> 1.1.0"

depends          "apache2",           "= 3.1.0"
# for rabbitmq consumer
depends          "runit",             "= 1.7.6"
depends          "python",            "= 1.4.6"
