function Search-PathAcrossDrives {
    param(
        [string]$Path
    )
    $drives = (Get-PSDrive -PSProvider FileSystem).Root

    foreach ($drive in $drives) {
        $fullPath = Join-Path -Path $drive -ChildPath $Path
        if (Test-Path $fullPath) {
            return $fullPath
        }
    }

    return ""
}

function New-D365ModelSymLinks
{
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory=$False)] [string] $RepoAosRootPath = (Split-Path -Path $PSScriptRoot -Parent)
    )

    $packagesLocalDirectory = Search-PathAcrossDrives -Path "AOSService\PackagesLocalDirectory"
    
    foreach($child in Get-ChildItem "$RepoAosRootPath\Metadata")
    {
        $name = $child.Name
        Write-Verbose     "Scanning: $name"

        $descriptorDir = "$($child.FullName)\Descriptor\*.xml" #Code
        $xRefDir = "$($child.FullName)\*.xref" #Precompiled model
        if((Test-Path $descriptorDir) -or (Test-Path $xRefDir))
        {
            Write-Verbose "Generating symbolic link for: $($child.BaseName)"
            New-Item -ItemType SymbolicLink -Target "$($child.FullName)" -Path "$packagesLocalDirectory\$name" -Force
        }
    }
}

function Remove-D365ModelSymLinks
{
    [CmdletBinding()]
    param()

    $packagesLocalDirectory = Search-PathAcrossDrives -Path "AOSService\PackagesLocalDirectory"
    $relatedPackage = Get-RelatedPackage -Verbose
    Write-Verbose "Related package(s) are: $relatedPackage"

    foreach($child in Get-ChildItem -Path $packagesLocalDirectory)
    {
        if($child.LinkType -eq "SymbolicLink")
        {
            # Only remove related packages from the system.
            if($relatedPackage -match $child.BaseName)
            {
                Write-Verbose "Removing previous symbolic link for: $($child.BaseName)"
                & cmd /c rmdir $child.FullName
            }
        }
    }
}

function Get-RelatedPackage
{
    [CmdletBinding()]
    param()

    $repositoryDirectory = Split-Path $PSScriptRoot -Parent
    $metaDataPath = "$($repositoryDirectory)\Metadata"
    Write-Verbose "Related metadata Path: $metaDataPath"
    
    return (Get-ChildItem -Path $metaDataPath -Directory)
}

.\Invoke-D365_Off.ps1
Remove-D365ModelSymLinks -Verbose
.\Invoke-D365_On.ps1
New-D365ModelSymLinks -Verbose