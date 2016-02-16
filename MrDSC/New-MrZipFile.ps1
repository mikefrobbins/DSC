#Requires -Version 4.0
function New-MrZipFile {

    [CmdletBinding()]
    param (
        [ValidateScript({
          if (Test-Path -Path $_ -PathType Container) {
            $True
          }
          else {
            Throw "'$_' is not a valid directory."
          }
        })]
        [string]$Directory,

        [ValidateScript({
          if (Test-Path -Path (Split-Path -Parent $_ -OutVariable Parent) -PathType Container) {
            if ((Resolve-Path -Path $Parent).Path -eq (Resolve-Path -Path $Directory).Path) {
                Throw "'$(Split-Path -Leaf $_)' cannot be placed in the '$Directory' folder because it's the folder being zipped."
            }
            $True
          }
          else {
            Throw "'$Parent' is not a valid directory."
          }
        })]
        [string]$FileName,

        [switch]$Force
    )

    $Directory = Resolve-Path -Path $Directory
    Write-Verbose -Message "Directory changed to the fully qualified path: '$Directory'"

    $FileName = Join-Path -Path (Resolve-Path -Path (Split-Path -Parent $FileName)) -ChildPath (Split-Path -Leaf $FileName)
    Write-Verbose -Message "FileName changed to the fully qualified path: '$FileName'"

    if ($PSBoundParameters.Force -and (Test-Path -Path $FileName)) {
        Write-Verbose -Message "Attempting to remove existing file '$FileName'"
        Remove-Item -Path $FileName -Force -Confirm:$false
    }

    Add-Type -AssemblyName System.IO.Compression.FileSystem
    [System.IO.Compression.ZipFile]::CreateFromDirectory($Directory, $FileName, 'fastest', $true)

}