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
    Set-EnvironmentVariable -VariableName PFTT_CACHE -VariableValue (Join-Path $env:PHP_BUILDS CACHE)
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