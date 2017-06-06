#%powershell1.0%
#
# File: controller.ps1
# Description: This file will automate the entire test flow.
#
## Example: controller.ps1 -PHP1 "5.3.8" -PHP1URL "http://windows.php.net/downloads/releases/php-5.3.8-Win32-VC9-x86.zip,http://windows.php.net/downloads/releases/php-5.3.8-nts-Win32-VC9-x86.zip" -PHP2 "5.4.0" -PHP2URL "5.4"
## 
## PHP1/PHP2 are used as labels for the results.  Avoid the use of spaces in these variables.
##
## PHP*URL must be in the format "5.3" or "5.4" indicating a snapshot build, or a comma-separated list of complete URLs to the
## TS and NTS .zip files.  This is because we can use the json files to scan for the latest revision and download the TS and NTS
## builds, but doing so for Release or Q/A builds is more difficult.
Param( $PHP1="", $PHP1URL="", $PHP2="", $PHP2URL="" )

Set-Location c:\wcat
$CLIENTS="php-load06,php-load07"
$VIRTUAL="8,16,32"
$SERVER="php-web02"

$REVISION = ""
$PHP1BuildDir = @()
$PHP2BuildDir = @()
$BaseBuildDir = "c:/wcat/phpbuilds"
$WebSvrPHPLoc = "\\$SERVER\php"
$ApacheSvcs = @( 'Apache2.2', 'Apache2.4vc10', 'Apache2.4vc11', 'Apache2.4vc11x64' )

## Import needed functions
. .\web-utils.ps1
. .\setup-utils.ps1

## Simple logging function.
Function logger ( $msg )  {
	$logfile = "c:/wcat/autocat-log.txt"
	$msg = (get-date -format "yyyy-MM-dd HH:mm:ss")+" $msg"
	$msg | Out-File -Encoding ASCII -Append $logfile
}

## Download the PHP builds.  We attempt to download three times, and exit if we fail to download any build.
## PHP*URL must either be "5.3" or "5.4" indicating a snapshot build, or a comma-separated list of
## complete URLs to the TS and NTS .zip files.
$status = ""
$loop = 0
do {
	switch ( $PHP1URL )  {
		{ $PHP1URL -notmatch "," }	{  ## Snapshot build
			$PHP1BuildDir = php-getsnapbuilds( $PHP1URL )
			if ( $PHP1BuildDir -eq $false )  {
				logger "Controller: php-getsnapbuilds() returned false, URL=$PHP1URL."
				$status = $false
				$loop++
				start-sleep -s 5
				continue
			}
			if ( $PHP1BuildDir[0] -match "r[a-z0-9]{7}" )  {
				$PHP1 = $PHP1+$matches[0]
			}
		}

		{ ($PHP1URL -match "http\:\/\/") -and ($PHP1URL -match ",") }  {  ## Links to specific builds.  Needed for Release and QA builds.
			$URIS = $PHP1URL.Split(",")
			$status = download-build( $URIS[0] )
			$PHP1BuildDir += $status
			if ( $status -eq $false )  {
				logger "Controller: download-build() returned false, URL=$PHP1URL[0]."
				$loop++
				start-sleep -s 5
				continue
			}
			$status = download-build( $URIS[1] )
			$PHP1BuildDir += $status
			if ( $status -eq $false )  {
				logger "Controller: download-build() returned false, URL=$PHP1URL[1]."
				$loop++
				start-sleep -s 10
				continue
			}
		}

		default  {
			write-host "Syntax error in PHP1URL parameter."
			exit
		}
	}
}  while ( ($status -eq $false) -and ($loop -lt 3) )  ## End Loop
if ( $status -eq $false )  {  exit  }

