<#
.SYNOPSIS
  This runs all tests against snapshot builds of PHP.
.DESCRIPTION
  The script will download the latest build and test pack of the given branch.  Then it will run a set of tests using run-test.php.
.PARAMETER Branch
  Branch of PHP to test.  7.2, 7.3, and 7.4 are supported.
.PARAMETER cpu
  CPU flavor of PHP to test.  x86 and x64 are supported.
.PARAMETER thread
  Thread safe version of PHP to test.  TS (thread safe), NTS (not thread safe) are supported.
.PARAMETER revision
  Specific revision to test.  Default is latest.
.PARAMETER pause
  This is useful for debugging purposes as it pauses right before exiting, and closing the Powershell window.
.EXAMPLE
  .\test_snap.ps1 -branch 7.4 -cpu x86 -thread TS -pause
.NOTES
  The following variables need to be set:
	$env:Build_ArtifactStagingDirectory
  The following variables can be set to either 'true' or 'false':
	$env:CLEANDIRECTORIES
	$env:CLEANRESULTS  
#>
[CmdletBinding(SupportsShouldProcess=$true)]
param(
    
	[Parameter(Mandatory)]
	[ValidateSet('7.2','7.3', '7.4')]
	[string]$Branch,
	[Parameter(Mandatory)]
	[ValidateSet('x86','x64')]
	[string]$cpu,
	[Parameter(Mandatory)]
	[ValidateSet('NTS','TS')]
	[string]$thread,
	[string]$revision = "latest",
	[switch]$pause
)
begin {
	# Set Environmental variables
	Import-Module $PSScriptRoot\Util.ps1 -Force

	Set-PHPEnvironmentVariables

	$build="vc15"
	$buildNeeded = "$thread-windows-$build-$cpu"

	# Get version information
	if($revision -eq "latest") {
		$SNAP_JSON="php-$branch.json"
		$SNAP_JSON_URL="https://windows.php.net/downloads/snaps/php-$branch/$SNAP_JSON"

		$snapJson = Get-StringFromUrl $SNAP_JSON_URL | ConvertFrom-Json

		$revision = "r$($snapJson.revision_last_exported)"
		if ($snapJson.builds -notcontains $buildNeeded) {
			write-error ">>> Build $buildNeeded not found"
			exit
		}
	}
	else {
		if ($revision[0] -ne 'r') {
			$revision = "r$revision"
		}
	}

	$test_pack="php-test-pack-$branch-$thread-windows-$build-$cpu-$revision"
	$build_pack="php-$branch-$thread-windows-$build-$cpu-$revision"

	$buildDirectory = Join-Path $env:PHP_BUILDS $build_pack
	$testDirectory = Join-Path $env:PHP_BUILDS $test_pack
	$outputDirectory = Join-Path $testDirectory "output"

	Write-host ">>> Current Build Pack: $build_pack"
	Write-Host ">>> Current Test Pack: $test_pack"

	# Download version and test pack if not unzipped already
	if(!(Test-Path $env:PHP_BUILDS)) {
		write-host ">>> Creating" $env:PHP_BUILDS
		mkdir $env:PHP_BUILDS
	}

	if(!(Test-Path $env:PHP_CACHE)) {
		write-host ">>> Creating" $env:PHP_CACHE
		mkdir $env:PHP_CACHE
	}

	# Check to see if we have set the CLEANDIRECTORIES 
	# Environmental variable to true
	if ((Test-Path env:\CLEANDIRECTORIES) -and
		($true -eq $env:CLEANDIRECTORIES)) {
		
		if ((Test-Path $BuildDirectory)) {
			write-host ">>> Cleaning $buildDirectory	"
			remove-item -Path $buildDirectory -Recurse -Force
		}

		if ((Test-Path $testDirectory)) {
			write-host ">>> Cleaning $testDirectory	"
			remove-item -Path $testDirectory -Recurse -Force
		}
	}

	if (!(Test-Path $buildDirectory)) {
		write-host ">>> Preparing $buildDirectory" 
		$build_link="https://windows.php.net/downloads/snaps/php-$branch/$revision/$build_pack.zip"
		$local_path = (join-path $env:PHP_CACHE "$build_pack.zip")

		Restore-PhpDownload -Uri $build_link -LocalPath $local_path			
	}

	if (!(Test-Path $testDirectory)) {
		write-host ">>> Preparing $testDirectory"
		$test_pack_link="https://windows.php.net/downloads/snaps/php-$branch/$revision/$test_pack.zip"
		$local_path = (join-path $env:PHP_CACHE "$test_pack.zip")

		Restore-PhpDownload -Uri $test_pack_link -LocalPath $local_path			
	}

	# Check to see if we have set the CLEANRESULTS
	# Environmental variable to true
	if ((Test-Path env:\CLEANRESULTS) -and
		($true -eq $env:CLEANRESULTS)) {
		
		if ((Test-Path $outputDirectory)) {
			write-host ">>> Cleaning $outputDirectory"
			remove-item -Path $outputDirectory -Recurse -Force
		}
	}

	if(!(Test-Path $outputDirectory)) {
		mkdir $outputDirectory
	}
	
}
process {
	# Save off original php.ini
	Copy-Item (Join-Path $buildDirectory "php.ini-development") (Join-Path $env:Build_ArtifactStagingDirectory "php.ini-development") -Force

	# Create php.ini w/o opcache
	write-host ">>> php.ini Processing"
	New-PhpIni -BuildDirectory $BuildDirectory
	Copy-Item (Join-Path $buildDirectory "php.ini") (Join-Path $env:Build_ArtifactStagingDirectory "php-noopcache.ini") -Force
	

	write-host ">>> Invoking Php Tests w/o opcache"
	$timeStart = get-date
	Invoke-PhpTests -BuildDirectory $buildDirectory -testDirectory $testDirectory -OutputDirectory $outputDirectory -opcache:$false
	$timeEnd = get-date

	write-host ">>> Without OpCache Started" $timeStart
	write-host ">>> Without OpCache Ended" $timeEnd

	# Create php.ini w/ opcache
	write-host ">>> php.ini Processing"
	New-PhpIni -BuildDirectory $BuildDirectory
	Merge-OpCacheSettings -IniFile (Join-Path $buildDirectory "php.ini") -cpu $cpu
	Copy-Item (Join-Path $buildDirectory "php.ini") (Join-Path $env:Build_ArtifactStagingDirectory "php-opcache.ini") -Force

	write-host ">>> Invoking Php Tests w/ opcache"
	$timeStart = get-date
	Invoke-PhpTests -BuildDirectory $buildDirectory -testDirectory $testDirectory -OutputDirectory $outputDirectory -opcache:$true
	$timeEnd = get-date

	write-host ">>> With OpCache Started" $timeStart
	write-host ">>> With OpCache Ended" $timeEnd

	$destinationDirectory = (join-path $env:Build_ArtifactStagingDirectory "output")
	if(Test-Path $destinationDirectory) {
		write-host ">>> Removing" $destinationDirectory
		Remove-Item $destinationDirectory -Recurse -Force
	}
	write-host ">>> Copying $outputDirectory to $destinationDirectory"
	Copy-item -Path $outputDirectory -Destination $destinationDirectory -Force -Recurse

}
end {
	# Let's make sure we're exiting with code 0
	# if we get to this point
	if ($true -eq $pause) {
		Pause
	}
	ExitWithCode -exitcode 0
}
