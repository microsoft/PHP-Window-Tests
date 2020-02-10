#%powershell1.0%
#
# File: wcat-manual-start.ps1
#

$PHPVER = "PHPLABEL"  # Label used on results output, don't use dashes ('-')
$SERVER = "php-web01"
$CLIENTS = "php-load01,php-load02"
$VIRTUAL = "8,16,32"
$WBSVR = "Apache"
$APACHESVC = "Apache2.4vc11"

c:\wcat\wcat_run.ps1 -SERVER $SERVER -SUFFIX "PHP$PHPVER-$WBSVR-nocache-Wordpress" -WEBSVR $WBSVR -APACHESVC $APACHESVC -CLIENTS $CLIENTS -VIRTUAL $VIRTUAL -SETFILE "c:\wcat\conf\settings-wordpress.wcat"
c:\wcat\wcat_run.ps1 -SERVER $SERVER -SUFFIX "PHP$PHPVER-$WBSVR-cache-Drupal" -WEBSVR $WBSVR -APACHESVC $APACHESVC -CLIENTS $CLIENTS -VIRTUAL $VIRTUAL -SETFILE "c:\wcat\conf\settings-drupal.wcat"
c:\wcat\wcat_run.ps1 -SERVER $SERVER -SUFFIX "PHP$PHPVER-$WBSVR-cache-Joomla" -WEBSVR $WBSVR -APACHESVC $APACHESVC -CLIENTS $CLIENTS -VIRTUAL $VIRTUAL -SETFILE "c:\wcat\conf\settings-joomla.wcat"
c:\wcat\wcat_run.ps1 -SERVER $SERVER -SUFFIX "PHP$PHPVER-$WBSVR-cache-Mediawiki" -WEBSVR $WBSVR -APACHESVC $APACHESVC -CLIENTS $CLIENTS -VIRTUAL $VIRTUAL -SETFILE "c:\wcat\conf\settings-mediawiki.wcat"
c:\wcat\wcat_run.ps1 -SERVER $SERVER -SUFFIX "PHP$PHPVER-$WBSVR-cache-Helloworld" -WEBSVR $WBSVR -APACHESVC $APACHESVC -CLIENTS $CLIENTS -VIRTUAL $VIRTUAL -SETFILE "c:\wcat\conf\settings-helloworld.wcat"
c:\wcat\wcat_run.ps1 -SERVER $SERVER -SUFFIX "PHP$PHPVER-$WBSVR-cache-Symfony" -WEBSVR $WBSVR -APACHESVC $APACHESVC -CLIENTS $CLIENTS -VIRUAL $VIRTUAL -SETFILE "c:\wcat\conf\settings-symfony.wcat"

