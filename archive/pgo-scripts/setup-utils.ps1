#%powershell1.0%
#
# File: setup-utils.ps1
# Description: Utility functions for configuring PHP, IIS and Apache
#

Function lock-get-filename ( $ver, $is_nts, $is_x64 ) {
    if ( $is_nts )  {
        $fn = 'php-nts'
    } else {
        $fn = 'php-ts'
    }

    <#if ( $is_x64 )  {
        $fn = "$fn-x64"
    } else {
        $fn = "$fn-x86"
    }

    $fn = "$fn-$PHPVER"#>

    return $fn
}

#
## Description: Check and set the lock file on the PGO host.
#
Function set-lock ( $lockfile )  {
	for ($i=0; $i -lt 120; $i++)  {
        $lock_file_path = $WebSvrPHPLoc + "\" + $lockfile
        if ( ( Invoke-Command -Session $SESSION -ScriptBlock { test-path $Using:lock_file_path } ) -eq $true )  {
			logger "set-lock($lockfile): $WebSvrPHPLoc\$lockfile exists, waiting for 60 seconds."
			Start-Sleep -s 60
		}
		else  {
			try {
				logger "set-lock($lockfile): Creating lockfile $WebSvrPHPLoc\$lockfile."
				Invoke-Command -Session $SESSION -ScriptBlock { new-item -path $Using:WebSvrPHPLoc -name $Using:lockfile -type file -ErrorAction stop | out-null }
				return $ret
			}
			catch {
				logger "set-lock($lockfile): Error creating $WebSvrPHPLoc\$lockfile, $_."
				write-output "set-lock($lockfile): Error creating $WebSvrPHPLoc\$lockfile, $_." 
				return $false
			}
		}
	}

	return $false
}

Function remove-lock ( $lockfile )  {
    $lock_file_path = $WebSvrPHPLoc + "\" + $lockfile
	logger "remove-lock($lockfile): removing lockfile $WebSvrPHPLoc\$lockfile."
	Invoke-Command -Session $SESSION -ScriptBlock { remove-item -path $Using:lock_file_path -Force -Recurse }
	if ( (Invoke-Command -Session $SESSION -ScriptBlock { test-path $Using:lock_file_path }) -eq $true )  {
		logger "remove-lock($lockfile): lockfile $WebSvrPHPLoc\$lockfile not removed."
	}
}

#
## Description: invoke a command on remote through winrs, use credentials when suppli
#
function winrs-invoke( $CMD )
{
    if ( $USER -ne "" -and $PASS -ne "" ) {
        $( winrs -r:$SERVER -u:$USER -p:$PASS $CMD )
    } else {
        $( winrs -r:$SERVER $CMD )
    }
    logger "winrs-invoke(): SERVER=$SERVER CMD=$CMD"
}

#
## Description: copy a file from local to remote, using the given session obj
# XXX Wildcard copying implementation is not recursive, extend if needed
#
function copy-to-remote( $from, $to ) {
    $from_is_dir = Test-Path $from -PathType Container
    $to_is_dir = Invoke-Command -Session $SESSION -ScriptBlock { Test-Path $Using:to -PathType Container }

    if ( $from_is_dir ) {
        $from_dirname = $from
    } else {
        $from_dirname = Split-Path $from -Resolve
    }

    if ( $from_is_dir -and $to_is_dir ) {
        Copy-Item $from -ToSession $SESSION -Destination $to -Force -Recurse
    } else {
        if ( $from -match "\*" ) {
            $from_basename = Split-Path $from -Leaf
        } else {
            $from_basename = Split-Path $from -Leaf -Resolve
        }

        if ( $to_is_dir ) {
            $to_dirname = $to
            $to_basename = ""
        } else {
            $to_dirname = Invoke-Command -Session $SESSION -ScriptBlock { Split-Path $Using:to }
            $to_basename = Invoke-Command -Session $SESSION -ScriptBlock { Split-Path $Using:to -Leaf }
        }

        Get-ChildItem $from |
            Where-Object {!$_.PsIsContainer} |
                ForEach-Object {
                    while ($SESSION.Availability -ne "Available") {
                        logger "copy-to-remote: session inavailable, waiting 1 second"
                        Start-Sleep -s 1
                    }
                    Copy-Item $_.FullName -ToSession $SESSION -Destination $to_dirname -Force
                }

# simple variant
#        Copy-Item $from -ToSession $SESSION -Destination $to_dirname -Force


        if ( $to_is_dir -eq $false -and $from_basename -ne $to_basename ) {
            $old_to = "$to_dirname\$from_basename"
            Invoke-Command -Session $SESSION -ScriptBlock { Rename-Item -Path $Using:old_to -NewName $Using:to -Force }
        }
    }
}

