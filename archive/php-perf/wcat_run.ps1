#%powershell1.0%
#
# File: wcat_run.ps1
# Description: This script will run the wcat test application against a web server.
#
# Example Usage:
# c:\> wcat_run.ps1 -SERVER php-web01 -SUFFIX PHP5.4.0-Apache-NoCache-Helloworld -WEBSVR Apache -CLIENTS "php-load01,php-load02" -SETFILE "c:/wcat/conf/settings-helloworld.wcat" -APACHESVC "Apache2.4vc10"

Param( $SERVER="", $SUFFIX="", $WEBSVR="", $CLIENTS="", $SETFILE="c:/wcat/settings.wcat", $VIRTUAL="8,16,32", $APACHESVC="Apache2.4vc10" )

# variable setting part
# setting file for wcat test
#$SETFILE="c:/wcat/settings.wcat"

# number of virtual machine
# can be a single integer or a comma-separated list of integers.
# for legacy support, a value of 0 is interpreted as 4,8,16,32,64
# set the total number of virtual clients
#$VIRTUAL=8,16,32

# web server testing against
#$SERVER="php-web01.ctac.nttest.microsoft.com"
#$SERVER="php-web01"

# xml file name suffix like application name
#$SUFFIX="PHP5.4.0B2-Apache-NoCache-Helloworld"

# Choose web server in window machines.  Comment and uncomment as required.
#$WEBSVR="Apache"
#$WEBSVR="IIS"

# List of load agents
#$CLIENTS="pnp-load01,php-load02,php-load03,php-load04,php-load05,php-load06,php-load07,php-load08,php-load09,php-load10"
#$CLIENTS="php-load01,php-load02"

# Begin
#------------------------------------------------------------------------------------------------

write-host
write-host "Target Server: $SERVER"
write-host "Webserver Type: $WEBSVR"
write-host "Output Suffix: $SUFFIX"
write-host "WCAT Settings: $SETFILE"
write-host "WCAT Clients: $CLIENTS"
write-host "Virtual Clients: $VIRTUAL"
if(  $WEBSVR -eq "Apache" ) {
	write-host "Apache Service: $APACHESVC"
}
write-host

Set-Location c:\wcat
$start = Get-Date
$out_dir = 'results/'+([string]::join('-',@($WEBSVR,$SUFFIX,(Get-Date -format "yyyyMMdd-hhmmss"))))
mkdir $out_dir

if ( $VIRTUAL.GetType().IsArray -eq $FALSE )  {
	$VIRTUAL = $VIRTUAL.Split(",")
}
if ( $CLIENTS.GetType().IsArray -eq $FALSE )  {
	$cl = $CLIENTS.Split(",").count
}
else  {  $cl = $CLIENTS.count  }

$i = 1;
@( $VIRTUAL ) | Foreach-Object {
	$_ = [int]$_  # SAZ, needed for formatting later.

	if ( $WEBSVR -eq "Apache" ) {
		$( winrs -r:$SERVER net stop w3svc )
		$( winrs -r:$SERVER net stop $APACHESVC )
		$( winrs -r:$SERVER del /F /Q "c:\windows\temp\ZendOPcache.MemoryBase*" )
		$( winrs -r:$SERVER del /F /Q "c:\windows\temp\Wincache*" )
		$( winrs -r:$SERVER net start $APACHESVC )
		Start-Sleep -s 10
	}
	elseif ( $WEBSVR -eq "IIS" ) {
		$( winrs -r:$SERVER net stop $APACHESVC )
		$( winrs -r:$SERVER net stop w3svc )
		$( winrs -r:$SERVER del /F /Q "c:\windows\temp\ZendOPcache.MemoryBase*" )
		$( winrs -r:$SERVER del /F /Q "c:\windows\temp\Wincache*" )
		$( winrs -r:$SERVER net start w3svc )
		$( winrs -r:$SERVER C:/windows/system32/inetsrv/appcmd start site /site.name:"Default Web Site" )
	}
	Start-Sleep -s 10

	## Run WCAT
	$OUT_FILE=$out_dir + "/" + $SERVER + "-" + $WEBSVR + "-" + $cl + "clnt-" + $_.ToString('00') + "vrtu-" + $SUFFIX + ".xml"
	c:\wcat\wcat.wsf -terminate -run -v $_ -clients $CLIENTS -f $SETFILE -s $SERVER -o $OUT_FILE 
  
	$i++
}

'Duration: '+ ('{0:00}:{1:00}:{2:00}' -f ( (Get-Date) - $start | % {$_.Hours, $_.Minutes, $_.Seconds}))
$summary_file = $out_dir + '\' + ([string]::join('-',@($WEBSVR,$SUFFIX))) + '.summary.dat'
c:/wcat/wcutil $out_dir\*.xml > $summary_file
