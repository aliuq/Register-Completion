[hashtable]$CacheAllCompletions = @{}
[hashtable]$CacheCommands = @{}
$PSVersion = $PSVersionTable.PSVersion

<#
.SYNOPSIS
  Convert to hashtable format.
.DESCRIPTION
  Recursive conversion of data to hashtable format. hashtable values will be converted to hashtable.
  e.g.
   @{arg1 = "arg1_1"} -> @{arg1 = @{arg1_1 = ""}}
.PARAMETER InputObject
  Input data, support for basic data types
.EXAMPLE
  ConvertTo-Hash "arg"
  Convert string to hashtable format
.EXAMPLE
  ConvertTo-Hash 100
  Convert number to hashtable format
.EXAMPLE
  ConvertTo-Hash "['hello','world']"
  Convert Javascript array to hashtable format
.EXAMPLE
  ConvertTo-Hash "[{arg: {arg_1: 'arg_1_1'}}]"
  Convert Javascript array object to hashtable format
.EXAMPLE
  ConvertTo-Hash "[{arg: {arg_1: {arg_1_1: ['arg_1_1_1', 'arg_1_1_2']}}}]"
  Convert Javascript nested array object to hashtable format
.EXAMPLE
  ConvertTo-Hash "[100, 'hello', {arg1: 'arg1_1'}, ['arg2', 'arg3']]"
  Convert Javascript array to hashtable format
.EXAMPLE
  ConvertTo-Hash @("arg1", "arg2")
  Convert array to hashtable format
.EXAMPLE
  ConvertTo-Hash @("arg1", @{arg2 = "arg2_1"; arg3 = @("arg3_1", "arg3_2")})
  Convert nested array to hashtable format
.INPUTS
  None.
.OUTPUTS
  System.Collections.Hashtable
#>
function ConvertTo-Hash {
  Param($InputObject)

  if (!$InputObject) {
    return ""
  }

  [hashtable]$hash = @{}
  $inputType = $InputObject.getType()

  if ($inputType -eq [hashtable]) {
    $InputObject.Keys | ForEach-Object { $hash[$_] = ConvertTo-Hash $InputObject[$_] }
  }
  elseif ($inputType -eq [Object[]]) {
    $InputObject | ForEach-Object { $hash += ConvertTo-Hash $_ }
  }
  elseif ($inputType -eq [System.Management.Automation.PSCustomObject]) {
    $InputObject.psobject.Properties |
    ForEach-Object { $hash[$_.Name] = ConvertTo-Hash $_.Value }
  }
  else {
    try {
      if ($PSVersion -lt "7.0") {
        $json = ConvertFrom-Json -InputObject $InputObject
      }
      else {
        $json = ConvertFrom-Json -InputObject $InputObject -AsHashtable
      }
      if ($json.getType() -in [hashtable],[Object[]],[System.Management.Automation.PSCustomObject]) {
        $hash = ConvertTo-Hash $json
      }
      else {
        $hash.Add($json, "")
      }
    }
    catch {
      $hash.Add($InputObject, "")
    }
  }
  return $hash
}

<#
.SYNOPSIS
  Get the completion keys.
.DESCRIPTION
  According to the input word and data, return the corresponding command keys.
  it usually used in the cmdlet `Register-ArgumentCompleter`, when provide datasets, it will return the right completion keys.
.PARAMETER Word
  The input word. From `$wordToComplete`
.PARAMETER Ast
  The input data. From `$commandAst`
.PARAMETER HashList
  The datasets, support basic data types.
.PARAMETER Filter
  The filter function. if provided, it will be used to filter the completion keys.
.EXAMPLE
  Get-CompletionKeys "" "case" "hello","world"
  Returns `hello` and `world`
.EXAMPLE
  Get-CompletionKeys "h" "case h" "hello","world"
  Returns `hello`
.EXAMPLE
  Get-CompletionKeys "" "case h" "hello","world"
  Returns None.
.INPUTS
  None.
.OUTPUTS
  System.Array
