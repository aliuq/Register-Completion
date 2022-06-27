BeforeAll {
  . "$pwd\src\Register-Completion\Register-Completion.ps1"

  function Compare-Hashtable {
    Param(
      [Hashtable]$hash_object_1,
      [Hashtable]$hash_object_2
    )

    if ($hash_object_1.Count -ne $hash_object_2.Count) {
      return $false
    }

    $result = $true

    $hash_object_1.Keys | ForEach-Object {
      $value_1 = $hash_object_1[$_]
      $value_2 = $hash_object_2[$_]

      if ($value_1 -ne $value_2) {
        $result = $false
      }
    }

    return $result
  }
}

Describe "Register-Completion" {
  Context "Test function - Convert-JsonToHash" {
    It "Convert type <type>" -ForEach @(
      @{ type = 'number'; src = 100; expected = 100 }
      @{ type = 'string 1'; src = "100"; expected = 100 }
      @{ type = 'string 2'; src = "World"; expected = "World" }
      @{ type = 'js array'; src = "['arg1','arg2','arg3']"; expected = "arg1","arg2","arg3" }
      @{ type = 'powershell array 1'; src = 'arg1','arg2','arg3'; expected = "arg1","arg2","arg3" }
      @{ type = 'powershell array 2'; src = @('arg1','arg2','arg3'); expected = "arg1","arg2","arg3" }
      @{
        type = 'js object';
        src = "{ arg1: 'arg1_1', arg2: 'arg2_2' }";
        expected = @{arg1 = 'arg1_1'; arg2 = 'arg2_2'}
      }
      @{
        type = 'powershell hashtable';
        src = @{arg1 = 'arg1_1'; arg2 = 'arg2_2'};
        expected = @{arg1 = 'arg1_1'; arg2 = 'arg2_2'}
      }
    ) {
      if ($type -in 'js object', 'powershell hashtable') {
        $hash = Convert-JsonToHash $src
        Compare-Hashtable $hash $expected | Should -Be $true
      }
      else {
        Convert-JsonToHash $src | Should -Be $expected
      }
    }
  }

  Context "Test function - Get-CompletionKeys" {
    It "<type> | typing '<ast>' should complete '<expected>'" -ForEach @(
      @{ type = "number"; word = ""; ast = "gc_number "; list = 100; "expected" = @(100) }
      @{ type = "number"; word = "1"; ast = "gc_number 1"; list = 100; "expected" = @(100) }
      @{ type = "number"; word = "1"; ast = "gc_number 1 "; list = 100; "expected" = @() }
      @{ type = "number"; word = "2"; ast = "gc_number 2"; list = 100; "expected" = @() }
      @{ type = "number"; word = "2"; ast = "gc_number 2 "; list = 100; "expected" = @() }
      @{ type = 'string'; word = ""; ast = "gc_string_1 "; list = "100"; "expected" = @(100) }
      @{ type = 'string'; word = "1"; ast = "gc_string_1 1"; list = "100"; "expected" = @(100) }
      @{ type = 'string'; word = "1"; ast = "gc_string_1 1 "; list = "100"; "expected" = @() }
      @{ type = 'string'; word = "2"; ast = "gc_string_1 2"; list = "100"; "expected" = @() }
      @{ type = 'string'; word = "2"; ast = "gc_string_1 2 "; list = "100"; "expected" = @() }
      @{ type = 'string'; word = ""; ast = "gc_string_2 "; list = "world"; "expected" = @("world") }
      @{ type = 'string'; word = "w"; ast = "gc_string_2 w"; list = "world"; "expected" = @("world") }
      @{ type = 'string'; word = "ld"; ast = "gc_string_2 ld"; list = "world"; "expected" = @("world") }
      @{ type = 'string'; word = "w"; ast = "gc_string_2 w "; list = "world"; "expected" = @() }
      @{ type = 'string'; word = "d"; ast = "gc_string_2 d "; list = "world"; "expected" = @() }
      @{
        type = "js array"; word = ""; ast = "gc_array_1 ";
        list = "['arg1','arg2','arg3']";
        expected = @('arg1','arg2','arg3')
      }
      @{
        type = "js array"; word = "2"; ast = "gc_array_1 2";
        list = "['arg1','arg2','arg3']";
        expected = @("arg2")
      }
      @{
        type = "js array"; word = "3"; ast = "gc_array_1 3 ";
        list = "['arg1','arg2','arg3']";
        expected = @()
      }
      @{
        type = "powershell array"; word = ""; ast = "gc_array_2 ";
        list = "arg1","arg2","arg3";
        expected = @("arg1","arg2","arg3")
      }
      @{
        type = "powershell array"; word = "2"; ast = "gc_array_2 2";
        list = "arg1","arg2","arg3";
        expected = @("arg2")
      }
      @{
        type = "powershell array"; word = "3"; ast = "gc_array_2 3 ";
        list = "arg1","arg2","arg3";
        expected = @()
      }
      @{
        type = "js object"; word = ""; ast = "gc_object ";
        list = "{'arg1': 'arg1_1', 'arg2': 'arg2_2', 'arg3': {'arg3_1': 'arg3_1_1', 'arg3_2': 'arg3_2_1'}}"
        expected = @("arg1","arg2","arg3")
      }
      @{
        type = "js object"; word = "2"; ast = "gc_object 2";
        list = "{'arg1': 'arg1_1', 'arg2': 'arg2_2', 'arg3': {'arg3_1': 'arg3_1_1', 'arg3_2': 'arg3_2_1'}}"
        expected = @("arg2")
      }
      @{
        type = "js object"; word = "arg2"; ast = "gc_object arg2";
        list = "{'arg1': 'arg1_1', 'arg2': 'arg2_2', 'arg3': {'arg3_1': 'arg3_1_1', 'arg3_2': 'arg3_2_1'}}"
        expected = @("arg2")
      }
      @{
        type = "js object"; word = "arg2"; ast = "gc_object arg2 ";
        list = "{'arg1': 'arg1_1', 'arg2': 'arg2_2', 'arg3': {'arg3_1': 'arg3_1_1', 'arg3_2': 'arg3_2_1'}}"
        expected = @("arg2_2")
      }
      @{
        type = "js object"; word = "arg3"; ast = "gc_object arg3 ";
        list = "{'arg1': 'arg1_1', 'arg2': 'arg2_2', 'arg3': {'arg3_1': 'arg3_1_1', 'arg3_2': 'arg3_2_1'}}"
        expected = @("arg3_1","arg3_2")
      }
      @{
        type = "js object"; word = "2"; ast = "gc_object arg3 2";
        list = "{'arg1': 'arg1_1', 'arg2': 'arg2_2', 'arg3': {'arg3_1': 'arg3_1_1', 'arg3_2': 'arg3_2_1'}}"
        expected = @("arg3_2")
      }
      @{
        type = "js object"; word = "arg3_2"; ast = "gc_object arg3 arg3_2 ";
        list = "{'arg1': 'arg1_1', 'arg2': 'arg2_2', 'arg3': {'arg3_1': 'arg3_1_1', 'arg3_2': 'arg3_2_1'}}"
        expected = @("arg3_2_1")
      }
      @{
        type = "js object"; word = "4"; ast = "gc_object arg2 4";
        list = "{'arg1': 'arg1_1', 'arg2': 'arg2_2', 'arg3': {'arg3_1': 'arg3_1_1', 'arg3_2': 'arg3_2_1'}}"
        expected = @()
      }
      @{
        type = "js object"; word = ""; ast = "gc_object_2 arg2 ";
        list = "{'arg1': 'arg1_1', 'arg2': ['arg2_2_1', 'arg2_2_2'], 'arg3': {'arg3_1': 'arg3_1_1', 'arg3_2': 'arg3_2_1'}}"
        expected = @("arg2_2_1", "arg2_2_2")
      }
      @{
        type = "powershell hashtable"; word = ""; ast = "gc_hashtable ";
        list = @{arg1 = "arg1_1"; arg2 = "arg2_2"; arg3 = @{arg3_1 = "arg3_1_1"; arg3_2 = "arg3_2_1"}}
        expected = @("arg1","arg2","arg3")
      }
      @{
        type = "powershell hashtable"; word = "2"; ast = "gc_hashtable 2";
        list = @{arg1 = "arg1_1"; arg2 = "arg2_2"; arg3 = @{arg3_1 = "arg3_1_1"; arg3_2 = "arg3_2_1"}}
        expected = @("arg2")
      }
      @{
        type = "powershell hashtable"; word = "arg2"; ast = "gc_hashtable arg2";
        list = @{arg1 = "arg1_1"; arg2 = "arg2_2"; arg3 = @{arg3_1 = "arg3_1_1"; arg3_2 = "arg3_2_1"}}
        expected = @("arg2")
      }
      @{
        type = "powershell hashtable"; word = "arg2"; ast = "gc_hashtable arg2 ";
        list = @{arg1 = "arg1_1"; arg2 = "arg2_2"; arg3 = @{arg3_1 = "arg3_1_1"; arg3_2 = "arg3_2_1"}}
        expected = @("arg2_2")
      }
      @{
        type = "powershell hashtable"; word = "arg3"; ast = "gc_hashtable arg3 ";
        list = @{arg1 = "arg1_1"; arg2 = "arg2_2"; arg3 = @{arg3_1 = "arg3_1_1"; arg3_2 = "arg3_2_1"}}
        expected = @("arg3_1","arg3_2")
      }
      @{
        type = "powershell hashtable"; word = "2"; ast = "gc_hashtable arg3 2";
        list = @{arg1 = "arg1_1"; arg2 = "arg2_2"; arg3 = @{arg3_1 = "arg3_1_1"; arg3_2 = "arg3_2_1"}}
        expected = @("arg3_2")
      }
      @{
        type = "powershell hashtable"; word = "arg3_2"; ast = "gc_hashtable arg3 arg3_2 ";
        list = @{arg1 = "arg1_1"; arg2 = "arg2_2"; arg3 = @{arg3_1 = "arg3_1_1"; arg3_2 = "arg3_2_1"}}
        expected = @("arg3_2_1")
      }
      @{
        type = "powershell hashtable"; word = "4"; ast = "gc_hashtable arg2 4";
        list = @{arg1 = "arg1_1"; arg2 = "arg2_2"; arg3 = @{arg3_1 = "arg3_1_1"; arg3_2 = "arg3_2_1"}}
        expected = @()
      }
      @{
        type = "powershell hashtable"; word = ""; ast = "gc_hashtable_2 arg2 ";
        list = @{arg1 = "arg1_1"; arg2 = "arg2_2_1","arg2_2_2"; arg3 = @{arg3_1 = "arg3_1_1"; arg3_2 = "arg3_2_1"}}
        expected = @("arg2_2_1", "arg2_2_2")
      }
    ) {
      Get-CompletionKeys $word $ast $list | Should -Be $expected
    }
  }

  Context "Test function - Register-Completion" {
    It "register completion by force replace <type>" -ForEach @(
      @{ type = "number"; src = 100; new_src = 1001 }
      @{ type = "string"; src = "100"; new_src = "1001" }
      @{ 
        type = "js array";
        src = "['arg1','arg2','arg3']";
        new_src = "['arg1_new','arg2','arg3']"
      }
      @{ 
        type = "powershell array";
        src = 'arg1','arg2','arg3';
        new_src = 'arg1_new','arg2','arg3'
      }
      @{ 
        type = "js object";
        src = "{ arg1: 'arg1_1', arg2: 'arg2_2' }";
        new_src = "{ arg1: 'arg1_1_new', arg2_new: 'arg2_2' }"
      }
      @{ 
        type = "powershell object";
        src = @{arg1 = 'arg1_1'; arg2 = 'arg2_2'};
        new_src = @{arg1 = 'arg1_1_new'; arg2_new = 'arg2_2'};
      }
    ) {
      Register-Completion rcf $src
      $cache_command_list["rcf"] | Should -Be $src
      Register-Completion rcf $new_src
      $cache_command_list["rcf"] | Should -Be $src
      Register-Completion rcf $new_src -Force
      $cache_command_list["rcf"] | Should -Be $new_src
      Remove-Completion rcf
      $cache_command_list["rcf"] | Should -Be $null
    }
  }

  Context "Test variable - cache_command_list" {
    BeforeAll {
      Register-Completion rc_number 100
      Register-Completion rc_string "100"
      Register-Completion rc_js_array "['arg1', 'arg2', 'arg3']"
      Register-Completion rc_powershell_array @('arg1', 'arg2', 'arg3')
      Register-Completion rc_js_object "{ arg1: 'arg1_1', arg2: 'arg2_2' }"
      Register-Completion rc_powershell_object @{arg1 = 'arg1_1'; arg2 = 'arg2_2'}
    }
    It "test cache_command_list count" {
      $cache_command_list.Count | Should -Be 6
    }
    It "test Remove-Completion" {
      Remove-Completion rc_number
      $cache_command_list["rc_number"] | Should -Be $null
      Remove-Completion "rc_js_object.arg2"
      $cache_command_list.Count | Should -Be 5
    }
  }
}
