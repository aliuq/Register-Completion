Param(
  [ArgumentCompletions('release', 'release-patch', 'release-minor', 'release-major', 'rollback-local', 'rollback')]
  [string]$action
)
$dir = ".\src"
$current_version = (Test-ModuleManifest "$dir\Register-Completion.psd1").version

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

if ($action -in 'release','release-patch','release-minor','release-major') {
  switch ($action) {
    release { $new_version = Read-Host "Input a new version(v$current_version)" }
    release-patch { $new_version = Set-SemverVersion $current_version -patch }
    release-minor { $new_version = Set-SemverVersion $current_version -minor }
    release-major { $new_version = Set-SemverVersion $current_version -major }
  }

  $confirm = Read-Host "Confirm to release v$($new_version)(previous v$($current_version))?(y/n)" [Char]

  if ($confirm -eq 'y') {
    Update-ModuleManifest -Path "$dir\Register-Completion.psd1" -ModuleVersion $new_version
    npx standard-changelog

    git add "$dir\Register-Completion.psd1" CHANGELOG.md
    git commit -m "Release v$new_version"
    git tag --annotate --message "v$new_version" v$new_version

    $confirm_push = Read-Host "Confirm to push?(y/n)" [Char]
    if ($confirm_push -eq 'y') {
      git push
      git push --tags
    }
  }
}
elseif ($action -in 'rollback', 'rollback-local') {
  $version = (Test-ModuleManifest "$dir\Register-Completion.psd1").version
  git reset --hard HEAD~1
  git tag -d "v$version"
  if ($action -eq 'rollback') {
    git push origin ":refs/tags/v$version"
    git push -f
  }
}

