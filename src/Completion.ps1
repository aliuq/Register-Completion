[hashtable]$CacheAllCompletions = [ordered]@{}
[hashtable]$CacheCommands = [ordered]@{}
$PSVersion = $PSVersionTable.PSVersion
$keywords = '#listitemtext', '#type','#tooltip'

class CacheCommandData {
  $Commands = $null
  [ScriptBlock]$Filter = $null
  [ScriptBlock]$Sort = $null
  [ScriptBlock]$Where = $null

  CacheCommandData ($c, [ScriptBlock]$f, [ScriptBlock]$s, [ScriptBlock]$w) {
    $this.Commands = $c
    $this.Filter = $f
    $this.Sort = $s
    $this.Where = $w
  }
}

<#
.SYNOPSIS
  Convert to hashtable format.
.DESCRIPTION
  Recursive conversion of data to hashtable format, by default, hashtable value is emtpy string, but if this hashtable key in `@('#listitemtext', '#type','#tooltip')`, it will be reserved, because it is used by the construct `System.Management.Automation.CompletionResult`
.PARAMETER InputObject
  Input data, support for basic data types
.EXAMPLE
  ConvertTo-Hash 'hello','world'
  # output: @{'hello' = ''; 'world' = ''}
  Convert array to hashtable format
.EXAMPLE
  ConvertTo-Hash 100
  # output: @{100 = ''}
  Convert number to hashtable format
.EXAMPLE
  ConvertTo-Hash '{arg1: "hello", arg2: "world"}'
  # output: @{arg1 = @{'hello' = ''}; arg2 = @{'world' = ''}}
  Convert object to hashtable format
.EXAMPLE
  ConvertTo-Hash '[{arg1: {"#tooltip": "arg1 tooltip"}, arg2: {"#tooltip": "arg2 tooltip"}}]'
  # output: @{arg1 = @{'#tooltip' = 'arg1 tooltip'}; arg2 = @{'#tooltip' = 'arg2 tooltip'}}
  Convert Javascript object to hashtable format width keywords
.INPUTS
  None.
.OUTPUTS
  System.Collections.Hashtable
.LINK
  https://github.com/aliuq/Register-Completion
