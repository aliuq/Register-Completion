if (!$cache_all_completion) {
  [hashtable]$cache_all_completion = [ordered]@{}
}
[hashtable]$cache_command_list = @{}

function Convert-JsonToHash {
  Param([string]$json)
  try {
    ConvertFrom-Json -InputObject $json -AsHashtable
  }
  catch {
    $json
  }
}

function Get-CompletionKeys {
  # hashtable or array
  Param($word, $ast, $hash_list)

  if (!$hash_list) {
    return @()
  }

  if ($hash_list.getType -And ($hash_list.getType() -eq [string])) {
    $hash_list = Convert-JsonToHash $hash_list
  }

  $arr = $ast.ToString().Split().ToLower() | Where-Object { $_ -ne $null }

  # Empty, need to return children completion keys
  if (!$word) {
    [string]$key = ($arr -join ".").trim(".")
    $key_level = $arr
  }
  # Character, need to return sibling completion keys
  else {
    [string]$key = (($arr | Select-Object -SkipLast 1) -join ".").trim(".")
    $key_level = $key | ForEach-Object { $_.split(".") }
  }

  if (!$cache_all_completion.ContainsKey($key)) {
    $map = $hash_list
    $prefix = ""
    $key_level | ForEach-Object {
      if ($prefix) {
        $map = $map[$_]
        $prefix = $prefix + "." + $_
      }
      else {
        $prefix = $_
      }
      if (!$cache_all_completion.ContainsKey($prefix)) {
        if ($map.Keys) {
          $cache_all_completion[$prefix] = $map.Keys
        }
        else {
          $cache_all_completion[$prefix] = $map
        }
      }
    }
  }

  $cache_all_completion[$key] |
  Where-Object { $_ -Like "*$word*" } |
  Sort-Object -Property @{Expression = { $_.ToString().StartsWith($wordToComplete) }; Descending = $true }, @{Expression = { $_.ToString().indexOf($wordToComplete) }; Descending = $false }, @{Expression = { $_ }; Descending = $false }
}

function Register-Completion {
  Param($command, $hash_list)
  $cache_command_list.add($command, $hash_list)

  Register-ArgumentCompleter -Native -CommandName $command -ScriptBlock {
    param($wordToComplete, $commandAst, $cursorPosition)
    [Console]::InputEncoding = [Console]::OutputEncoding = $OutputEncoding = [System.Text.Utf8Encoding]::new()

    $cmd = $commandAst.CommandElements[0].Value
    $hash_list = $cache_command_list[$cmd]

    if ($null -ne $hash_list) {
      Get-CompletionKeys $wordToComplete $commandAst $hash_list |
      ForEach-Object { [System.Management.Automation.CompletionResult]::new($_, $_, 'ParameterValue', $_) }
    }
  }
}

