#%powershell1.0%
#
# File: setup-utils.ps1
# Description: Utility functions for configuring PHP, IIS and Apache
#

#
## Description: Unzip the PHP download onto the webserver.
#
Function setup-php ( $extdir="", $phploc )  {

	logger "setup-php(): Setting up PHP with exts=$extdir and php=$phploc"
	if ( $phploc.GetType().IsArray -eq $true )  {
		if ( $phploc.length -eq 0 )  {
			return $false
		}
	}
	else  {
			return $false
	}

	foreach ( $zipfile in $phploc )  {
		## unzip the PHP files
		$phpdir = $zipfile.split('/')
		$phpdir = [string]$phpdir[($phpdir.length-1)]
		$phpdir = $phpdir -ireplace "\.zip", ""
		$zipfile = $zipfile -replace '/', '\'

		logger "setup-php(): Unzipping $zipfile into $WebSvrPHPLoc\$phpdir"
		new-item -path $WebSvrPHPLoc -name $phpdir -type directory -force
		$shell = new-object -com shell.application
		$zipsource = $shell.namespace( "$zipfile" )
		$destination = $shell.namespace( "$WebSvrPHPLoc\$phpdir" )
		$destination.Copyhere( $zipsource.items(), 0x14 )
		if ( (test-path "$WebSvrPHPLoc\$phpdir\php-cgi.exe") -eq $false )  {
			return $false
		}

		## PECL extensions
		## $extdir is organized as $extdir\$version\$ts\$compiler\$arch, i.e. "$extdir\5.5\nts\vc9\x86\"
		$version = 'master'
		$ts = 'ts'
		$compiler = ''
		$arch = 'x86'
		if ( $zipfile -match "\d.\d" )  {
			$version = $matches[0]
		}
		if ( $zipfile -match "nts" )  {
			$ts = 'nts'
		}
		if ( $zipfile -match "vc\d\d?" )  {
			$compiler = $matches[0]
		}
		if ( $zipfile -match 'x64' )  {
			$arch = 'x64'
		}
		copy-item -Force "$extdir/$version/$ts/$compiler/$arch/*" -destination "$WebSvrPHPLoc\$phpdir\ext\" -recurse
	}
}


#
## Description: Configure PHP for Apache.
#
Function setup-apache( $phppath="" )  {
	if ( $phppath -eq "" )  {
		return $false
	}
	logger "setup-apache(): Setting up Apache using PHP=$phppath"

	$conffile = "$WebSvrApacheLoc/conf/extra/httpd-php.conf"
	$config = "LoadModule php5_module `"c:/php/$phppath/php5apache2_4.dll`"`n"
	$config += "AddType application/x-httpd-php .php`n"
	$config += "PHPIniDir `"c:/php/$phppath`"`n"

	$config | Out-File -encoding ASCII $conffile
	if ( (test-path $conffile) -eq $false )  {
		return $false
	}
}


#
## Description: Configure PHP for IIS.
#
Function setup-iis( $phppath="" )  {
	if ( $phppath -eq "" )  {
		return $false
	}
	logger "setup-iis(): Setting up IIS with PHP=$phppath"

	## Clear any current PHP handlers
	$( winrs -r:$SERVER "%windir%\system32\inetsrv\appcmd clear config /section:system.webServer/fastCGI" )
	$( winrs -r:$SERVER "%windir%\system32\inetsrv\appcmd set config /section:system.webServer/handlers /-[name='PHP_via_FastCGI']" )

	## Set up the PHP handler
	$( winrs -r:$SERVER "%windir%\system32\inetsrv\appcmd set config /section:system.webServer/fastCGI /+[fullPath=`'c:\php\$phppath\php-cgi.exe`']" )
	$( winrs -r:$SERVER "%windir%\system32\inetsrv\appcmd set config /section:system.webServer/handlers /+[name='PHP_via_FastCGI',path='*.php',verb='*',modules='FastCgiModule',scriptProcessor=`'c:\php\$phppath\php-cgi.exe`',resourceType='Unspecified']" )
	$( winrs -r:$SERVER "%windir%\system32\inetsrv\appcmd set config /section:system.webServer/handlers /accessPolicy:Read,Script" )

	## Configure FastCGI variables
	$( winrs -r:$SERVER "%windir%\system32\inetsrv\appcmd set config -section:system.webServer/fastCgi /[fullPath=`'c:\php\$phppath\php-cgi.exe`'].instanceMaxRequests:10000" )
	$( winrs -r:$SERVER "%windir%\system32\inetsrv\appcmd.exe set config -section:system.webServer/fastCgi /+`"[fullPath=`'c:\php\$phppath\php-cgi.exe`'].environmentVariables.[name='PHP_FCGI_MAX_REQUESTS',value='10000']`"" )
	$( winrs -r:$SERVER "%windir%\system32\inetsrv\appcmd.exe set config -section:system.webServer/fastCgi /+`"[fullPath=`'c:\php\$phppath\php-cgi.exe`'].environmentVariables.[name='PHPRC',value=`'c:\php\$phppath\php.ini`']`"" )
}


#
## Description: Copy a php.ini onto the webserver.
#
function php-configure( $phppath="", $phpini="" )  {
	if ( ($phppath -eq "") -or ($phpini -eq "") )  {
		return $false
	}
	logger "php-configure(): Configuring PHP with PHP=$phppath and INI=$phpini"
	copy-item "$phpini" -destination "$WebSvrPHPLoc/$phppath/php.ini"

	if ( $phppath -ne "nts" )  {
		$contents = (get-content "$WebSvrPHPLoc/$phppath/php.ini")
		out-file -encoding ASCII -Force "$WebSvrPHPLoc/$phppath/php.ini"
		Foreach ( $line in $contents )  {
			if ( $line -match "^extension_dir" )  {
				$line = "extension_dir = `"C:/php/$phppath/ext`""
			}
			elseif ( $line -match "^zend_extension=php_opcache" )  {
				$line = "zend_extension=`"C:/php/$phppath/ext/php_opcache.dll`""
			}
			$line | out-file -encoding ASCII -append "$WebSvrPHPLoc/$phppath/php.ini"
		}
	}
}

function stop-svcs ( $services ) {
	## Stop all web services on the server
	foreach ( $svc in $services )  {
		$( winrs -r:$SERVER net stop $svc )
	}
	$( winrs -r:$SERVER net stop w3svc )

	return $true
}

