# Register-Completion

![GitHub](https://img.shields.io/github/license/aliuq/Register-Completion)
![Github Action](https://img.shields.io/github/workflow/status/aliuq/Register-Completion/CI)
![powershellgallery downloads](https://img.shields.io/powershellgallery/dt/Register-Completion)
![powershellgallery version](https://img.shields.io/powershellgallery/v/Register-Completion?include_prereleases)

Easy to register tab completions with fixed data structures. Easy to customize.

> **Note**  
> Recommeded Powershell version 7.0.0 or higher.

[TOC]

## Installation

Install module

```Powershell
# Install
Install-Module Register-Completion -Scope CurrentUser
# Import
Import-Module Register-Completion
```

Open config file `$profile.ps1`

```Powershell
# Powershell 7.x
pwsh
notepad $profile

# Powershell 5.x
powershell
notepad $profile
```

Add in `$profile.ps1`

```Powershell
# profile.ps1
Import-Module Register-Completion

# Set Tab to menu complement and intellisense
Set-PSReadLineKeyHandler -Key "Tab" -Function MenuComplete
```

## Usage

### New-Completion

`New-Completion [[-Command] <String>] [[-HashList] <Object>] [-Force]`

+ `-Command`: Command name
+ `-HashList`: Allows basic type number、string、array、hashtable、object or nested types.
+ `-Force`: Force a replacement when a completion exists
+ `-Filter`: Custom filter and sort function
+ `-Where`: Custom filter function
+ `-Sort`: Custom sort function

`Register-Completion` is usually used for tab completion of cli commands, but it goes beyond that, there are two types of tab completions: known datas and dynamic datas.

For known datas, use `New-Completion` can easily to register a completion. just need to construct the correct data format, example using part of the `npm` command:

```Powershell
$npmCmds = "
  {
   'login': ['--registry', '--scope', '--auth-type', '--always-auth', '--help'],
   'cache': ['add', { 'clean': '--force', 'clear': '--force', 'rm': '--force' }, 'verify', '--help'],
   'config': [{ 'set': ['--global'] }, 'get', 'delete', { list: ['-l', '--json'] }, 'edit', '--help'],
   'init': ['--force', '--yes', '--scope', '--help', { '#tooltip': 'npm init <@scope> (same as ``npx <@scope>/create``) `nnpm init [<@scope>/]<name> (same as ``npx [<@scope>/]create-<name>``)' }],
   'install': ['--save-prod', '--save-dev', '--save-optional', '--save-exact', '--no-save', '--help'],
   'publish': ['--tag', { '--access': ['public', 'restricted'] }, '--dry-run', '--otp', '--help'],
   'run': ['--silent', '--help'],
   'uninstall': ['--save-prod', '--save-dev', '--save-optional', '--no-save', '--help'],
   'version': ['major', 'minor', 'patch', 'premajor', 'preminor', 'prepatch', 'prerelease', '--preid', 'from-git', '--help'],
   '--version': '',
   '--help': ''
  }
"
New-Completion npm $npmCmds
```

Then, restart the current pssession or open a new terminal, use `npm <Tab>` to complete the command. In the above example, there is a special key `#tooltip`, which is a reserved field, and it means that after starting `MenuComplete`, powershell will give a tooltip, by providing this key, we can know more about.

For dynamic data, we need to do some additional processing, continuing with the above field `$npmCmds`, using the `package.json` script as an example:

<details>
<summary>The code</summary>

```Powershell
Register-ArgumentCompleter -Native -CommandName npm -ScriptBlock {
   param($wordToComplete, $commandAst, $cursorPosition)
   [Console]::InputEncoding = [Console]::OutputEncoding = $OutputEncoding = [System.Text.Utf8Encoding]::new()
   # If provided input string data, and needed to edit it,
   # use `ConvertTo-Hash` to convert the string data to a hash table 
   $commands = ConvertTo-Hash $npmCmds
   # Remove the cache of the same completion key, because if exists, it will not be dynamic updated.
   Remove-Completion "npm.run"
   # Get package.json script content and append the script to the hashtable
   if (Test-Path "$pwd\package.json") {
      $scripts = (Get-Content "$pwd\package.json" | ConvertFrom-JSON).scripts
      if ($null -ne $scripts) {
         $scriptNames = $scripts | Get-Member -MemberType NoteProperty | Select-Object -ExpandProperty Name
         $scriptNames | ForEach-Object {
            # Add script name to the completion key, the script command to the completion tooltip
            $commands.run[$_] = @{ '#tooltip' = $scripts.$_ }
         }
      }
   }
   # According to the $wordToComplete、$commandAst、$commands, get the avaliable completion data
   # See more at https://github.com/aliuq/Register-Completion/blob/master/src/Completion.ps1#L303
   Get-CompletionKeys $wordToComplete $commandAst $commands | ForEach-Object {
      $key = $_.Key
      $value = $_.Value
      $tooltip = $key
      
      if ($value) {
         $value.GetEnumerator() | ForEach-Object {
            $lowerKey = $_.Key.ToString().ToLower()
            if ($lowerKey -eq '#tooltip') {
               $tooltip = $_.Value
            }
         }
      }
      
      [System.Management.Automation.CompletionResult]::new($key, $key, "ParameterValue", $tooltip)
   }
}
```

</details>

Then, enter a directory where the `package.json` file exists, use `npm run <Tab>` to complete the command. Except the script, we can also append dynamic dependencies to `npm uninstall <Tab>`, the code to implement it is not given here.

Other `HashList` types to see the below examples. `-Force` let us can force to replacement a exist command.

```Powershell
New-Completion nc 100
New-Completion nc "1001" -Force
New-Completion nc "hello world" -Force
New-Completion nc "[100]" -Force
New-Completion nc "[100,101]" -Force
New-Completion nc 'arg1','arg2','arg3' -Force
New-Completion nc '["arg1","arg2","arg3"]' -Force
New-Completion nc "[{arg: 'arg_1'}]" -Force
New-Completion nc "[{arg: {arg_1: 'arg_1_1'}}]" -Force
New-Completion nc "[{arg: {arg_1: {arg_1_1: ['arg_1_1_1', 'arg_1_1_2']}}}]" -Force
New-Completion nc "[100, 'hello', {arg1: 'arg1_1'}, ['arg2', 'arg3']]" -Force
New-Completion nc @{100 = ""; hello = ""; arg1 = @{arg1_1 = ""}; arg2 = ""; arg3 = ""} -Force
New-Completion nc @("arg1", "arg2") -Force
New-Completion nc @("arg1", @{arg2 = "arg2_1"; arg3 = @("arg3_1", "arg3_2")}) -Force
New-Completion nc @{100 = ""; hello = ""; arg1 = @{arg1_1 = ""}; arg2 = ""; arg3 = @("arg3_1", "arg3_2")} -Force
New-Completion nc "{a:1,b:2,c:['c1','c2',{c3:{c3_1:'c3_1_1',c3_2:['c3_2_1','c3_2_2']}}]}" -Force
New-Completion nc "{a:1,b:2,c:['c1','c2',{c3:{c3_1:'c3_1_1',c3_2:['c3_2_1','c3_2_2']}}]}" -filter {
   Param($Keys, $Word)
   $Keys | Where-Object { $_ -Like "*$Word*" } | Sort-Object -Descending
} -Force
```

### Register-Alias

`Register-Alias [[-Name] <String>] [[-Value] <String>]`

Provide bash-like experiences, [see more](https://github.com/aliuq/Register-Completion/blob/master/src/Utils.ps1#L23)

```Powershell
Register-Alias ll ls
Register-Alias la ls
Register-Alias swd "echo $pwd"
Register-Alias apps "cd ~/Projects"
Register-Alias i "cd ~/Projects/$($args[0])"
Register-Alias which Get-Command
```

## Global Variables

+ `$CacheAllCompletions`: Cached all you typed completions, e.g. `nc <Tab>`
+ `$CacheCommands`: Cached all commands and hashlists from `New-Completion`

## License

[MIT](.\LICENSE)
