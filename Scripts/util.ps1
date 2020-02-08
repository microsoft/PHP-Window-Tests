<#
.SYNOPSIS
  Set Environmental variable to given value.
.DESCRIPTION
  The script will overwrite the environmental variable if it exists.  Otherwise, it will create a new environmental variable.
.PARAMETER VariableName
  Name of the environmental variable. Mandatory.
.PARAMETER VariableValue
  Value of the environmental variable. Mandatory.
.EXAMPLE
  Set-EnvironmentVariable -VariableName PHP_BUILDS -VariableValue "c:\phpbuilds"
#>
function Set-EnvironmentVariable {
    [CmdletBinding(SupportsShouldProcess= $true)]
    param (
        [Parameter(Mandatory)]
        $VariableName,
        [Parameter(Mandatory)]
        $VariableValue
    )
    
    begin {
        $envPath = join-path env:\ $VariableName
    }
    
    process {
        if (Test-Path $envPath) {
            if ($PSCmdlet.ShouldProcess($VariableName, "Create Environment Variable")) {
                Set-item -Path $envPath -Value $VariableValue
            }
        }
        else {
            if ($PSCmdlet.ShouldProcess($VariableName, "Set Environment Variable")) {
                New-item -Path $envPath -Value $VariableValue
            }
        }
    }
    
    end {
        
    }
}

<#
.SYNOPSIS
  This sets all needed environmental variables for testing.
.DESCRIPTION
  The script will set a variety of environmental variables needed for testing purposes.
.EXAMPLE
  Set-PHPEnvironmentVariables
#>
function Set-PHPEnvironmentVariables () {
    Set-EnvironmentVariable -VariableName PHP_BUILDS -VariableValue (join-path $env:SystemDrive "PHPBuilds")
    Set-EnvironmentVariable -VariableName PHP_CACHE -VariableValue (Join-Path $env:PHP_BUILDS CACHE)
}

<#
.SYNOPSIS
  Gets the contents of a given url as a string.
.DESCRIPTION
  The script will download the contents of a url and return it as a string.
.PARAMETER url
  URL of content needed to download.  Mandatory.
.EXAMPLE
  Get-StringFromUrl -url https://windows.php.net/downloads/snap/php-7.4/php-7.4.json
.NOTES
  This sets [System.Net.ServicePointManager]::SecurityProtocol to handle secure url's.
#>
function Get-StringFromUrl() {
    param(
        [Parameter(Mandatory)]
        $url
    )
    [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.SecurityProtocolType]'Tls,Tls11,Tls12'	
    $wc = New-Object System.Net.WebClient
    $wc.Headers.Add("user-agent", "Mozilla/4.0 (compatible; MSIE 6.0; Windows NT 5.2; .NET CLR 1.0.3705;)")
    $wc.DownloadString($url)	
}

<#
.SYNOPSIS
  Gets the contents of a given url as a local file.
.DESCRIPTION
  The script will download the contents of a url and save it to a local path.
.PARAMETER url
  URL of content needed to download.  Mandatory.
.PARAMETER outFile
  The local file path to save contents to.  Mandatory.
.EXAMPLE
  Get-FileFromUrl -url https://windows.php.net/downloads/snap/php-7.4/php-7.4.json -outFile c:\downloads\php.json
.NOTES
  This sets [System.Net.ServicePointManager]::SecurityProtocol to handle secure url's.
#>
function Get-FileFromUrl() {
    param(
        [Parameter(Mandatory)]
        $url,
        [Parameter(Mandatory)]
        $outFile
    )
    [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.SecurityProtocolType]'Tls,Tls11,Tls12'	
    $wc = New-Object System.Net.WebClient
    $wc.Headers.Add("user-agent", "Mozilla/4.0 (compatible; MSIE 6.0; Windows NT 5.2; .NET CLR 1.0.3705;)")
    $wc.DownloadFile($url, $outFile)	
}

<#
.SYNOPSIS
  Exits Powershell with specific code.
.DESCRIPTION
  Sets the specified exit code and then exits Powershell.
.PARAMETER exitcode
  The exit code you want.  You need to know why you're using this.
.EXAMPLE
  ExitWithCode -exitcode 0
.NOTES
  If you run this in a Powershell window, it will close the window.
#>
function ExitWithCode{
    param(
      [Parameter(Mandatory)]
      $exitcode
    )

    $host.SetShouldExit($exitcode)
    exit
}

<#
.SYNOPSIS
  Restores a download from a url to a local directory
.DESCRIPTION
  This will download a given link to a local path, then uses 7za to unzip the file.
.PARAMETER Uri
  URI of the zip file to download.  Mandatory.
.PARAMETER LocalPath
  Local path of the zip file to save to. Mandatory.
.PARAMETER UnzipPath
  Local path where the zip file needs to be unzipped.  Should be of the form "<path>\*".  You need to precreate <path> as 7za will not create it.
.EXAMPLE
  Restore-PhpDownload -Uri $build_link -LocalPath $local_path
.NOTES
  7za needs to be in the bin directory.
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
    &"$PSScriptRoot\..\bin\7za.exe" x $LocalPath "-o$UnzipPath"
    Remove-Item $LocalPath				
  }
  
  end {
    
  }
}


