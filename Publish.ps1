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
  [switch]$Tag,
  [switch]$Beta
)

$dir = ".\src"
$currentVersion = (Test-ModuleManifest "$dir\Register-Completion.psd1").version

@{
  "PowerShell Version" = $PSVersionTable.PSVersion;
  "Module Version" = $currentVersion
} | ForEach-Object { new-object PSObject -Property $_} | Format-List

function Get-BetaVersion {
  $prerelease = (Test-ModuleManifest "$dir\Register-Completion.psd1").PrivateData.PSData.Prerelease
  if ($prerelease) {
    $betaVersion = $prerelease.Substring(4)
  }
  else {
    $betaVersion = 0
  }
  return [Int32]$betaVersion
}
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
  } | ForEach-Object { new-object PSObject -Property $_} | Format-List
}
elseif ($Action -eq 'release') {

  $betaVersionNum = Get-BetaVersion

  if (($Beta -And ($betaVersionNum -eq 0)) -Or !$Beta) {
    if ($Patch) { $newVersion = Set-SemverVersion $currentVersion -patch }
    elseif ($Minor) { $newVersion = Set-SemverVersion $currentVersion -minor }
    elseif ($Major) { $newVersion = Set-SemverVersion $currentVersion -major }
    else { $newVersion = Read-Host "Input a new version(v$currentVersion)" }
  }
  else {
    $newVersion = $currentVersion
  }

  if ($Beta) {
    $betaVersion = "beta$($betaVersionNum + 1)"
    $fullVersion =  "$newVersion-$betaVersion"
  }
  else {
    $fullVersion = $newVersion
  }
  Write-Host "You are about to release a version($fullVersion)`n" -ForegroundColor Yellow

  $confirm = Read-Host "Confirm to release v$($fullVersion)(previous v$($currentVersion))?(y/n)" [Char]

  if ($confirm -eq 'y') {
    if ($Beta) {
      Update-ModuleManifest -Path "$dir\Register-Completion.psd1" -ModuleVersion $newVersion -Prerelease $betaVersion
    }
    else {
      $d = "$dir\Register-Completion.psd1"
      (Get-Content $d -Raw) -Replace "Prerelease = 'beta\d+'", "# Prerelease = ''" | Set-Content $d
      Update-ModuleManifest -Path "$dir\Register-Completion.psd1" -ModuleVersion $newVersion
    }

    npx standard-changelog

    if ($Commit) {
      git add "$dir\Register-Completion.psd1" CHANGELOG.md
      git commit -m "Release v$fullVersion"
    }
    if ($Tag) {
      git tag --annotate --message "v$fullVersion" v$fullVersion
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
  $betaVersionNum = Get-BetaVersion
  if ($Beta) {
    $betaVersion = "beta$($betaVersionNum + 1)"
    $fullVersion =  "$version-$betaVersion"
  }
  else {
    $fullVersion = $version
  }
  $comfirmPush = Read-Host "Are you sure reset the version($fullVersion)?(y/n)" [Char]
  if ($comfirmPush -eq 'y') {
    git reset --hard HEAD~1
    if ($Tag) {
      git tag -d "v$fullVersion"
    }
    $comfirmPushRemote = Read-Host "Are you sure reset the version($fullVersion) to remote?(y/n)" [Char]
    if ($comfirmPushRemote -eq 'y') {
      git push -f
      if ($Tag) {
        git push origin ":refs/tags/v$fullVersion"
      }
    }
  }
}