$loop = 0
do {
	switch ( $PHP2URL )  {
		{ $PHP2URL -notmatch "," }	{  ## Snapshot build
			$PHP2BuildDir = php-getsnapbuilds( $PHP2URL )
			if ( $PHP2BuildDir -eq $false )  {
				logger "Controller: php-getsnapbuilds() returned false, URL=$PHP2URL."
				$status = $false
				$loop++
				start-sleep -s 10
				continue
			}
			if ( $PHP2BuildDir[0] -match "r[a-z0-9]{7}" )  {
				$PHP2 = $PHP2+$matches[0]
			}
		}
		
		{ ($PHP2URL -match "http\:\/\/") -and ($PHP2URL -match ",") }  {  ## Links to specific builds.  Needed for Release and QA builds.
			$URIS = $PHP2URL.Split(",")
			$status = download-build( $URIS[0] )
			$PHP2BuildDir += $status
			if ( $status -eq $false )  {
				logger "Controller: download-build() returned false, URL=$PHP2URL[0]."
				$loop++
				start-sleep -s 10
				continue
			}
			$status = download-build( $URIS[1] )
			$PHP2BuildDir += $status
			if ( $status -eq $false )  {
				logger "Controller: download-build() returned false, URL=$PHP2URL[1]."
				$loop++
				start-sleep -s 10
				continue
			}
		}

		default  {
			write-output "Syntax error in PHP2URL parameter."
			exit
		}
	}
}  while ( ($status -eq $false) -and ($loop -lt 3) )  ## End Loop
if ( $status -eq $false )  {  exit  }


###################################################################################
## PHP1 - Setup and run the tests
##
$exts = "c:/wcat/conf/exts"
$tsbuild = ""
$ntsbuild = ""
$basever=""
foreach ( $build in $PHP1BuildDir )  {
	$build = $build.split('/')
	$build = [string]$build[($build.length-1)]
	$build = $build -ireplace "\.zip", ""
	if ( $build -match 'nts' )  {  $ntsbuild = $build  }
	else  {  $tsbuild = $build  }
}

## Determine build version and perf tests to run
##   $ntscache (bool) - run cached test with nts build (wincache)
##   $tscache (bool) - run cached test with ts build (apc)
##   $tscacheigbinary (bool) - run cached test with ts build using APC and Igbinary
$ntscache = $tscache = $tscacheigbinary = 0
switch ( $tsbuild )  {
	{ $_ -match "php\-5\.2" }  {
		$basever = "5.2"
		$ntscache = 1
		$tscache = 1
		$tscacheigbinary = 0
	}
	{ $_ -match "php\-5\.3" }  {
		$basever = "5.3"
		$ntscache = 1
		$tscache = 1
		$tscacheigbinary = 1
	}
	{ $_ -match "php\-5\.4" }  {
		$basever = "5.4"
		$ntscache = 1
		$tscache = 1
		$tscacheigbinary = 0
	}
	{ $_ -match "php\-5\.5" }  {
		$basever = "5.5"
		$ntscache = 1
		$tscache = 1
		$tscacheigbinary = 0
	}
	{ $_ -match "master" }  {
		$basever = "master"
		$ntscache = 0
		$tscache = 1
		$tscacheigbinary = 0
	}
	default { $basever = "master" }
}

switch ( $PHP1BuildDir )  {
	{ $_ -match 'vc9' }  {
		$APACHE_SERVICE = 'Apache2.4vc10'
		$WebSvrApacheLoc = "\\$SERVER\Apache24-vc10"
	}
	{ $_ -match 'vc11' }  {
		$APACHE_SERVICE = 'Apache2.4vc11'
		$WebSvrApacheLoc = "\\$SERVER\Apache24-vc11"
	}
}
logger "Controller (INFO): PHP1; APACHE_SERVICE = $APACHE_SERVICE, WebSvrApacheLoc = $WebSvrApacheLoc"

## Stop all web services on the server
stop-svcs $ApacheSvcs | out-null

logger "Controller: Starting PHP1 configuration."
if ( (setup-php $exts $PHP1BuildDir) -eq $false )  {
	logger "Controller: setup-php() returned error."
	write-output "Controller: setup-php() returned error."
	exit
}
if ( (setup-apache($tsbuild)) -eq $false )  {
	logger "Controller: setup-apache() returned error."
	write-output "Controller: setup-apache() returned error."
	exit
}
if ( (setup-iis($ntsbuild)) -eq $false )  {
	logger "Controller: setup-iis() returned error."
	write-output "Controller: setup-iis() returned error."
	exit
}

#
## Test Scenario #1 - Nocache
#
logger 'Controller: PHP1, Running Test Scenario #1 - Nocache'
$phpini = "c:/wcat/conf/ini/php-$basever-ts-nocache.ini"
if ( (php-configure $tsbuild $phpini) -eq $false )  {  ## Apache
	logger "Controller: php-configure() returned error: $tsbuild, $phpini"
	exit
}
$phpini = "c:/wcat/conf/ini/php-$basever-nts-nocache.ini"
if ( (php-configure $ntsbuild $phpini) -eq $false )  {  ## IIS
	logger "Controller: php-configure() returned error: $ntsbuild, $phpini"
	exit
}
c:\wcat\wcat-run-all.ps1 -SERVER "$SERVER" -TESTTYPE "nocache" -CLIENTS "$CLIENTS" -PHPVER "$PHP1" -VIRTUAL "$VIRTUAL" -APACHESVC "$APACHE_SERVICE"