<#
.SYNOPSIS
  Runs PHP Tests
.DESCRIPTION
  The function will generate the list of tests needed to be run, run them, and place all files in the output directory.
  It won't run if the html file in the output directory already exists.
.PARAMETER BuildDirectory
  The location of php.exe and php.ini.
.PARAMETER TestDirectory
  Directory where run-tests.php and all tests have been downloaded to.
.PARAMETER OutputDirectory
  Directory where output goes.
.PARAMETER opCache
  Switch to say whether opcache needs to be enabled.
.EXAMPLE
  # Runs tests with opcache disabled
  Invoke-PhpTests -BuildDirectory $buildDirectory -testDirectory $testDirectory -OutputDirectory $outputDirectory
.EXAMPLE
  # Runs tests with opcache enabled
	Invoke-PhpTests -BuildDirectory $buildDirectory -testDirectory $testDirectory -OutputDirectory $outputDirectory -opcache
.NOTES
  Put some notes here.
.LINK
  http://www.microsoft.com
#>
function Invoke-PhpTests {
  [CmdletBinding()]
  param (
    [string]$BuildDirectory,
    [string]$TestDirectory,
    [string]$OutputDirectory,
    [switch]$opCache
  )
  
  begin {
    push-location $testDirectory

    $phpExe = join-path $BuildDirectory "php.exe"
    $runTestFile = join-path $testDirectory "run-test.php"
    $opCacheString = ""
    if($true -eq $opCache) {$opCacheString = "-opcache"}

    # Read the input and queue it up
    $directoriesToParse = get-content $PSScriptRoot\tests-to-run.txt

    $allOutputFile = join-path $OutputDirectory "tests$opCacheString.log" 
    $failedTestsFile = join-path $OutputDirectory "tests$opCacheString-failed.log"
    $outputHtmlFile = join-path $OutputDirectory "tests$opCacheString.html"
    $allTestsToRunFile = join-path $OutputDirectory "TestsToRun$opCacheString.txt"

  }
  
  process {
    $allTestsToRun = $directoriesToParse  | ForEach-Object {
      $testsToRunDirectory = $_
      write-host "Getting items from" $testsToRunDirectory
      Get-ChildItem -Path $testsToRunDirectory -Recurse -Filter *.phpt
    }

    write-host ">>> Writing out tests to run to $allTestsToRunFile"
    $allTestsToRun | ForEach-Object {$_.fullname } | Sort-Object | Out-File -LiteralPath $allTestsToRunFile -Force -Encoding ascii

    if (!(Test-Path $outputHtmlFile)) {
      write-host ">>> Running:" $phpExe $runTestFile --html $outputHtmlFile "-w" $failedTestsFile "-W" $allOutputFile "-r" $allTestsToRunFile
      &$phpExe $runTestFile --html $outputHtmlFile  -w $failedTestsFile -W $allOutputFile -r $allTestsToRunFile
    }
  }		
  end {
    Pop-Location
  }
}

<#
.SYNOPSIS
  Creates a php.ini file.
.DESCRIPTION
  This copies the php.ini-development over to php.ini, and then takes care of extensions that we need enabled for the various tests.
.PARAMETER BuildDirectory
  Directory where php.exe and php.ini-development are living. Mandatory.
.EXAMPLE
  New-PhpIni -BuildDirectory $BuildDirectory
.NOTES
  Does not manage opcache settings.
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
  Writes a file out in UTF-8 encoding
.DESCRIPTION
  The script itself will only print 'Hello World'. But that's cool. It's main objective is to show off the cool help thingy anyway.
.PARAMETER outFile
  Local path to output to.  We will overwrite.
.PARAMETER linesToWrite
  The data to write to outFile.
.PARAMETER Append
  Append instead of overwrite.  We get the existing contents and add the new lines in.
.EXAMPLE
  Write-Utf8File -outFile $IniFile -linesToWrite $phpIniContents
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
  Merges opcache settings into php.ini
.DESCRIPTION
  The script itself will only print 'Hello World'. But that's cool. It's main objective is to show off the cool help thingy anyway.
.PARAMETER IniFile
  Full path to the php.ini file to add to. Mandatory.
.PARAMETER cpu
  CPU type to use. x86 and x64 are supported. Mandatory.
.EXAMPLE
  Merge-OpCacheSettings -IniFile (Join-Path $buildDirectory "php.ini") -cpu $cpu
.NOTES
  The opcache settings are decided based on cpu, and located in the ini folder.
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
  Merge extension settings into ini contents.
.DESCRIPTION
  We turn on all extensions that we test on in the php.ini contents given.
.PARAMETER IniContents
  Php.ini contents.  We will change them in memory and send them back.
.PARAMETER buildDirectory
  Location of php.exe and the extensions (ext/) directory.
.PARAMETER opCache
  Switch to turn on opcache extensions explicitly.
.EXAMPLE
  Merge-Extensions -IniContents $iniContents -buildDirectory $BuildDirectory
.NOTES
  Depends on $PSScriptRoot\tests-to-run.txt
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
