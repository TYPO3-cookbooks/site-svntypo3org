maintainer       "TYPO3 Association"
maintainer_email "steffen.gebert@typo3.org"
license          "Apache 2.0"
description      "Installs/Configures svn.typo3.org"
version          "0.0.1"

depends "ssl_certificates"
depends "apache2"

# for rabbitmq consumer
depends "runit"
depends "python"