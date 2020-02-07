<#
.SYNOPSIS
  This is a simple Powershell script to explain how to create help
.DESCRIPTION
  The script itself will only print 'Hello World'. But that's cool. It's main objective is to show off the cool help thingy anyway.
.PARAMETER
  Description of the parameter.
.EXAMPLE
  ./HelloWorld.ps1
.NOTES
  Put some notes here.
.LINK
  http://www.microsoft.com
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
	[string]$thread
)
begin {

	<#
	.SYNOPSIS
	  This is a simple Powershell script to explain how to create help
	.DESCRIPTION
	  The script itself will only print 'Hello World'. But that's cool. It's main objective is to show off the cool help thingy anyway.
	.PARAMETER
	  Description of the parameter.
	.EXAMPLE
	  ./HelloWorld.ps1
	.NOTES
	  Put some notes here.
	.LINK
	  http://www.microsoft.com
	#>
	function Write-Utf8File {
		[CmdletBinding()]
		param (
			[string]$outFile,
			[string[]]$linesToWrite,
			[switch]$Append
		)
		
		begin {
			if (($true -eq $Append) -and (Test-Path $outFile)) {
				$outLines = get-content $outFile
				$outLines += $linesToWrite
			}
			else {
				$outLines = $linesToWrite
			}

			$Utf8NoBomEncoding = New-Object System.Text.UTF8Encoding $False
		}
		
		process {
			[System.IO.File]::WriteAllLines($outFile, $outLines, $Utf8NoBomEncoding)
		}
		
		end {
			
		}
	}

	<#
	.SYNOPSIS
	  This is a simple Powershell script to explain how to create help
	.DESCRIPTION
	  The script itself will only print 'Hello World'. But that's cool. It's main objective is to show off the cool help thingy anyway.
	.PARAMETER
	  Description of the parameter.
	.EXAMPLE
	  ./HelloWorld.ps1
	.NOTES
	  Put some notes here.
	.LINK
	  http://www.microsoft.com
	#>
	function Merge-OpCacheSettings {
		[CmdletBinding()]
		param (
			[Parameter(Mandatory)]
			[string]$IniFile,
			[Parameter(Mandatory)]
			[ValidateSet('x86','x64')]
			[string]$cpu
		)
		
		begin {
			$cpuIniFile = "$PSScriptRoot\..\Ini\$cpu-opcache.ini"
		}
		
		process {
			$phpIniContents = Get-Content $IniFile
			write-host ">>> Removing opcache from php.ini"
			$phpIniContents = $phpIniContents | ForEach-Object {
				if($_ -eq "[opcache]") {
					" "
					";Removing for testing purposes"
					";[opcache]"
				}
				else{
					$_
				}
			} 
			Write-Utf8File -outFile $IniFile -linesToWrite $phpIniContents
			write-host ">>> Using CPU Ini File: $cpuIniFile"
			Get-Content $cpuIniFile | Out-File -FilePath $IniFile -Append -Encoding utf8
		}
		
		end {
			
		}
	}

	<#
	.SYNOPSIS
	  This is a simple Powershell script to explain how to create help
	.DESCRIPTION
	  The script itself will only print 'Hello World'. But that's cool. It's main objective is to show off the cool help thingy anyway.
	.PARAMETER
	  Description of the parameter.
	.EXAMPLE
	  ./HelloWorld.ps1
	.NOTES
	  Put some notes here.
	.LINK
	  http://www.microsoft.com
	#>
	function Merge-Extensions {
		[CmdletBinding()]
		param (
			[string[]]$IniContents,
			[string]$buildDirectory,
			[switch]$opCache
		)
		
		begin {
			# From the tests to run file, get only the extensions we are going to run
			# and output them to the php.ini file
			$extensions = [System.Collections.ArrayList](get-content $PSScriptRoot\tests-to-run.txt | 
				Where-Object {$_ -like "ext\*" } |
				ForEach-Object {$_ -replace "ext\\", ";extension="})
			
			if ($false -eq $opCache) {
				write-host ">>> Removing opcache extension"
				$extensions.Remove(";extension=opcache")
			}

			$extensionsCopy = $extensions.Clone()
			$extensions | ForEach-Object {
				$originalLine = $_
				$dllName = Join-Path $buildDirectory ("ext\php_{0}.dll" -f ($originalLine -replace ";extension=",""))
				if(!(Test-Path $dllName)) {
					write-host ">>> Removing" $originalLine
					$extensionsCopy.Remove($originalLine)
				}
			}
			$extensions = $extensionsCopy
		}
		
		process {
			# Enable all extensions with existing lines.
			$iniContents = $iniContents | ForEach-Object {
				$line = $_
				if($extensions -contains $line) {
					write-host ">>> Enabling" $line
					$extensions.Remove($line)
					$line -replace ";",""
				}
				elseif ($line -eq ";extension_dir = ""ext""") {
					write-host ">>> Updating extension_dir setting:" (join-path $BuildDirectory "ext")
					("extension_dir=" + (join-path $BuildDirectory "ext")) 
				}
				else {
					$line
				}
			}
			
			# Add in all extensions that actually exist
			$iniContents = $iniContents | ForEach-Object {
				$line = $_
				if ($line -eq "[CLI Server]") {
					$extensions | ForEach-Object {
						$extline = $_
						write-host ">>> Adding extension:" ($extline -replace ";","")
						$extline -replace ";",""
					}
				}
				$line
			}

			# Return all corrected contents
			$IniContents
		}		
		end {
			
		}
	}

	<#
	.SYNOPSIS
	  This is a simple Powershell script to explain how to create help
	.DESCRIPTION
	  The script itself will only print 'Hello World'. But that's cool. It's main objective is to show off the cool help thingy anyway.
	.PARAMETER
	  Description of the parameter.
	.EXAMPLE
	  ./HelloWorld.ps1
	.NOTES
	  Put some notes here.
	.LINK
	  http://www.microsoft.com
	#>
	function New-PhpIni {
		[CmdletBinding()]
		param (
			[Parameter(Mandatory)]
			[string]$BuildDirectory
		)
		
		begin {
			$fromFile = (Join-Path $buildDirectory "php.ini-development")
			$toFile = (Join-Path $buildDirectory "php.ini")
		}
		
		process {
			if(Test-Path $fromFile) {
				write-host ">>> Copying $fromFile to $toFile"
				$iniContents = Get-Content $fromFile

				$iniContents = Merge-Extensions -IniContents $iniContents -buildDirectory $BuildDirectory
				Write-Utf8File -outFile $toFile -linesToWrite $iniContents
			}
			else {
				Write-error ">>> $fromFile does not exist!"
			}
		}
		
		end {
			
		}
	}

	<#
	.SYNOPSIS
	  This is a simple Powershell script to explain how to create help
	.DESCRIPTION
	  The script itself will only print 'Hello World'. But that's cool. It's main objective is to show off the cool help thingy anyway.
	.PARAMETER
	  Description of the parameter.
	.EXAMPLE
	  ./HelloWorld.ps1
	.NOTES
	  Put some notes here.
	.LINK
	  http://www.microsoft.com
	#>
	function Invoke-PhpTests {
		[CmdletBinding()]
		param (
			$BuildDirectory,
			$TestDirectory,
			$OutputDirectory,
			[switch]$opCache
		)
		
		begin {
			push-location $BuildDirectory
		}
		
		process {
			$phpExe = join-path $BuildDirectory "php.exe"
			$runTestFile = join-path $testDirectory "run-test.php"
			$opCacheString = ""
			if($true -eq $opCache) {$opCacheString = "-opcache"}

			# Read the input and queue it up
			$directoriesToParse = get-content $PSScriptRoot\tests-to-run.txt

			$directoriesToParse  | ForEach-Object {
				$testsToRunDirectory = join-path $testDirectory $_
				write-host ">>> Checking" $testsToRunDirectory
				$htmlFile = ("{0}{1}.html" -f ($_ -replace "\\", "_"),$opCacheString)
				$outputHtmlFile = join-path $OutputDirectory $htmlFile

				if (!(Test-Path $outputHtmlFile)) {
					write-host ">>> Running:" $phpExe $runTestFile --html $outputHtmlFile $testsToRunDirectory
					&$phpExe $runTestFile --html $outputHtmlFile $testsToRunDirectory
				}
			}
		}
		
		end {
			Pop-Location
		}
	}

	<#
	.SYNOPSIS
	  This is a simple Powershell script to explain how to create help
	.DESCRIPTION
	  The script itself will only print 'Hello World'. But that's cool. It's main objective is to show off the cool help thingy anyway.
	.PARAMETER
	  Description of the parameter.
	.EXAMPLE
	  ./HelloWorld.ps1
	.NOTES
	  Put some notes here.
	.LINK
	  http://www.microsoft.com
	#>
	function Restore-PhpDownload {
		[CmdletBinding()]
		param (
			[Parameter(Mandatory)]
			[string]$Uri,
			[Parameter(Mandatory)]
			[string]$LocalPath,
			[string]$UnzipPath="$env:PHP_BUILDS\*"
		)
		
		begin {
			if (Test-Path $LocalPath) {
				Remove-Item $LocalPath -Force
			}
		}
		
		process {
			write-host ">>> Downloading" $Uri
			Get-FileFromUrl $Uri $LocalPath
			write-host ">>> Unzipping" $LocalPath
			7za.exe x $LocalPath "-o$UnzipPath"
			Remove-Item $LocalPath				
		}
		
		end {
			
		}
	}

	# Set Environmental variables
	Import-Module $PSScriptRoot\Util.ps1 -Force

	Set-PHPEnvironmentVariables

	# Get version information
	$SNAP_JSON="php-$branch.json"
	$SNAP_JSON_URL="https://windows.php.net/downloads/snaps/php-$branch/$SNAP_JSON"

	$snapJson = Get-StringFromUrl $SNAP_JSON_URL | ConvertFrom-Json

	# Common Variables
	$build="vc15"
	$buildNeeded = "$thread-windows-$build-$cpu"

	$revision = "r$($snapJson.revision_last_exported)"

	$test_pack="php-test-pack-$branch-$thread-windows-$build-$cpu-$revision"
	$build_pack="php-$branch-$thread-windows-$build-$cpu-$revision"

	$buildDirectory = Join-Path $env:PHP_BUILDS $build_pack
	$testDirectory = Join-Path $env:PHP_BUILDS $test_pack
	$outputDirectory = Join-Path $testDirectory "output"

	Write-host ">>> Current Build Pack: $build_pack"
	Write-Host ">>> Current Test Pack: $test_pack"
	if ($snapJson.builds -notcontains $buildNeeded) {
		write-error ">>> Build $buildNeeded not found"
		exit
	}

	# Download version and test pack if not unzipped already
	if(!(Test-Path $env:PHP_BUILDS)) {
		write-host ">>> Creating" $env:PHP_BUILDS
		mkdir $env:PHP_BUILDS
	}

	if(!(Test-Path $env:PFTT_CACHE)) {
		write-host ">>> Creating" $env:PFTT_CACHE
		mkdir $env:PFTT_CACHE
	}

	if (!(Test-Path $buildDirectory)) {
		write-host ">>> Preparing $buildDirectory" 
		$build_link="https://windows.php.net/downloads/snaps/php-$branch/$revision/$build_pack.zip"
		$local_path = (join-path $env:PFTT_CACHE "$build_pack.zip")

		Restore-PhpDownload -Uri $build_link -LocalPath $local_path			
	}

	if (!(Test-Path $testDirectory)) {
		write-host ">>> Preparing $testDirectory"
		$test_pack_link="https://windows.php.net/downloads/snaps/php-$branch/$revision/$test_pack.zip"
		$local_path = (join-path $env:PFTT_CACHE "$test_pack.zip")

		Restore-PhpDownload -Uri $test_pack_link -LocalPath $local_path			
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

	return 0
}
end {
}
