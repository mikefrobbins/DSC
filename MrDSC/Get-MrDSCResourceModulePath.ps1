#Requires -Version 4.0
function Get-MrDSCResourceModulePath {

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
