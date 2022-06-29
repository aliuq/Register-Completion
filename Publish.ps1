<#
.SYNOPSIS
  Helper publish script
.DESCRIPTION
  Helper script to publish or reset commits to the remote repository.
#>

Param(
  [Parameter(Mandatory, Position=0)]
  [ValidateSet('release', 'reset', 'help')]
  [string]$Action,
  [switch]$Patch,
  [switch]$Minor,
  [switch]$Major,
  [switch]$Commit,
  [switch]$Tag
)

$dir = ".\src"
$currentVersion = (Test-ModuleManifest "$dir\Register-Completion.psd1").version

@{
  "PowerShell Version" = $PSVersionTable.PSVersion;
  "Module Version" = $currentVersion
} | % { new-object PSObject -Property $_} | Format-List

function Set-SemverVersion {
  param(
    [PSCustomObject]$version,
    [switch]$patch,
    [switch]$minor,
    [switch]$major
  )

  $ver = $version.ToString()

  if ($patch) {
    $p = $version.Build + 1
    $ver = [string]$version.Major + "." + [string]$version.Minor + "." + [string]$p
  }
  elseif ($minor) {
    $m = $version.Minor + 1
    $ver = [string]$version.Major + "." + [string]$m + ".0"
  }
  elseif ($major) {
    $m = $version.Major + 1
    $ver = [string]$m + ".0.0"
  }

  return $ver
}

if ($Action -eq 'help') {
  Write-Host "Helper script:"
  @{
    "1" = ".\Publish.ps1 release -Patch -Commit -Tag"
    "2" = ".\Publish.ps1 reset -Tag"
  } | % { new-object PSObject -Property $_} | Format-List
}
elseif ($Action -eq 'release') {
  if ($Patch) { $newVersion = Set-SemverVersion $currentVersion -patch }
  elseif ($Minor) { $newVersion = Set-SemverVersion $currentVersion -minor }
  elseif ($Major) { $newVersion = Set-SemverVersion $currentVersion -major }
  else { $newVersion = Read-Host "Input a new version(v$currentVersion)" }

  $confirm = Read-Host "Confirm to release v$($newVersion)(previous v$($currentVersion))?(y/n)" [Char]

  if ($confirm -eq 'y') {
    Update-ModuleManifest -Path "$dir\Register-Completion.psd1" -ModuleVersion $newVersion
    npx standard-changelog

    if ($Commit) {
      git add "$dir\Register-Completion.psd1" CHANGELOG.md
      git commit -m "Release v$newVersion"
    }
    if ($Tag) {
      git tag --annotate --message "v$newVersion" v$newVersion
    }
    $comfirmPush = Read-Host "Confirm to push?(y/n)" [Char]
    if ($comfirmPush -eq 'y') {
      if ($Commit) {
        git push
      }
      if ($Tag) {
        git push --tags
      }
    }
  }
}
elseif ($Action -eq 'reset') {
  $version = (Test-ModuleManifest "$dir\Register-Completion.psd1").version
  $comfirmPush = Read-Host "Are you sure reset the version($version)?(y/n)" [Char]
  if ($comfirmPush -eq 'y') {
    git reset --hard HEAD~1
    if ($Tag) {
      git tag -d "v$version"
    }
    $comfirmPushRemote = Read-Host "Are you sure reset the version($version) to remote?(y/n)" [Char]
    if ($comfirmPushRemote -eq 'y') {
      git push -f
      if ($Tag) {
        git push origin ":refs/tags/v$version"
      }
    }
  }
}