#>
function ConvertTo-Hash {
  Param($InputObject)

  if (!$InputObject) {
    return ""
  }

  [hashtable]$hash = [ordered]@{}
  $inputType = $InputObject.getType()

  if ($inputType -eq [hashtable]) {
    $InputObject.Keys | ForEach-Object {
      if ($_.ToString().ToLower() -in $keywords) { $hash[$_] = $InputObject[$_] }
      else { $hash[$_] = ConvertTo-Hash $InputObject[$_] }
    }
  }
  elseif ($inputType -eq [Object[]]) {
    $InputObject | ForEach-Object { $hash += ConvertTo-Hash $_ }
  }
  elseif ($inputType -eq [System.Management.Automation.PSCustomObject]) {
    $InputObject.psobject.Properties | ForEach-Object {
      if ($_.Name.ToString().ToLower() -in $keywords) { $hash[$_.Name] = $_.Value }
      else { $hash[$_.Name] = ConvertTo-Hash $_.Value }
    }
  }
  else {
    try {
      if ($PSVersion -lt "7.0") {
        $json = ConvertFrom-Json -InputObject $InputObject
      }
      else {
        $json = ConvertFrom-Json -InputObject $InputObject -AsHashtable
      }
      $jsonType = $json.getType()
      if ($jsonType -in [hashtable],[Object[]],[System.Management.Automation.PSCustomObject]) {
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
  According to input datas, returns avaliable completion object keys.
.DESCRIPTION
  According to input word and data, return the corresponding command keys.
  it usually used in the cmdlet `Register-ArgumentCompleter`, when provide datasets, it will return the avaliable completion keys.
.PARAMETER Word
  The input word. From `$wordToComplete`
.PARAMETER Ast
  The input data. From `$commandAst`
.PARAMETER HashList
  The datasets, support basic data types.
.PARAMETER Filter
  The filter function. if provided, it will be used to filter and sort the completion object keys.
.PARAMETER Where
  The where function. if provided, it will be used to filter the completion object keys.
.PARAMETER Sort
  The sort function. if provided, it will be used to sort the completion object keys.
.EXAMPLE
  Get-CompletionKeys '' nc 'hello','world'
  # output: @(@{hello = ''}, @{world = ''})
  Returns object array
.INPUTS
  None.
.OUTPUTS
  Object[]
.LINK
  https://github.com/aliuq/Register-Completion
#>
function Get-CompletionKeys {
  Param(
    [string]$Word,
    $Ast,
    $HashList,
    [ScriptBlock]$Filter,
    [ScriptBlock]$Where,
    [ScriptBlock]$Sort
  )

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
        if ($null -ne $map) {
          $CacheAllCompletions[$prefix] = $map
        }
        else {
          $CacheAllCompletions[$prefix] = @{}
        }
      }
    }
  }

  # Convert HashtableEnumerator to Object[]
  $keyArrs = $CacheAllCompletions[$key].GetEnumerator() | ForEach-Object { $_ }

  if ($Filter -is [scriptblock]) {
    & $Filter $keyArrs $Word
  }
  else {
    if ($Where -is [scriptblock]) {
      $keyArrs = & $Where $keyArrs $Word
    }
    else {
      $keyArrs = $keyArrs | Where-Object { $_.Key -Like "*$Word*" }
    }
    if ($Word) {
      $keyArrs = $keyArrs | Sort-Object -Property `
        @{Expression = { $Word -And $_.Key.ToString().StartsWith($Word) }; Descending = $true }, `
        @{Expression = { $Word -And $_.Key.ToString().indexOf($Word) }; Descending = $false }
    }
    
    $keyArrs = $keyArrs | Sort-Object -Property `
      @{Expression = { $_.Key.ToString().StartsWith('-') }; Descending = $false }, `
      @{Expression = { $_.Key }; Descending = $false }

    if ($Sort -is [scriptblock]) {
      $keyArrs = & $Sort $keyArrs
    }
  }
  $keyArrs | Where-Object { $_.Key.ToString().ToLower() -notin $keywords }
}

<#
.SYNOPSIS
  Remove a completion.
.DESCRIPTION
  According to input command, remove the completion.
.PARAMETER Command
  The command name. use dot to separate the command name.
.EXAMPLE
  Remove-Completion nc
.EXAMPLE
  Remove-Completion 'nc.hello'
.INPUTS
  None.
.OUTPUTS
  None.
.LINK
  https://github.com/aliuq/Register-Completion
#>
function Remove-Completion {
  Param([string]$Command)

  if ($CacheCommands.ContainsKey($Command)) {
    $CacheCommands.Remove($Command)
  }
  if ($CacheCommands.ContainsKey("$Command--filter")) {
    $CacheCommands.Remove("$Command--filter")
  }
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
.PARAMETER Where
  The where function. if provided, it will be used to filter the completion object keys.
.PARAMETER Sort
  The sort function. if provided, it will be used to sort the completion object keys.
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
.LINK
  https://github.com/aliuq/Register-Completion
#>
function New-Completion {
  Param(
    [string]$Command,
    $HashList,
    [switch]$Force = $false,
    [ScriptBlock]$Filter,
    [ScriptBlock]$Sort,
    [ScriptBlock]$Where
  )

  if ($CacheCommands.ContainsKey($Command)) {
    if ($Force) {
      Remove-Completion $Command
    }
    else {
      return
    }
  }

  $CacheCommands.Add($Command, [CacheCommandData]::new($HashList, $Filter, $Sort, $Where))

  Register-ArgumentCompleter -Native -CommandName $Command -ScriptBlock {
    param($wordToComplete, $commandAst, $cursorPosition)
    [Console]::InputEncoding = [Console]::OutputEncoding = $OutputEncoding = [System.Text.Utf8Encoding]::new()

    $cmd = $commandAst.CommandElements[0].Value
    $data = $CacheCommands[$cmd]

    if ($data) {
      Get-CompletionKeys $wordToComplete $commandAst $data.Commands -Filter $data.Filter -Sort $data.Sort -Where $data.Where |
      ForEach-Object {
        $key = $_.Key
        $value = $_.Value
        $type = "ParameterValue"
        $listItemText = $key
        $tooltip = $key
        
        if ($value) {
          $value.GetEnumerator() | ForEach-Object {
            $lowerKey = $_.Key.ToString().ToLower()
            if ($lowerKey -eq '#tooltip') {
              $tooltip = $_.Value
            }
            elseif ($lowerKey -eq '#type') {
              $type = $_.Value
            }
            elseif ($lowerKey -eq '#listitemtext') {
              $listItemText = $_.Value
            }
          }
        }
        
        [System.Management.Automation.CompletionResult]::new($key, $listItemText, $type, $tooltip)
      }
    }
  }
}
