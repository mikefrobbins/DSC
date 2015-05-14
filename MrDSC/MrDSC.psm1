#Requires -Version 4.0
function Publish-MrMOFToSMB {

<#
.SYNOPSIS
    Publishes a DSC MOF configuration file to the pull server that's configured on a target node(s).
 
.DESCRIPTION
    Publish-MrMOFToSMB is an advanced PowerShell function that publishes one or more MOF configuration files
    to the an SMB DSC server by determining the ConfigurationID (GUID) that's configured on the target node along
    with the UNC path of the SMB pull server and creates the necessary checksum along with copying the MOF and
    checksum to the pull server.
 
.PARAMETER ConfigurationPath
    The folder path on the local computer that contains the mof configuration files.

.PARAMETER ComputerName
    The computer name of the target node that the DSC configuration is created for.
 
.EXAMPLE
     Publish-MrMOFToSMB -ConfigurationPath 'C:\MyMofFiles'

.EXAMPLE
     Publish-MrMOFToSMB -ConfigurationPath 'C:\MyMofFiles' -ComputerName 'Server01', 'Server02'

.EXAMPLE
     'Server01', 'Server02' | Publish-MrMOFToSMB -ConfigurationPath 'C:\MyMofFiles'

.EXAMPLE
     MyDscConfiguration -Param1 Value1 -Parm2 Value2 | Publish-MrMOFToSMB
 
.INPUTS
    String
 
.OUTPUTS
    None
 
.NOTES
    Author:  Mike F Robbins
    Website: http://mikefrobbins.com
    Twitter: @mikefrobbins
#>

    [CmdletBinding()]
    param (
        [Parameter(Mandatory,
                   ValueFromPipelineByPropertyName)]
        [ValidateScript({Test-Path -Path $_ -PathType Container})]
        [Alias('Directory')]
        [string]$ConfigurationPath,

        [Parameter(ValueFromPipeline,
                   ValueFromPipelineByPropertyName)]
        [Alias('BaseName')]
        [string[]]$ComputerName
    )

    BEGIN {
        if (-not($PSBoundParameters['ComputerName'])) {
            $ComputerName = (Get-ChildItem -Path $ConfigurationPath\*.mof).basename
        }
    }

    PROCESS {
        foreach ($Computer in $ComputerName) {

            try {
                Write-Verbose -Message "Retrieving LCM information from $Computer"
                $LCMConfig = Get-DscLocalConfigurationManager -CimSession $Computer -ErrorAction Stop
            }
            catch {
                Write-Error -Message "An error has occurred. Error details: $_.Exception.Message"
                continue
            }        
            
            $servermof = "$ConfigurationPath\$Computer.mof"

            if (-not(Get-ChildItem -Path $servermof -ErrorAction SilentlyContinue)) {
                Write-Error -Message "Unable to find MOF file for $Computer in location: $ConfigurationPath"
            } 
            elseif ($LCMConfig.RefreshMode -ne 'Pull') {
                Write-Error -Message "The LCM on $Computer is not configured for DSC pull mode."
            }
            elseif ($LCMConfig.DownloadManagerName -ne 'DscFileDownloadManager' -and $LCMConfig.ConfigurationDownloadManagers.ResourceId -notlike '`[ConfigurationRepositoryShare`]*') {
                Write-Error -Message "LCM on $Computer not configured to receive configuration from DSC SMB pull server"
            }
            elseif (-not($LCMConfig.ConfigurationID)) {
                Write-Error -Message "A ConfigurationID (GUID) has not been set in the LCM on $Computer"
            }
            else {
                if ($LCMConfig.ConfigurationDownloadManagers.SourcePath) {
                    $SMBPath = "$($LCMConfig.ConfigurationDownloadManagers.SourcePath)"
                }
                elseif ($LCMConfig.DownloadManagerCustomData.Value) {
                    $SMBPath = "$($LCMConfig.DownloadManagerCustomData.Value)"
                }

                Write-Verbose -Message "Creating DSCChecksum for $servermof"
                New-DSCCheckSum -ConfigurationPath $servermof -Force

                if (Test-Path -Path $SMBPath) {

                    $guidmof = Join-Path -Path $SMBPath -ChildPath "$($LCMConfig.ConfigurationID).mof"

                    try {
                        Write-Verbose -Message "Copying $servermof.checksum to $guidmof.checksum"
                        Copy-Item -Path "$servermof.checksum" -Destination "$guidmof.checksum" -ErrorAction Stop

                        Write-Verbose -Message "Copying $servermof to $guidmof"
                        Copy-Item -Path $servermof -Destination $guidmof -ErrorAction Stop
                    }
                    catch {
                        Write-Error -Message "An error has occurred. Error details: $_.Exception.Message"                    
                    }

                }
                else {
                    Write-Error -Message "Unable to connect to $SMBPath as specified in the LCM on $Computer for it's DSC pull server"
                }
            }
        }
    }
}