#
## Descriptyon: copy a file from remote to local
# XXX Wildcard copying implementation is not recursive, extend if needed
#
function copy-from-remote( $from, $to ) {
    $from_is_dir = Invoke-Command -Session $SESSION -ScriptBlock { Test-Path $Using:from -PathType Container }
    $to_is_dir = Test-Path $to -PathType Container

    if ( $from_is_dir ) {
        $from_dirname = $from
    } else {
        $from_dirname = Invoke-Command -Session $SESSION -ScriptBlock { Split-Path $Using:from -Resolve }
    }

    if ( $from_is_dir -and $to_is_dir ) {
        Copy-Item $from -FromSession $SESSION -Destination $to_dirname -Force -Recurse
    } else {
        if ( $from -match "\*" ) {
            $from_basename = Invoke-Command -Session $SESSION -ScriptBlock { Split-Path $Using:from -Leaf }
        } else {
            $from_basename = Invoke-Command -Session $SESSION -ScriptBlock { Split-Path $Using:from -Leaf -Resolve }
        }

        if ( $to_is_dir ) {
            $to_dirname = $to
            $to_basename = ""
        } else {
            $to_dirname = Split-Path $to
            $to_basename = Split-Path $to -Leaf
        }

        Invoke-Command -Session $SESSION -ScriptBlock { Get-ChildItem $Using:from } |
            Where-Object {!$_.PsIsContainer} |
                ForEach-Object {
                    while ($SESSION.Availability -ne "Available") {
                        logger "copy-from-remote: session inavailable, waiting 1 second"
                        Start-Sleep -s 1
                    }
                    Copy-Item $_.FullName -FromSession $SESSION -Destination $to_dirname -Force
                }

# simple variant
#        Copy-Item $from -FromSession $SESSION -Destination $to_dirname -Force

        Copy-Item -Path $from_dirname -Filter $from_basename -FromSession $SESSION -Destination $to_dirname -Force


        if ( $to_is_dir -eq $false -and $from_basename -ne $to_basename ) {
            $old_to = "$to_dirname\$from_basename"
            Rename-Item -Path $old_to -NewName $to -Force
        }
    }
}