#>
function Get-CompletionKeys {
  Param([string]$Word, $Ast, $HashList, [ScriptBlock]$Filter)

  if (!$HashList) {
    return @()
  }

  $arr = $Ast.ToString().Split().ToLower() | Where-Object { $null -ne $_ }

  # Empty, need to return children completion keys
  if (!$Word) {
    [string]$key = ($arr -join ".").trim(".")
    $keyLevel = $arr
  }
  # Character, need to return sibling completion keys
  else {
    [string]$key = (($arr | Select-Object -SkipLast 1) -join ".").trim(".")
    $keyLevel = $key | ForEach-Object { $_.split(".") }
  }

  if (!$CacheAllCompletions.ContainsKey($key)) {
    $map = ConvertTo-Hash $HashList
    $prefix = ""
    $keyLevel | ForEach-Object {
      if ($prefix) {
        $map = $map[$_]
        $prefix = "$prefix.$($_)"
      }
      else {
        $prefix = $_
      }
      if (!$CacheAllCompletions.ContainsKey($prefix)) {
        $CacheAllCompletions[$prefix] = $map.Keys
      }
    }
  }

  if ($Filter -is [scriptblock]) {
    & $Filter $CacheAllCompletions[$key] $Word
  }
  else {
    $CacheAllCompletions[$key] |
    Where-Object { $_ -Like "*$Word*" } |
    Sort-Object -Property @{Expression = { $_.ToString().StartsWith($Word) }; Descending = $true },
                          @{Expression = { $_.ToString().indexOf($Word) }; Descending = $false },
                          @{Expression = { $_.ToString().StartsWith('-') }; Descending = $false },
                          @{Expression = { $_ }; Descending = $false }
  }
}

function Remove-Completion {
  Param([string]$Command)

  $CacheCommands.Remove($Command)
  $CacheCommands.Remove("$Command--filter")
  $CacheAllCompletions.Clone().Keys |
    Where-Object { $_.StartsWith("$Command.") -or ($_ -eq $Command) } |
    ForEach-Object { $CacheAllCompletions.Remove($_) }
}

<#
.SYNOPSIS
  Register a completion.
.DESCRIPTION
  Register a completion. provide the command name and the completion datasets. when type the command name, and press `Tab`, it will show the completion keys.
.PARAMETER Command
  The command name.
.PARAMETER HashList
  The datasets, support basic data types.
.PARAMETER Force
  Enable replaced the existing completion. default is false.
.PARAMETER Filter
  The filter function. if provided, it will be used to filter the completion keys.
  The function will be called with two parameters: $Keys and $Word, and the return value is the filtered and sorted keys.
.EXAMPLE
  New-Completion demo "hello","world"
  Register a completion with command name `demo` and datasets `hello`、`world`.
  Press `demo <Tab>` will get `demo hello`
.EXAMPLE
  New-Completion demo "100" -Force
  Replace the existing completion with command name `demo` and datasets `100`.
  Press `demo <Tab>` will get `demo 100`
.EXAMPLE
  $cmds = "{
    'access': ['public', { grant: ['read-only', 'read-write'] }, 'revoke', 'edit', '--help'],
    '--help': ''
  }"
  New-Completion nc $cmds -filter {
    Param($Keys, $Word)
    $Keys | Where-Object { $_ -Like "*$Word*" } | Sort-Object -Descending
  }
  Replace the default filter function, and will returns the filtered completion keys with provided fitler function.
.INPUTS
  None.
.OUTPUTS
  None.
#>
function New-Completion {
  Param(
    [string]$Command,
    $HashList,
    [switch]$Force = $false,
    [ScriptBlock]$Filter
  )

  if ($CacheCommands.ContainsKey($Command)) {
    if ($Force) {
      Remove-Completion $Command
    }
    else {
      return
    }
  }
  $CacheCommands.Add($Command, $HashList)
  $CacheCommands.Add("$Command--filter", $Filter)

  Register-ArgumentCompleter -Native -CommandName $Command -ScriptBlock {
    param($wordToComplete, $commandAst, $cursorPosition)
    [Console]::InputEncoding = [Console]::OutputEncoding = $OutputEncoding = [System.Text.Utf8Encoding]::new()

    $cmd = $commandAst.CommandElements[0].Value
    $cmdHashList = $CacheCommands[$cmd]
    $cmdFilter = $CacheCommands["$cmd--filter"]

    if ($null -ne $cmdHashList) {
      Get-CompletionKeys $wordToComplete $commandAst $cmdHashList $cmdFilter |
      ForEach-Object { [System.Management.Automation.CompletionResult]::new($_, $_, 'ParameterValue', $_) }
    }
  }
}

