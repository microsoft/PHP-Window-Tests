#%powershell1.0%
#
# File: wcat-run-all.ps1
# Description: Works with autocat controller, executes wcat_run.ps1 for all common scenarios. 
#
Param( $SERVER="", $TESTTYPE="", $CLIENTS="", $PHPVER="", $VIRTUAL="8,16,32", $APACHESVC="Apache2.4vc10")

if ( ($SERVER -eq "") -or ($TESTTYPE -eq "") -or ($CLIENTS -eq "") -or ($PHPVER -eq "") -or ($APACHESVC -eq "") )  {
	write-output 'Usage: wcat-run-all.ps1 -SERVER [servername] -TESTTYPE [nocache|cache|cachewithigbinary] -CLIENTS [loadclient1,loadclient2,...] -PHPVER [PHP version] -APACHESVC [Apache2.4vc10|Apache2.4vc11] [-VIRTUAL [n1,n2,...]]'
	exit
}

switch ( $TESTTYPE )  {
	"nocache" {
	
		## IIS - No Cache
		c:\wcat\wcat_run.ps1 -SERVER $SERVER -SUFFIX "PHP$PHPVER-IIS-nocache-Drupal" -WEBSVR "IIS" -APACHESVC $APACHESVC -CLIENTS $CLIENTS -SETFILE "c:\wcat\conf\settings-drupal.wcat"
		c:\wcat\wcat_run.ps1 -SERVER $SERVER -SUFFIX "PHP$PHPVER-IIS-nocache-Helloworld" -WEBSVR "IIS" -APACHESVC $APACHESVC -CLIENTS $CLIENTS -SETFILE "c:\wcat\conf\settings-helloworld.wcat"
		c:\wcat\wcat_run.ps1 -SERVER $SERVER -SUFFIX "PHP$PHPVER-IIS-nocache-Joomla" -WEBSVR "IIS" -APACHESVC $APACHESVC -CLIENTS $CLIENTS -SETFILE "c:\wcat\conf\settings-joomla.wcat"
		c:\wcat\wcat_run.ps1 -SERVER $SERVER -SUFFIX "PHP$PHPVER-IIS-nocache-Wordpress" -WEBSVR "IIS" -APACHESVC $APACHESVC -CLIENTS $CLIENTS -SETFILE "c:\wcat\conf\settings-wordpress.wcat"
		c:\wcat\wcat_run.ps1 -SERVER $SERVER -SUFFIX "PHP$PHPVER-IIS-nocache-Mediawiki" -WEBSVR "IIS" -APACHESVC $APACHESVC -CLIENTS $CLIENTS -SETFILE "c:\wcat\conf\settings-mediawiki.wcat"
		c:\wcat\wcat_run.ps1 -SERVER $SERVER -SUFFIX "PHP$PHPVER-IIS-nocache-Symfony" -WEBSVR "IIS" -APACHESVC $APACHESVC -CLIENTS $CLIENTS -SETFILE "c:\wcat\conf\settings-symfony.wcat"

		## Apache - No Cache
		c:\wcat\wcat_run.ps1 -SERVER $SERVER -SUFFIX "PHP$PHPVER-Apache-nocache-Helloworld" -WEBSVR "Apache" -APACHESVC $APACHESVC -CLIENTS $CLIENTS -SETFILE "c:\wcat\conf\settings-helloworld.wcat"
		c:\wcat\wcat_run.ps1 -SERVER $SERVER -SUFFIX "PHP$PHPVER-Apache-nocache-Joomla" -WEBSVR "Apache" -APACHESVC $APACHESVC -CLIENTS $CLIENTS -SETFILE "c:\wcat\conf\settings-joomla.wcat"
		c:\wcat\wcat_run.ps1 -SERVER $SERVER -SUFFIX "PHP$PHPVER-Apache-nocache-Wordpress" -WEBSVR "Apache" -APACHESVC $APACHESVC -CLIENTS $CLIENTS -SETFILE "c:\wcat\conf\settings-wordpress.wcat"
		c:\wcat\wcat_run.ps1 -SERVER $SERVER -SUFFIX "PHP$PHPVER-Apache-nocache-Mediawiki" -WEBSVR "Apache" -APACHESVC $APACHESVC -CLIENTS $CLIENTS -SETFILE "c:\wcat\conf\settings-mediawiki.wcat"
		c:\wcat\wcat_run.ps1 -SERVER $SERVER -SUFFIX "PHP$PHPVER-Apache-nocache-Drupal" -WEBSVR "Apache" -APACHESVC $APACHESVC -CLIENTS $CLIENTS -SETFILE "c:\wcat\conf\settings-drupal.wcat"	
		c:\wcat\wcat_run.ps1 -SERVER $SERVER -SUFFIX "PHP$PHPVER-Apache-nocache-Symfony" -WEBSVR "Apache" -APACHESVC $APACHESVC -CLIENTS $CLIENTS -SETFILE "c:\wcat\conf\settings-symfony.wcat"	
	}
	"cache" {

		## IIS - Cache
		c:\wcat\wcat_run.ps1 -SERVER $SERVER -SUFFIX "PHP$PHPVER-IIS-Cache-Helloworld" -WEBSVR "IIS" -APACHESVC $APACHESVC -CLIENTS $CLIENTS -SETFILE "c:\wcat\conf\settings-helloworld.wcat"
		c:\wcat\wcat_run.ps1 -SERVER $SERVER -SUFFIX "PHP$PHPVER-IIS-Cache-Joomla" -WEBSVR "IIS" -APACHESVC $APACHESVC -CLIENTS $CLIENTS -SETFILE "c:\wcat\conf\settings-joomla.wcat"
		c:\wcat\wcat_run.ps1 -SERVER $SERVER -SUFFIX "PHP$PHPVER-IIS-Cache-Wordpress" -WEBSVR "IIS" -APACHESVC $APACHESVC -CLIENTS $CLIENTS -SETFILE "c:\wcat\conf\settings-wordpress.wcat"
		c:\wcat\wcat_run.ps1 -SERVER $SERVER -SUFFIX "PHP$PHPVER-IIS-Cache-Mediawiki" -WEBSVR "IIS" -APACHESVC $APACHESVC -CLIENTS $CLIENTS -SETFILE "c:\wcat\conf\settings-mediawiki.wcat"
		c:\wcat\wcat_run.ps1 -SERVER $SERVER -SUFFIX "PHP$PHPVER-IIS-Cache-Drupal" -WEBSVR "IIS" -APACHESVC $APACHESVC -CLIENTS $CLIENTS -SETFILE "c:\wcat\conf\settings-drupal.wcat"
		c:\wcat\wcat_run.ps1 -SERVER $SERVER -SUFFIX "PHP$PHPVER-IIS-Cache-Symfony" -WEBSVR "IIS" -APACHESVC $APACHESVC -CLIENTS $CLIENTS -SETFILE "c:\wcat\conf\settings-symfony.wcat"

		## Apache - Cache w/o Igbinary
		c:\wcat\wcat_run.ps1 -SERVER $SERVER -SUFFIX "PHP$PHPVER-Apache-cachenoigbinary-Helloworld" -WEBSVR "Apache" -APACHESVC $APACHESVC -CLIENTS $CLIENTS -SETFILE "c:\wcat\conf\settings-helloworld.wcat"
		c:\wcat\wcat_run.ps1 -SERVER $SERVER -SUFFIX "PHP$PHPVER-Apache-cachenoigbinary-Joomla" -WEBSVR "Apache" -APACHESVC $APACHESVC -CLIENTS $CLIENTS -SETFILE "c:\wcat\conf\settings-joomla.wcat"
		c:\wcat\wcat_run.ps1 -SERVER $SERVER -SUFFIX "PHP$PHPVER-Apache-cachenoigbinary-Wordpress" -WEBSVR "Apache" -APACHESVC $APACHESVC -CLIENTS $CLIENTS -SETFILE "c:\wcat\conf\settings-wordpress.wcat"
		c:\wcat\wcat_run.ps1 -SERVER $SERVER -SUFFIX "PHP$PHPVER-Apache-cachenoigbinary-Mediawiki" -WEBSVR "Apache" -APACHESVC $APACHESVC -CLIENTS $CLIENTS -SETFILE "c:\wcat\conf\settings-mediawiki.wcat"
		c:\wcat\wcat_run.ps1 -SERVER $SERVER -SUFFIX "PHP$PHPVER-Apache-cachenoigbinary-Drupal" -WEBSVR "Apache" -APACHESVC $APACHESVC -CLIENTS $CLIENTS -SETFILE "c:\wcat\conf\settings-drupal.wcat"	
		c:\wcat\wcat_run.ps1 -SERVER $SERVER -SUFFIX "PHP$PHPVER-Apache-cachenoigbinary-Symfony" -WEBSVR "Apache" -APACHESVC $APACHESVC -CLIENTS $CLIENTS -SETFILE "c:\wcat\conf\settings-symfony.wcat"	
	}
	"cachewithigbinary" {

		## Apache - Cache w/Igbinary
		c:\wcat\wcat_run.ps1 -SERVER $SERVER -SUFFIX "PHP$PHPVER-Apache-cachewithigbinary-Helloworld" -WEBSVR "Apache" -APACHESVC $APACHESVC -CLIENTS $CLIENTS -SETFILE "c:\wcat\conf\settings-helloworld.wcat"
		c:\wcat\wcat_run.ps1 -SERVER $SERVER -SUFFIX "PHP$PHPVER-Apache-cachewithigbinary-Joomla" -WEBSVR "Apache" -APACHESVC $APACHESVC -CLIENTS $CLIENTS -SETFILE "c:\wcat\conf\settings-joomla.wcat"
		c:\wcat\wcat_run.ps1 -SERVER $SERVER -SUFFIX "PHP$PHPVER-Apache-cachewithigbinary-Wordpress" -WEBSVR "Apache" -APACHESVC $APACHESVC -CLIENTS $CLIENTS -SETFILE "c:\wcat\conf\settings-wordpress.wcat"
		c:\wcat\wcat_run.ps1 -SERVER $SERVER -SUFFIX "PHP$PHPVER-Apache-cachewithigbinary-Mediawiki" -WEBSVR "Apache" -APACHESVC $APACHESVC -CLIENTS $CLIENTS -SETFILE "c:\wcat\conf\settings-mediawiki.wcat"
		c:\wcat\wcat_run.ps1 -SERVER $SERVER -SUFFIX "PHP$PHPVER-Apache-cachewithigbinary-Drupal" -WEBSVR "Apache" -APACHESVC $APACHESVC -CLIENTS $CLIENTS -SETFILE "c:\wcat\conf\settings-drupal.wcat"
		c:\wcat\wcat_run.ps1 -SERVER $SERVER -SUFFIX "PHP$PHPVER-Apache-cachewithigbinary-Symfony" -WEBSVR "Apache" -APACHESVC $APACHESVC -CLIENTS $CLIENTS -SETFILE "c:\wcat\conf\settings-symfony.wcat"
	}
}

