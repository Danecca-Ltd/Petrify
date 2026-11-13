<#
.SYNOPSIS
    Set the release version everywhere it lives, e.g.  .\bump_version.ps1 2.0.1

.DESCRIPTION
    Petrify.bundle:     PackageContents.xml (x2), Contents\Petrify.manifest, PETRIFY_VERSION
    Shrinkwrap.bundle:  the same three, and SHRINKWRAP_VERSION in the migration stub. Installs
                        from before the rename refuse an update whose SHRINKWRAP_VERSION differs
                        from the release tag, so the stub must always match.
    README.md:          the "Version X.Y.Z." line
    Also copies Petrify.bundle\Contents\petrify_updater.py into the stub as
    shrinkwrap_migration_updater.py, so the stub installs Petrify with current code.

    Then: commit, tag vX.Y.Z, push the commit and the tag.
#>
param([Parameter(Mandatory = $true)][ValidatePattern('^\d+\.\d+\.\d+$')][string]$Version)

$ErrorActionPreference = 'Stop'
$root = $PSScriptRoot
$utf8 = New-Object System.Text.UTF8Encoding $false

function Set-Version([string]$RelPath, [string[]]$Patterns) {
    $path = Join-Path $root $RelPath
    $text = [IO.File]::ReadAllText($path)
    foreach ($pattern in $Patterns) {
        $new = [regex]::Replace($text, $pattern, { param($m) $m.Groups[1].Value + $Version + $m.Groups[2].Value })
        if ($new -eq $text -and -not [regex]::IsMatch($text, $pattern)) { throw "Pattern not found in ${RelPath}: $pattern" }
        $text = $new
    }
    [IO.File]::WriteAllText($path, $text, $utf8)
    Write-Host "  $RelPath"
}

$xml  = @('(AppVersion=")\d+\.\d+\.\d+(")', '(<ComponentEntry [^>]*?Version=")\d+\.\d+\.\d+(")')
$json = @('("version":\s*")\d+\.\d+\.\d+(")')

Write-Host "Setting version $Version in:"
Set-Version 'Petrify.bundle\PackageContents.xml' $xml
Set-Version 'Petrify.bundle\Contents\Petrify.manifest' $json
Set-Version 'Petrify.bundle\Contents\Petrify.py' @("(?m)(^PETRIFY_VERSION = ')\d+\.\d+\.\d+(')")
Set-Version 'Shrinkwrap.bundle\PackageContents.xml' $xml
Set-Version 'Shrinkwrap.bundle\Contents\Shrinkwrap.manifest' $json
Set-Version 'Shrinkwrap.bundle\Contents\Shrinkwrap.py' @("(?m)(^SHRINKWRAP_VERSION = ')\d+\.\d+\.\d+(')")
Set-Version 'README.md' @('(Version )\d+\.\d+\.\d+(\.)')

Copy-Item (Join-Path $root 'Petrify.bundle\Contents\petrify_updater.py') `
          (Join-Path $root 'Shrinkwrap.bundle\Contents\shrinkwrap_migration_updater.py') -Force
Write-Host "  Shrinkwrap.bundle\Contents\shrinkwrap_migration_updater.py (copied from petrify_updater.py)"

Write-Host ""
Write-Host "Next: commit, then  git tag v$Version; git push origin master; git push origin v$Version"
