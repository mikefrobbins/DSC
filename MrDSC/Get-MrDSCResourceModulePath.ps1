#Requires -Version 4.0
function Get-MrDSCResourceModulePath {

<#
.SYNOPSIS
    Returns path and version information for the root module of the specified DSC resource.
 
.DESCRIPTION
    The Get-MrDSCResourceModulePath function returns the name, module name, module version,
    and module path for the root module of the specified DSC resource.
 
.PARAMETER Name
    DSC resource name.

.EXAMPLE
     Get-MrDSCResourceModulePath -Name Archive
 
.INPUTS
    None
 
.OUTPUTS
    PSCustomObject
 
.NOTES
    Author:  Mike F Robbins
    Website: http://mikefrobbins.com
    Twitter: @mikefrobbins
#>

    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]
        [string[]]$Name
    )

    $DSCResouces = Get-DscResource -Name $Name
    
    foreach ($DSCResource in $DSCResouces) {
        
        try {
            $ModuleInfo = Get-Module -Name $DSCResource.Module -ListAvailable -ErrorAction Stop
        }
        catch {
            Write-Warning -Message "The '$($DSCResource.Name)' DSCResource does not have a module specified. Error details: $_"
        }        

        [pscustomobject]@{
            Name = $DSCResource.Name
            Module = $DSCResource.Module
            ModuleVersion = $ModuleInfo.Version
            ModulePath = $ModuleInfo.ModuleBase
        }
    }
}
