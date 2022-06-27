# Register-Completion

Easy to register tab completions with data structures. Easy to customize.

> **Note**
>
> Recommeded Powershell version 7.0.0 or higher.

## Install

```Powershell
Install-Module Register-Completion -Scope CurrentUser
```

## Simple Usage

In your terminal, type the below command to trying the completion.

First, import module

```Powershell
Import-Module Register-Completion
```

Second, register the completion

```Powershell
Register-Completion demo 'arg1','arg2','arg3'
```

Third, typing `demo ⇥` to see the completion, you will see the result `demo arg1`, the completions's first option.

## Full Usage

Use `-Force` to force a replacement when a completion exists

```Powershell
Register-Completion rc_number 100
# type `rc_number ⇥` will get 1001
Register-Completion rc_number 1001 -Force
Register-Completion rc_string "hello world"
Register-Completion rc_list 'arg1','arg2','arg3'
# powershell version >= 7.0.0
Register-Completion rc_array '["arg1","arg2","arg3"]'
Register-Completion rc_hashtable @{
 arg1 = 'arg1_1'; 
 arg2 = 'arg2_2'; 
 arg3 = @{
  arg3_1 = 'arg3_1_1';
  arg3_2 = 'arg3_2_1'
  }
}
# powershell version >= 7.0.0
Register-Completion rc_object "
{
 'arg1': 'arg1_1',
 'arg2': 'arg2_2',
 'arg3': {
  'arg3_1': 'arg3_1_1',
  'arg3_2': 'arg3_2_1'
 }
}
"
```

## More Info

`Register-Completion` module export the variables:

+ `$cache_all_completion`: cache all the avaliable completion
+ `$cache_command_list`: cache the register completion list

## License

[MIT](.\LICENSE)