#
## Test Scenario #2 - Cache
#
logger 'Controller: PHP1, Running Test Scenario #2 - Cache'
if ( $tscache -eq 1 -or $ntscache -eq 1 )  {
	$phpini = "c:/wcat/conf/ini/php-$basever-ts-cachenoigbinary.ini"
	if ( (php-configure $tsbuild $phpini) -eq $false )  {  ## Apache
		logger "Controller: php-configure() returned error: $tsbuild, $phpini"
		exit
	}

	$phpini = "c:/wcat/conf/ini/php-$basever-nts-cache.ini"
	if ( (php-configure $ntsbuild $phpini) -eq $false )  {  ## IIS
		logger "Controller: php-configure() returned error: $ntsbuild, $phpini"
		exit
	}
	c:\wcat\wcat-run-all.ps1 -SERVER "$SERVER" -TESTTYPE "cache" -CLIENTS "$CLIENTS" -PHPVER "$PHP1" -VIRTUAL "$VIRTUAL" -APACHESVC "$APACHE_SERVICE"
}

#
## Test Scenario #3 - Cache with igbinary (Apache)
#
logger 'Controller: PHP1, Running Test Scenario #3 - Cache with igbinary'
if ( $tscacheigbinary -eq 1 )  {
	$phpini = "c:/wcat/conf/ini/php-$basever-ts-cachewithigbinary.ini"
	if ( (php-configure $tsbuild $phpini) -eq $false )  {  ## Apache
		logger "Controller: php-configure() returned error: $tsbuild, $phpini"
		exit
	}
	c:\wcat\wcat-run-all.ps1 -SERVER "$SERVER" -TESTTYPE "cachewithigbinary" -CLIENTS "$CLIENTS" -PHPVER "$PHP1" -VIRTUAL "$VIRTUAL" -APACHESVC "$APACHE_SERVICE"
}


###################################################################################
## PHP2 - Setup and run the tests
##
$exts = "c:/wcat/conf/exts"
$tsbuild = ""
$ntsbuild = ""
$basever = ""
foreach ( $build in $PHP2BuildDir )  {
	$build = $build.split('/')
	$build = [string]$build[($build.length-1)]
	$build = $build -ireplace "\.zip", ""
	if ( $build -match 'nts' )  {  $ntsbuild = $build  }
	else  {  $tsbuild = $build  }  ## Some builds will not have "-ts" in the filename, i.e. stable builds "php-5.3.8-Win32-VC9-x86"
}

## Determine build version and perf tests to run
##   $ntscache (bool) - run cached test with nts build (wincache)
##   $tscache (bool) - run cached test with ts build (apc)
##   $tscacheigbinary (bool) - run cached test with ts build using APC and Igbinary
$ntscache = $tscache = $tscacheigbinary = 0
switch ( $tsbuild )  {
	{ $_ -match "php\-5\.2" }  {
		$basever = "5.2"
		$ntscache = 1
		$tscache = 1
		$tscacheigbinary = 0
	}
	{ $_ -match "php\-5\.3" }  {
		$basever = "5.3"
		$ntscache = 1
		$tscache = 1
		$tscacheigbinary = 1
	}
	{ $_ -match "php\-5\.4" }  {
		$basever = "5.4"
		$ntscache = 1
		$tscache = 1
		$tscacheigbinary = 0
	}
	{ $_ -match "php\-5\.5" }  {
		$basever = "5.5"
		$ntscache = 1
		$tscache = 1
		$tscacheigbinary = 0
	}
	{ $_ -match "master" }  {
		$basever = "master"
		$ntscache = 1
		$tscache = 1
		$tscacheigbinary = 0
	}
	default { $basever = "master" }
}

switch ( $PHP2BuildDir )  {
	{ $_ -match 'vc9' }  {
		$APACHE_SERVICE = 'Apache2.4vc10'
		$WebSvrApacheLoc = "\\$SERVER\Apache24-vc10"
	}
	{ $_ -match 'vc11' }  {
		$APACHE_SERVICE = 'Apache2.4vc11'
		$WebSvrApacheLoc = "\\$SERVER\Apache24-vc11"
	}
}
logger "Controller (INFO): PHP2; APACHE_SERVICE = $APACHE_SERVICE, WebSvrApacheLoc = $WebSvrApacheLoc"

