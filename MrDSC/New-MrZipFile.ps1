#Requires -Version 4.0
function New-MrZipFile {

    [CmdletBinding()]
    param (

        $Directory,
        $FileName

    )
    Add-Type -AssemblyName System.IO.Compression.FileSystem
    [System.IO.Compression.ZipFile]::CreateFromDirectory($Directory, $FileName, 'fastest', $true)
}