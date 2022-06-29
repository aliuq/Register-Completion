# Register-Completion

Easy to register tab completions with fixed data structures. Easy to customize.

> **Note**  
> Recommeded Powershell version 7.0.0 or higher.

## Installation

```Powershell
# Install
Install-Module Register-Completion -Scope CurrentUser
# Import
Import-Module Register-Completion
```

## Usage

`New-Completion [[-Command] <String>] [[-HashList] <Object>] [-Force]`

+ Param `HashList`, allows basic type number、string、array、hashtable、object or nested types.
+ Param `-Force` to force a replacement when a completion exists

Run `Set-PSReadLineKeyHandler -Key "Tab" -Function MenuComplete` in current terminal, this will enable to see all avaliable tab completion keys.

Let us start the first completion, then press `nc <Tab>`

```Powershell
New-Completion nc 'arg1','arg2','arg3'
```

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
```

## Global Variables

+ `$CacheAllCompletions`: Cached all you typed completions, e.g. `nc <Tab>`
+ `$CacheCommands`: Cached all commands and hashlists from `New-Completion`

## License

[MIT](.\LICENSE)
