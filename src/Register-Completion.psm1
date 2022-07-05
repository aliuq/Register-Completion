if (Get-Module New-Completion) { return }

. $PSScriptRoot\Utils.ps1
. $PSScriptRoot\Completion.ps1

$exportModuleMemberParams = @{
  Function = @('New-Completion', 'Get-CompletionKeys', 'ConvertTo-Hash', 'Remove-Completion', 'Register-Alias')
  Variable = @('CacheAllCompletions', 'CacheCommands')
}
Export-ModuleMember @exportModuleMemberParams

