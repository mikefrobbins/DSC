#Requires -Version 4.0
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
     Publish-MrDSCResourceToSMB -Name xSMBShare, xFirewall -SMBPath \\Server01\Share

.EXAMPLE
     'xSMBShare', 'xFirewall' | Publish-MrDSCResourceToSMB -SMBPath \\Server01\Share
 
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
        [ValidateScript({
            If (Get-DscResource -Name $_) {
                $True
            }
            else {
                Throw "$_ is not a valid DSC resource name or was not found on $env:COMPUTERNAME."
            }
        })]
        [string[]]$Name,

        [Parameter(Mandatory)]
        [ValidateScript({Test-Path -Path $_ -PathType Container})]
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