#Requires -Version 4.0
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