## Stop all web services on the server
stop-svcs $ApacheSvcs | out-null

logger "Controller: Starting PHP2 configuration."
if ( (setup-php $exts $PHP2BuildDir) -eq $false )  {
	logger "Controller: setup-php() returned error."
	write-output "Controller: setup-php() returned error."
	exit
}
if ( (setup-apache($tsbuild)) -eq $false )  {
	logger "Controller: setup-apache() returned error."
	write-output "Controller: setup-apache() returned error."
	exit
}
if ( (setup-iis($ntsbuild)) -eq $false )  {
	logger "Controller: setup-iis() returned error."
	write-output "Controller: setup-iis() returned error."
	exit
}

#
## Test Scenario #1 - Nocache
#
logger 'Controller: PHP2, Running Test Scenario #1 - Nocache'
$phpini = "c:/wcat/conf/ini/php-$basever-ts-nocache.ini"
if ( (php-configure $tsbuild $phpini) -eq $false )  {  ## Apache
	logger "Controller: php-configure() returned error: $tsbuild, $phpini"
	exit
}

$phpini = "c:/wcat/conf/ini/php-$basever-nts-nocache.ini"
if ( (php-configure $ntsbuild $phpini) -eq $false )  {  ## IIS
	logger "Controller: php-configure() returned error: $ntsbuild, $phpini"
	exit
}
c:\wcat\wcat-run-all.ps1 -SERVER "$SERVER" -TESTTYPE "nocache" -CLIENTS "$CLIENTS" -PHPVER "$PHP2" -VIRTUAL "$VIRTUAL" -APACHESVC "$APACHE_SERVICE"

#
## Test Scenario #2 - Cache
#
logger 'Controller: PHP2, Running Test Scenario #2 - Cache'
if ( $tscache -eq 1 -or $ntscache -eq 1 )  {
	$phpini = "c:/wcat/conf/ini/php-$basever-ts-cachenoigbinary.ini"
	if ( (php-configure $tsbuild $phpini) -eq $false )  {  ## Apache
		logger "Controller: php-configure() returned error: $tsbuild, $phpini"
		exit
	}

	$phpini = "c:/wcat/conf/ini/php-$basever-nts-cache.ini"
	if ( (php-configure $ntsbuild $phpini) -eq $false )  {  ## IIS
		logger "Controller: php-configure() returned error: $ntsbuild, $phpini"
		exit
	}
	c:\wcat\wcat-run-all.ps1 -SERVER "$SERVER" -TESTTYPE "cache" -CLIENTS "$CLIENTS" -PHPVER "$PHP2" -VIRTUAL "$VIRTUAL" -APACHESVC "$APACHE_SERVICE"
}

#
## Test Scenario #3 - Cache with igbinary (Apache)
#
logger 'Controller: PHP2, Running Test Scenario #3 - Cache with igbinary'
if ( $tscacheigbinary -eq 1 )  {
	$phpini = "c:/wcat/conf/ini/php-$basever-ts-cachewithigbinary.ini"
	if ( (php-configure $tsbuild $phpini) -eq $false )  {  ## Apache
		logger "Controller: php-configure() returned error: $tsbuild, $phpini"
		exit
	}
	c:\wcat\wcat-run-all.ps1 -SERVER "$SERVER" -TESTTYPE "cachewithigbinary" -CLIENTS "$CLIENTS" -PHPVER "$PHP2" -VIRTUAL "$VIRTUAL" -APACHESVC "$APACHE_SERVICE"	
}

##
## Parse and archive results
$date = (get-date).Year.ToString('00')
$date += (get-date).Month.ToString('00')
$date += (get-date).Day.ToString('00')

$dirname = "$date-$PHP1-$PHP2"
$rand = $( Get-Random -min 1000 -max 9999 )
mkdir c:\wcat\results-archive\$dirname
c:\wcat\summarize-results.ps1 -PHP1 $PHP1 -PHP2 $PHP2 -VIRTUAL "8,16,32" > c:\wcat\results-archive\$dirname\results-$dirname-$rand.html
move c:\wcat\results\* c:\wcat\results-archive\$dirname
