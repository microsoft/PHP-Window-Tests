#%powershell1.0%
#
# File: pgo_controller.ps1
# Description:
# 	- Deploy PGI build on remote server
#	- Set up IIS and Apache with PGI builds of PHP
#	- Run training scripts to collect profiling data
#	- Collect .pgc files
#
## Example: pgo_controller.ps1 -PHPBUILD C:\obj\ts-windows-vc9-x86\Release_TS\php-5.4.0RC6-dev-Win32-VC9-x86.zip -PHPVER php-5.4

Param( $PHPBUILD="", $PHPVER="", $APACHEVER="2.4", $OPCACHE=0, $SERVER="", $USER="", $PASS="" )
if ( ($PHPBUILD -eq "") -or ($PHPVER -eq "") )  {
	write-output "Usage: pgo_controller.ps1 -PHPBUILD <path_to_.zip> -PHPVER <php_ver> [-APACHEVER <ver>] [-OPCACHE 0|1] [-USER <name] [-PASS <pass>]"
	exit
}

$IS_NTS = $PHPBUILD -match "nts"
$IS_X64 = $PHPBUILD -match "x64"

if ( ($APACHEVER -ne "2.4") -and ($APACHEVER -ne "2.2") ) {
    write-output "Unknown Apache version, only 2.2 and 2.4 are supported";
    exit
}
if ( $APACHEVER -eq "2.4" ) {
    $APACHE_SERVICE = "Apache2.4"
    $APACHE_DIR = "Apache24"
} else {
    $APACHE_SERVICE = "Apache2.2"
    $APACHE_DIR = "Apache2"
}

if ( ($SERVER -eq "") ) {
    $SERVER = "php-php7-pgo01"
}

$SESSION = $false
if ( ($USER -ne "") -and ($PASS -eq "") ) {
    $PASS_SECURE = Read-Host "Enter password" -AsSecureString
    $PASS = [Runtime.InteropServices.Marshal]::PtrToStringAuto([Runtime.InteropServices.Marshal]::SecureStringToBSTR($PASS_SECURE))
} else {
    $PASS_SECURE = ConvertTo-SecureString -String $PASS
}

$CRED = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $USER, $PASS_SECURE
# XXX provide another session instattiation, for the case credentials are not used
$SESSION = New-PSSession -computername $SERVER -Credential $CRED


# copy from remote
# can't rename while copying, so have to do separately if needed
# c:\pgo\hello0.txt is the path on remote
# Copy-Item c:\pgo\hello0.txt -FromSession $session -Destination .

# copy to remote
# .\log.txt is the path on local
# copy-item .\log.txt -ToSession $session -Destination c:\pgo 


#Set-Variable -Name SERVER -Option AllScope
#Set-Variable -Name USER -Option AllScope
#Set-Variable -Name PASS -Option AllScope

$REMOTE_BASE = "c:\pgo"
$REMOTE_BASE_APPS = "c:\apps"
$LOCAL_BASE = "c:\php-sdk\pgo-build"
$LOCAL_BASE_APPS = "$LOCAL_BASE\apps"

$WebSvrPHPLoc = $REMOTE_BASE
$WebSvrApacheLoc = "$REMOTE_BASE_APPS\$APACHE_DIR"
$RemoteBaseDir = $REMOTE_BASE
$RemotePHPBin = "$REMOTE_BASE_APPS\php\php.exe"

$BaseDir = $LOCAL_BASE
$LocalPHPBin = "C:\php-sdk\php\php.exe"
$BaseBuildDir = "c:\php-sdk"
$ObjDir = "$PHPBUILD\..\obj"

Set-Variable -Name WebSvrPHPLoc -Option AllScope

## Import needed functions
Set-Location $BaseDir
. .\setup-utils.ps1

## Simple logging function.
Function logger ( $msg )  {
	$logfile = "$BaseDir\log.txt"
	$msg = (get-date -format "yyyy-MM-dd HH:mm:ss")+" $msg"
	$msg | Out-File -Encoding ASCII -Append $logfile
}

###################################################################################
## Setup PHP and run the profiling tools.
##

