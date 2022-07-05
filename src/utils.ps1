<#
.SYNOPSIS
  Register a new alias
.DESCRIPTION
  It supports providing string statements, if a single string is provided, it will call `Set-Alias` directly, if a statement is provided, it will automatically construct a dynamic function with the name `<Name>AliasFunction` and then call `Set-Alias`, you can call `Set-Alias` with `Get-Command -CommandType Function -Name "*AliasFunction"` to see all the alias registered in this way.
.PARAMETER Name
  The alias name.
.PARAMETER Value
  The alias content, it can be a string or a statement.
.EXAMPLE
  Register-Alias hello "echo 'Hello World!'"
  Typing "hello" to output a string "Hello World!".
.EXAMPLE
  Register-Alias i "cd ~/Projects/$($args[0])"
  Recieve a parameter $args[0] from the command line, and then change the current directory to ~/Projects/$($args[0]).
.INPUTS
  None.
.OUTPUTS
  None.
.LINK
  https://github.com/aliuq/Register-Completion
#>
function Register-Alias {
  Param([string]$Name, [string]$Value)
  if (($Value -Split ' ').Count -le 1) {
     Set-Alias $Name $Value -scope global
  }
  else {
     $fullName = $Name + "AliasFunction"
     Set-Item "Function:\global:$fullName" -Value ([scriptblock]::Create($Value))
     Set-Alias $Name $fullName -scope global
  }
}

