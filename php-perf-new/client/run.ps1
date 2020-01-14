# Runs a single performance test
#
# The Webserver and database server have to be properly configured.
# The WCAT *.xml results are stored in results/.

Param(
	[Bool] $USE_IIS = $True,
	[Int[]] $VirtualClients = @(32, 16, 8),
	[String[]] $Apps = @('wordpress', 'drupal', 'laravel', <#'yii',#> 'helloworld', 'symfony', <#'phalcon',#> 'mediawiki', 'joomla')
)

$WEB_SERVER = $Env:WCAT_WEB_IP
$DB_SERVER = $Env:WCAT_DB_IP
$WCAT_CLIENTS = $Env:WCAT_CLIENT_IPS

$WEB_USER = $Env:WCAT_WEB_USER
$DB_USER = $Env:WCAT_DB_USER

$pw = convertto-securestring -AsPlainText -Force -String $Env:WCAT_WEB_PASS
$cred = new-object -typename System.Management.Automation.PSCredential -argumentlist $WEB_SERVER\$WEB_USER,$pw
$sess_web = New-PSSession -ComputerName $WEB_SERVER -Credential $cred

$pw = convertto-securestring -AsPlainText -Force -String $Env:WCAT_DB_PASS
$cred = new-object -typename System.Management.Automation.PSCredential -argumentlist $DB_SERVER\$DB_USER,$pw
$sess_db = New-PSSession -ComputerName $DB_SERVER -Credential $cred

Function CleanState() {
	# Note: OS (on web server and database server) has some internal structures (TCB, etc...) for handling TCP sockets
	#       this will not reset those between test runs - those add some overhead in connection creation so subsequent
	#       test runs may be faster than the first (very slightly)
	
	# ensure a clean state between each test run:
	
	#Invoke-Command -Session $sess_web -ScriptBlock { httpd -k INSTALL }
	
	#Invoke-Command -Session $sess_web -ScriptBlock { httpd -k STOP }
	Invoke-Command -Session $sess_web -ScriptBlock { Stop-Service -Name Apache2.4 }
	Invoke-Command -Session $sess_web -ScriptBlock { Stop-Service -Name W3SVC }
	
	Invoke-Command -Session $sess_db -ScriptBlock { Stop-Service -Name MySQL57 }
	
	Invoke-Command -Session $sess_web -ScriptBlock { cports /close * 80 * * }
	Invoke-Command -Session $sess_db -ScriptBlock { cports /close * 3306 * * }
	
	
	# ensure PHP is stopped 
	#
	# Symfony sometimes seems to cause php-cgi.exe processes to go to 100% and not die when IIS stopped/restarted
	#	
	Invoke-Command -Session $sess_web -ScriptBlock { Get-Process -Name php-cgi -ErrorAction SilentlyContinue | Stop-Process -Force }
	
	if ( -Not $USE_IIS ) {
		Invoke-Command -Session $sess_web -ScriptBlock { httpd -k INSTALL }
		Invoke-Command -Session $sess_web -ScriptBlock { httpd -k START }
		#Invoke-Command -Session $sess_web -ScriptBlock { httpd -k UNINSTALL }
	} else {
		Invoke-Command -Session $sess_web -ScriptBlock { Start-Service -Name W3SVC }
	}
	
	Invoke-Command -Session $sess_db -ScriptBlock { Start-Service -Name MySQL57 }
		
	#sleep 65 # try to compensate for the "improvement" from azure's new "accelerated networking" feature
	# NOTE: wcat does some requests to warmup the server before starting a test run
}

CleanState
foreach ($app in $Apps) {
	foreach ($vc in $VirtualClients) {
		wcat.wsf -terminate -run -v $vc -clients $WCAT_CLIENTS -t .\conf\scenario-$app.wcat -f .\conf\settings-$app.wcat -o .\results\$app-$vc.xml -s $WEB_SERVER
		CleanState
	}
}

# these tend to accumulate and use a lot of memory - try to clean them up
Invoke-Command -Session $sess_web -ScriptBlock { Stop-Process -Name WSMPROVHOST -Force }
Invoke-Command -Session $sess_db -ScriptBlock { Stop-Process -Name WSMPROVHOST -Force }
