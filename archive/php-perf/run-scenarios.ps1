#%powershell1.0%
#
# File: run-scenarios.ps1
# Description: Run through a number of scenarios, each comparing two versions of PHP.
# This is the file you will likely run for an automated approach.
#
# Example Usage:
# c:\> run-scenarios.ps1
#

## Archive the old log file for this test run.
if ( (test-path "c:\wcat\autocat-log.txt") -ne $false )  {
	$date = (get-date).Year.ToString('00')
	$date += (get-date).Month.ToString('00')
	$date += (get-date).Day.ToString('00')+'-'
	$date += (get-date).Hour.ToString('00')
	$date += (get-date).Minute.ToString('00')
	$destination = "c:\wcat\logs\autocat-log-"+$date+".txt"
	move-item -path "c:\wcat\autocat-log.txt" -destination $destination
}


## Example Scenarios

## 5.3 Release <-> 5.4 QA
#write-host '5.3 Release <-> 5.4 QA'
#c:\wcat\controller.ps1 -PHP1 "5.3.8" -PHP1URL "http://windows.php.net/downloads/releases/php-5.3.8-Win32-VC9-x86.zip,http://windows.php.net/downloads/releases/php-5.3.8-nts-Win32-VC9-x86.zip" -PHP2 "5.4.0RC1" -PHP2URL "http://windows.php.net/downloads/qa/php-5.4.0RC2-Win32-VC9-x86.zip,http://windows.php.net/downloads/qa/php-5.4.0RC2-nts-Win32-VC9-x86.zip"

## 5.3 Release <-> 5.3 QA
#write-host '5.3 Release <-> 5.3 QA'
#c:\wcat\controller.ps1 -PHP1 "5.3.8" -PHP1URL "http://windows.php.net/downloads/releases/php-5.3.8-Win32-VC9-x86.zip,http://windows.php.net/downloads/releases/php-5.3.8-nts-Win32-VC9-x86.zip" -PHP2 "5.3.9RC1" -PHP2URL "http://windows.php.net/downloads/qa/php-5.3.9RC2-nts-Win32-VC9-x86.zip,http://windows.php.net/downloads/qa/php-5.3.9RC2-Win32-VC9-x86.zip"

## 5.3 QA <-> 5.3 Snap
#write-host '5.3 QA <-> 5.3 Snap'
#c:\wcat\controller.ps1 -PHP1 "5.3.9RC1" -PHP1URL "http://windows.php.net/downloads/qa/php-5.3.9RC2-nts-Win32-VC9-x86.zip,http://windows.php.net/downloads/qa/php-5.3.9RC2-Win32-VC9-x86.zip" -PHP2 "5.3.9" -PHP2URL "5.3"

## 5.3 Release <-> 5.4 Snap
#write-host '5.3 Release <-> 5.4 Snap'
#c:\wcat\controller.ps1 -PHP1 "5.3.8" -PHP1URL "http://windows.php.net/downloads/releases/php-5.3.8-Win32-VC9-x86.zip,http://windows.php.net/downloads/releases/php-5.3.8-nts-Win32-VC9-x86.zip" -PHP2 "5.4.0" -PHP2URL "5.4"

## 5.4 QA <-> 5.4 Snap
#write-host '5.4 QA <-> 5.4 Snap'
#c:\wcat\controller.ps1 -PHP1 "5.4.0RC1" -PHP1URL "http://windows.php.net/downloads/qa/php-5.4.0RC2-Win32-VC9-x86.zip,http://windows.php.net/downloads/qa/php-5.4.0RC2-nts-Win32-VC9-x86.zip" -PHP2 "5.4.0" -PHP2URL "5.4"