#
## Description: Unzip the PHP download onto the webserver
#
Function setup-php ( $extdir="", $phploc )  {

	logger "setup-php(): Setting up PHP with exts=$extdir and php=$phploc"

	## Unzip the PHP files
	$phploc = $phploc -replace '/', '\'
	$tmp = $phploc.split('\')
	$phpzip = [string]$tmp[($tmp.length-1)]
	$phpdir = $phpzip -ireplace "\.zip", ""

    $php_dir_path = $WebSvrPHPLoc + "\" + $phpdir
	if ( (Invoke-Command -Session $SESSION -ScriptBlock { test-path $Using:php_dir_path }) -eq $true )  {
		logger "setup-php(): The directory $WebSvrPHPLoc\$phpdir exists, removing."
		Invoke-Command -Session $SESSION -ScriptBlock { Remove-Item $Using:php_dir_path -Recurse -Force | out-null }
	}

	logger "setup-php(): Unzipping $phploc into $WebSvrPHPLoc\$phpdir"
	Invoke-Command -Session $SESSION -ScriptBlock { new-item -path $Using:WebSvrPHPLoc -name $Using:phpdir -type directory -Force | out-null }

## This method apparently does not work when called as a background process.
#	$shell = new-object -com shell.application
#	$zipsource = $shell.namespace( "$phploc" )
#	$destination = $shell.namespace( "$WebSvrPHPLoc\$phpdir" )
#	$destination.Copyhere( $zipsource.items(), 20 )

#	$out = & $LocalPHPBin "$BaseDir\unzip.php" "$phploc" "$WebSvrPHPLoc\$phpdir"
    copy-to-remote $phploc $WebSvrPHPLoc
    winrs-invoke "$REMOTE_BASE_APPS\php\php.exe $REMOTE_BASE\scripts\unzip.php $WebSvrPHPLoc\$phpzip $WebSvrPHPLoc\$phpdir"
    $php_cgi_path = $php_dir_path + "\php-cgi.exe"
	if ( $LastExitCode -ne 0 -or ( Invoke-Command -Session $SESSION -ScriptBlock { test-path $Using:php_cgi_path } ) -eq $false )  {
		logger "setup-php(): Error, $WebSvrPHPLoc\$phpdir\php-cgi.exe does not exist."
		return $false
	}

#	copy-item -Force "$extdir\*" -destination "$WebSvrPHPLoc\$phpdir\ext\" -recurse  ## PECL support
}


#
## Description: Configure PHP for Apache.
#
Function setup-apache( $phppath="", $ver = "2.4" )  {
	if ( $phppath -eq "" )  {
		return $false
	}
	logger "setup-apache(): Setting up Apache using PHP=$phppath"

	$phpdir = $RemoteBaseDir -replace '\\', '/'

	if ( ($ver -ne "2.4") -and ($ver -ne "2.2") ) {
		logger "setup-apache: unknown apache version '$ver'"
		return $false
	}
	if ( $ver -eq "2.4" ) {
		$dll = "php7apache2_4.dll"
	} else {
		$dll = "php7apache2_2.dll"
	}
	
	$conffile = "$WebSvrApacheLoc/conf/extra/httpd-php.conf"
	$config = "LoadModule php7_module `"$phpdir/$phppath/$dll`"`n"
	$config += "AddType application/x-httpd-php .php`n"
	$config += "PHPIniDir `"$phpdir/$phppath`"`n"

	$config | Out-File -encoding ASCII $conffile
	if ( (test-path $conffile) -eq $false )  {
		return $false
	}

	winrs-invoke "rmdir `"c:\apps\$APACHE_DIR\php_deps`""
	winrs-invoke "mklink /d `"c:\apps\$APACHE_DIR\php_deps`" `"$RemoteBaseDir\$phppath`""
}

#
## Description: Configure PHP for IIS.
#
Function setup-iis( $phppath="", $trans=0 )  {
	logger "setup-iis(): Setting up IIS with PHP=$phppath, Transactions=$trans"
	if ( ($phppath -eq "") -or ($trans -eq "") )  {
		return $false
	}
#Set-PSDebug -Trace 1
	## Clear any current PHP handlers
	winrs-invoke "%windir%\system32\inetsrv\appcmd clear config /section:system.webServer/fastCGI"
	winrs-invoke "%windir%\system32\inetsrv\appcmd set config /section:system.webServer/handlers /-[name='PHP_via_FastCGI']"

	## Set up the PHP handler
	winrs-invoke "%windir%\system32\inetsrv\appcmd set config /section:system.webServer/fastCGI /+[fullPath=`'$RemoteBaseDir\$phppath\php-cgi.exe`']"
	winrs-invoke "%windir%\system32\inetsrv\appcmd set config /section:system.webServer/handlers /+[name='PHP_via_FastCGI',path='*.php',verb='*',modules='FastCgiModule',scriptProcessor=`'$RemoteBaseDir\$phppath\php-cgi.exe`',resourceType='Unspecified']"
	winrs-invoke "%windir%\system32\inetsrv\appcmd set config /section:system.webServer/handlers /accessPolicy:Read,Script"

	## Configure FastCGI variables
	winrs-invoke "%windir%\system32\inetsrv\appcmd set config -section:system.webServer/fastCgi /[fullPath=`'$RemoteBaseDir\$phppath\php-cgi.exe`'].instanceMaxRequests:10000"
	winrs-invoke "%windir%\system32\inetsrv\appcmd set config -section:system.webServer/fastCgi /[fullPath=`'$RemoteBaseDir\$phppath\php-cgi.exe`'].MaxInstances:1"
	winrs-invoke "%windir%\system32\inetsrv\appcmd.exe set config -section:system.webServer/fastCgi /+`"[fullPath=`'$RemoteBaseDir\$phppath\php-cgi.exe`'].environmentVariables.[name='PHP_FCGI_MAX_REQUESTS',value=`'$trans`']`""
	winrs-invoke "%windir%\system32\inetsrv\appcmd.exe set config -section:system.webServer/fastCgi /+`"[fullPath=`'$RemoteBaseDir\$phppath\php-cgi.exe`'].environmentVariables.[name='PHPRC',value=`'$RemoteBaseDir\$phppath\php.ini`']`""
#Set-PSDebug -Off
}


#
## Description: Copy a php.ini onto the webserver.
#
function php-configure( $phppath="", $phpini="" )  {
	if ( ($phppath -eq "") -or ($phpini -eq "") )  {
		return $false
	}
	logger "php-configure(): Configuring PHP with PHP=$phppath and INI=$phpini"

    $phpdir = $RemoteBaseDir -replace '\\', '/'
    $php_ini_path = $WebSvrPHPLoc + "\" + $phppath + "\php.ini"

    copy-to-remote "$phpini" "$php_ini_path"

	if ( $phppath -ne "nts" )  {
        
		Invoke-Command -Session $SESSION -ScriptBlock {
            $contents = get-content $Using:php_ini_path
            out-file -encoding ASCII -Force $Using:php_ini_path
            
            Foreach ( $line in $contents )  {
			    if ( $line -match "^extension_dir" )  {
				    $line = "extension_dir = `"$Using:phpdir/$Using:phppath/ext`""
			    }
			    $line | out-file -encoding ASCII -append $Using:php_ini_path
		    }
        }
	}
	if ( $OPCACHE -eq 1 )  {
		Invoke-Command -Session $SESSION -ScriptBlock {
            $contents =  get-content $Using:php_ini_path
		    out-file -encoding ASCII -Force $Using:php_ini_path
		    Foreach ( $line in $contents )  {
			    if ( $line -match "^zend_extension=php_opcache" )  {
				    $line = "zend_extension=`"$Using:phpdir/$Using:phppath/ext/php_opcache.dll`""
			    }
			    $Using:line | out-file -encoding ASCII -append $Using:php_ini_path
		    }
        }
	}

	return $true
}

