if (Get-Module New-Completion) { return }

. $PSScriptRoot\Completion.ps1

$exportModuleMemberParams = @{
  Function = @('New-Completion', 'Get-CompletionKeys', 'ConvertTo-Hash', 'Remove-Completion')
  Variable = @('CacheAllCompletions', 'CacheCommands')
}
Export-ModuleMember @exportModuleMemberParams

