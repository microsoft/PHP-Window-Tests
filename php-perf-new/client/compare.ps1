Param(
	[String] $Name1 = "php1",
	[Parameter(Mandatory=$true)]
	[String] $Url1,
	[String] $Name2 = "php2",
	[Parameter(Mandatory=$true)]
	[String] $Url2
)

$php_urls = $Url1, $Url2
$php_names = $Name1, $Name2

$WEB_SERVER = $Env:WCAT_WEB_IP
$WINRM_USER = $Env:WCAT_WEB_USER

$pw = convertto-securestring -AsPlainText -Force -String $Env:WCAT_WEB_PASS
$cred = new-object -typename System.Management.Automation.PSCredential -argumentlist $WEB_SERVER\$WINRM_USER,$pw

for ($i = 0; $i -lt $php_urls.count; ++$i) {

	$php_url = $php_urls[$i]

    $sess_web = New-PSSession -ComputerName $WEB_SERVER -Credential $cred
    $outfolder = "results\iis\$($php_names[$i])"
    Invoke-Command -Session $sess_web -ScriptBlock { C:\Users\ostc\Desktop\setup-php.bat $Using:php_url }
    mkdir $outfolder
    Invoke-WebRequest -Uri http://$WEB_SERVER/phpinfo.php -OutFile $outfolder\phpinfo.html
    ./run.ps1
    move results\*.xml $outfolder
    Invoke-WebRequest -Uri http://$WEB_SERVER/phperrors.php -OutFile $outfolder\phperror.log

    $sess_web = New-PSSession -ComputerName $WEB_SERVER -Credential $cred
    $outfolder = "results\iis\$($php_names[$i])-opcache"
    Invoke-Command -Session $sess_web -ScriptBlock { C:\Users\ostc\Desktop\enable-opcache.bat $Using:php_url }
    mkdir $outfolder
    Invoke-WebRequest -Uri http://$WEB_SERVER/phpinfo.php -OutFile $outfolder\phpinfo.html
    ./run.ps1
    move results\*.xml $outfolder
    Invoke-WebRequest -Uri http://$WEB_SERVER/phperrors.php -OutFile $outfolder\phperror.log
}

copy .\conf\versions.ini .\results\iis\versions.ini

cd results
& C:\php\php.exe ..\report_iis.php $Name1 $Name2 > iis\$Name1-$Name2.html
cd ..

Compress-Archive -Path .\results\iis\* -DestinationPath .\results\iis\$Name1-$Name2.zip