$build = ""
$PHPBUILD = $PHPBUILD -replace '/', '\'
$build = $PHPBUILD.split('\')
$build = [string]$build[($build.length-1)]
$build = $build -ireplace "\.zip", ""

$trans = invoke-expression -command "$LocalPHPBin $WebSvrPHPLoc\scripts\pgo.php printnum"
$trans = [string]$trans
$trans = $trans.split(':')
$trans = $trans[$trans.length-1].trim()

$exts = $build.split('-')
$exts = 'pecl-'+$exts[1]
$exts = ($PHPBUILD -replace '\\php\-\d.+$', '') + '\' + $exts

## Locking here.

$lockfile = lock-get-filename $PHPVER $IS_NTS $IS_X64
if ((set-lock $lockfile) -eq $false )  {
	logger "PGO Controller: set-lock($lockfile) returned error."
	write-output "PGO Controller: set-lock($lockfile) returned error."
	exit
}
## end locking

## Stop relevant web services on the server
logger "PGO Controller: Starting PHP configuration."
if ( $PHPBUILD -match "nts" )  {
	winrs-invoke "net stop w3svc"
}
else  {
	winrs-invoke "net stop $APACHE_SERVICE"
}

## Copy and set up PHP runtime.
if ( (setup-php $exts $PHPBUILD) -eq $false )  {
	logger "PGO Controller: setup-php() returned error."
	write-output "PGO Controller: setup-php() returned error."
	remove-lock $lockfile
	exit
}

## Set up IIS or Apache
if ( $PHPBUILD -match "nts" )  {
	if ( (setup-iis $build $trans) -eq $false )  {
		logger "PGO Controller: setup-iis() returned error."
		write-output "PGO Controller: setup-iis() returned error."
		remove-lock $lockfile
		exit
	}
}
else  {
	if ( (setup-apache($build)) -eq $false )  {
		logger "PGO Controller: setup-apache() returned error."
		write-output "PGO Controller: setup-apache() returned error."
		remove-lock $lockfile
		exit
	}
}

if ( $PHPBUILD -match "nts" )  {
	$phpini = "$BaseDir/conf/ini/$PHPVER-pgo-nts.ini"
	if ( $OPCACHE -eq 1 )  {
		$phpini = "$BaseDir/ini/$PHPVER-pgo-nts-cache.ini"
	}
	if ( (php-configure $build $phpini) -eq $false )  {
		logger "PGP Controller: php-configure() returned error: $build, $phpini"
		remove-lock $lockfile
		exit
	}
    winrs-invoke "net stop w3svc"
    winrs-invoke "net start w3svc"
    winrs-invoke "C:/windows/system32/inetsrv/appcmd stop site /site.name:`"Default Web Site`""
    winrs-invoke "C:/windows/system32/inetsrv/appcmd start site /site.name:`"wordpress`""
    <#winrs-invoke "C:/windows/system32/inetsrv/appcmd start site /site.name:`"drupal`""
    winrs-invoke "C:/windows/system32/inetsrv/appcmd start site /site.name:`"joomla`""
    winrs-invoke "C:/windows/system32/inetsrv/appcmd start site /site.name:`"mediawiki`""
    winrs-invoke "C:/windows/system32/inetsrv/appcmd start site /site.name:`"phpbb`""
    winrs-invoke "C:/windows/system32/inetsrv/appcmd start site /site.name:`"symfony`""#>
    winrs-invoke "powershell C:\pgo\scripts\pgo-iis.ps1 -PHPBUILD $build"
}
else  {
	$phpini = "$BaseDir/conf/ini/$PHPVER-pgo-ts.ini"
	if ( $OPCACHE -eq 1 )  {
		$phpini = "$BaseDir/ini/$PHPVER-pgo-ts-cache.ini"
	}
	if ( (test-path "$exts\php_apc.dll") -eq $true )  {
		$phpini = "$BaseDir/ini/$PHPVER-pgo-ts-apc.ini"
	}
	if ( (php-configure $build $phpini) -eq $false )  {
		logger "PGO Controller: php-configure() returned error: $build, $phpini"
		remove-lock $lockfile
		exit
	}
	winrs-invoke "net stop $APACHE_SERVICE"
    winrs-invoke "net start $APACHE_SERVICE"
	winrs-invoke "$RemotePHPBin C:\pgo\scripts\pgo.php localhost 8080"
}

if ( $PHPBUILD -match "nts" )  {
	winrs-invoke "net stop w3svc"
}
else  {
	winrs-invoke "net stop $APACHE_SERVICE"
}

## Important - need to give instrumentation time to
## create .pgc files after stopping the server.
Start-Sleep -s 10

## Collect the .pgc files
$LocalBuildDir = $PHPBUILD -replace "$build\.zip", ''
if ( $OPCACHE -eq 1 )  {
	copy-item -force "$WebSvrPHPLoc/$build/ext/php_opcache*.pgc" -destination $LocalBuildDir
}
else  {
	remove-item "$LocalBuildDir/*.pgc" -force

    $main_pgc = "$WebSvrPHPLoc/$build/*.pgc"
    $ext_pgc = "$WebSvrPHPLoc/$build/ext/*.pgc"
    copy-from-remote $main_pgc $LocalBuildDir
    copy-from-remote $ext_pgc $LocalBuildDir
}

## Remove lock
remove-lock $lockfile

## close opened sessions
Get-PSSession | Remove-PSSession