function Publish-MrDSCResourceToSMB {

<#
.SYNOPSIS
    Publishes the module(s) of the specified DSC Resource(s) an SMB based DSC pull server.
 
.DESCRIPTION
    Publish-MrDSCResourceToSMB is an advanced PowerShell function that publishes one or more DSC resource
    modules to the an SMB based DSC server pull server.
 
.PARAMETER Name
    The name of the DSC resource. This is not necessarily the same as the root module containing the DSC
    resource.

.PARAMETER SMBPath
    The UNC path of the SMB share used as the DSC pull server.
 
.EXAMPLE
     Publish-MrDSCResourceToSMB -Name xSMBShare -SMBPath \\Server01\Share
 
.INPUTS
    String
 
.OUTPUTS
    None
 
.NOTES
    Author:  Mike F Robbins
    Website: http://mikefrobbins.com
    Twitter: @mikefrobbins
#>

    [CmdletBinding()]
    param (

        [Parameter(Mandatory,
                   ValueFromPipeline)]
        [string[]]$Name,

        [Parameter(Mandatory)]
        [string]$SMBPath

    )

    PROCESS {

        foreach ($N in $Name) {

            $Guid = New-MrGuid
            $ResourceInfo = Get-MrDSCResourceModulePath -Name $N        

            New-MrZipFile -Directory "$($ResourceInfo.ModulePath)" -FileName "$($SMBPath)\$($ResourceInfo.Module)_$($ResourceInfo.ModuleVersion).zip"
            New-DSCCheckSum -ConfigurationPath "$($SMBPath)\$($ResourceInfo.Module)_$($ResourceInfo.ModuleVersion).zip" -OutPath "$SMBPath"

        }

    }

}

function New-MrZipFile {

    [CmdletBinding()]
    param (

        $Directory,
        $FileName

    )
    Add-Type -AssemblyName System.IO.Compression.FileSystem
    [System.IO.Compression.ZipFile]::CreateFromDirectory($Directory, $FileName, 'fastest', $true)
}

function Get-MrDSCResourceModulePath {

    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]
        [string[]]$Name
    )

    $DSCResouces = Get-DscResource -Name $Name
    
    foreach ($DSCResource in $DSCResouces) {

        $ModuleInfo = Get-Module -Name $DSCResource.Module -ListAvailable

        [pscustomobject]@{
            Name = $DSCResource.Name
            Module = $DSCResource.Module
            ModuleVersion = $ModuleInfo.Version
            ModulePath = $ModuleInfo.ModuleBase
        }
    }
}

function New-MrGuid {
    [Guid]::NewGuid()
}

function Invoke-MrDscConfiguration {

    [CmdletBinding()]
    param (
        [string]$ComputerName
    )

    $params = @{
        Namespace = 'root/Microsoft/Windows/DesiredStateConfiguration'
        ClassName = 'MSFT_DSCLocalConfigurationManager'
        MethodName = 'PerformRequiredConfigurationChecks'
        Arguments = @{
            Flags = [uint32]1
        }
    }
    Invoke-CimMethod -ComputerName $ComputerName @params
}

function Get-MrDscLogs {
    
    [CmdletBinding()]
    param (
        [string[]]$ComputerName,
        [int]$MaxEvents
    )

    Invoke-Command -ComputerName $ComputerName {
        Get-WinEvent –LogName 'Microsoft-Windows-Dsc/Operational' -MaxEvents $Using:MaxEvents |
        Select-Object -Property TimeCreated, Id, LevelDisplayName, Message
    } | Select-Object -Property TimeCreated, Id, LevelDisplayName, Message
}