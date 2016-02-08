#Requires -Version 4.0
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