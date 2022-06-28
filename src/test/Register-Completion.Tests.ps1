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

    foreach ($key in $hash_object_1.Keys) {
      $hash_1 = $hash_object_1[$key]
      $hash_2 = $hash_object_2[$key]

      if ($hash_1.getType() -in [object[]],[hashtable]) {
        $result = Compare-Hashtable $hash_1 $hash_2
      }
      elseif ([string]::IsNullOrEmpty($hash_1) -And [string]::IsNullOrEmpty($hash_2)) {
        continue
      }
      elseif ($hash_1 -ne $hash_2) {
        $result = $false
        break
      }
    }

    return $result
  }
}

Describe "ConvertTo-Hash" {
  It "convert <type>" -ForEach @(
    @{ type = "string"; src = "arg"; expected = @{arg = ""} }
    @{ type = "number"; src = 100; expected = @{100 = ""} }
    @{ type = "number string"; src = "100"; expected = @{100 = ""} }
    @{ type = "array number"; src = "[100]"; expected = @{100 = ""} }
    @{ type = "array number"; src = "[100,101]"; expected = @{100 = ""; 101 = ""} }
    @{ type = "array string"; src = "['hello']"; expected = @{hello = ""} }
    @{ type = "array string"; src = "['hello','world']"; expected = @{hello = ""; world = ""} }
    @{ type = "array object"; src = "[{arg: 'arg_1'}]"; expected = @{arg = @{arg_1 = ""}} }
    @{
      type = "array nested object";
      src = "[{arg: {arg_1: 'arg_1_1'}}]";
      expected = @{arg = @{arg_1 = @{arg_1_1 = ""}}}
    }
    @{
      type = "array nested object array";
      src = "[{arg: {arg_1: {arg_1_1: ['arg_1_1_1', 'arg_1_1_2']}}}]";
      expected = @{arg = @{arg_1 = @{arg_1_1 = @{arg_1_1_1 = ""; arg_1_1_2 = ""}}}}
    }
    @{
      type = "array number、string、object、array";
      src = "[100, 'hello', {arg1: 'arg1_1'}, ['arg2', 'arg3']]";
      expected = @{100 = ""; hello = ""; arg1 = @{arg1_1 = ""}; arg2 = ""; arg3 = ""}
    }
    @{
      type = "hashtable number、string、hashtable、list";
      src = @{100 = ""; hello = ""; arg1 = @{arg1_1 = ""}; arg2 = ""; arg3 = ""}
      expected = @{100 = ""; hello = ""; arg1 = @{arg1_1 = ""}; arg2 = ""; arg3 = ""}
    }
    @{
      type = "object number、string、object、array";
      src = "{a:1,b:2,c:['c1','c2',{c3:{c3_1:'c3_1_1',c3_2:['c3_2_1','c3_2_2']}}]}";
      expected = @{a = @{1 = ""}; b = @{2 = ""}; c = @{c1 = ""; c2 = ""; c3 = @{c3_1 = @{c3_1_1 = ""}; c3_2 = @{c3_2_1 = ""; c3_2_2 = ""}}}}
    }
  ) {
    $hash = ConvertTo-Hash $src
    Compare-Hashtable $hash $expected | Should -Be $true
  }
}

Describe "Test Cases" {
  It "test number" {
    $list = 100
    Register-Completion case $list
    $cache_command_list["case"] | Should -Be 100

    Get-CompletionKeys "" "case" $list | Should -Be @(100)
    Get-CompletionKeys "1" "case 1" $list | Should -Be @(100)
    Get-CompletionKeys "" "case 1" $list | Should -Be @()
    Get-CompletionKeys "2" "case 2" $list | Should -Be @()
    Get-CompletionKeys "" "case 2" $list | Should -Be @()

    $cache_all_completion["case"] | Should -Be $((ConvertTo-Hash $list).Keys)
    Register-Completion case 1001
    $cache_command_list["case"] | Should -Be 100
    Register-Completion case 1001 -Force
    $cache_command_list.case | Should -Be 1001
    Remove-Completion case
    $cache_command_list["case"] | Should -Be $null
    $cache_all_completion["case"] | Should -Be $null
  }

  It "test number string" {
    $list = "100"
    Register-Completion case $list
    $cache_command_list["case"] | Should -Be "100"

    Get-CompletionKeys "" "case" $list | Should -Be @("100")
    Get-CompletionKeys "1" "case 1" $list | Should -Be @("100")
    Get-CompletionKeys "" "case 1" $list | Should -Be @()
    Get-CompletionKeys "2" "case 2" $list | Should -Be @()
    Get-CompletionKeys "" "case 2" $list | Should -Be @()

    $cache_all_completion["case"] | Should -Be $((ConvertTo-Hash $list).Keys)
    Register-Completion case "1001"
    $cache_command_list["case"] | Should -Be "100"
    Register-Completion case "1001" -Force
    $cache_command_list.case | Should -Be "1001"
    Remove-Completion case
    $cache_command_list["case"] | Should -Be $null
    $cache_all_completion["case"] | Should -Be $null
  }

  It "test string" {
    $list = "world"
    Register-Completion case $list
    $cache_command_list["case"] | Should -Be "world"

    Get-CompletionKeys "" "case" $list | Should -Be @("world")
    Get-CompletionKeys "w" "case w" $list | Should -Be @("world")
    Get-CompletionKeys "" "case w" $list | Should -Be @()
    Get-CompletionKeys "c" "case c" $list | Should -Be @()
    Get-CompletionKeys "" "case c" $list | Should -Be @()

    $cache_all_completion["case"] | Should -Be $((ConvertTo-Hash $list).Keys)
    Register-Completion case "world new"
    $cache_command_list["case"] | Should -Be "world"
    Register-Completion case "world new" -Force
    $cache_command_list.case | Should -Be "world new"
    Remove-Completion case
    $cache_command_list["case"] | Should -Be $null
    $cache_all_completion["case"] | Should -Be $null
  }

  It "test <type>" -ForEach @(
    @{
      type = "js array";
      list = "['arg1','arg2','arg3']"
      list_new = "['arg1_new','arg2_new','arg3_new']"
    }
    @{
      type = "powershell list";
      list = "arg1","arg2","arg3"
      list_new = "arg1_new","arg2_new","arg3_new"
    }
  ) {
    $list = "['arg1','arg2','arg3']"
    $list_new = "['arg1_new','arg2_new','arg3_new']"
    Register-Completion case $list
    $cache_command_list["case"] | Should -Be $list

    Get-CompletionKeys "" "case" $list | Should -Be @("arg1","arg2","arg3")
    Get-CompletionKeys "2" "case 2" $list | Should -Be @("arg2")
    Get-CompletionKeys "" "case w" $list | Should -Be @()
    Get-CompletionKeys "c" "case c" $list | Should -Be @()
    Get-CompletionKeys "" "case c" $list | Should -Be @()
    Get-CompletionKeys "arg1" "case arg1" $list | Should -Be @("arg1")
    Get-CompletionKeys "" "case arg1" $list | Should -Be @()

    $cache_all_completion["case"] | Should -Be $((ConvertTo-Hash $list).Keys)
    Register-Completion case $list_new
    $cache_command_list["case"] | Should -Be $list
    Register-Completion case $list_new -Force
    $cache_command_list.case | Should -Be $list_new
    Remove-Completion case
    $cache_command_list["case"] | Should -Be $null
    $cache_all_completion["case"] | Should -Be $null
  }

  It "test <type>" -ForEach @(
    @{
      type = "js object";
      list = "{
        'arg1': 'arg1_1',
        'arg2': 'arg2_2',
        'arg3': {
          'arg3_1': 'arg3_1_1',
          'arg3_2': 'arg3_2_1'
        }
      }";
      list_new = "{
        'arg1': 'arg1_1_new',
        'arg2_new': 'arg2_2',
        'arg3': {
          'arg3_1': 'arg3_1_1_new',
          'arg3_2_new': 'arg3_2_1'
        }
      }"
    }
    @{
      type = "powershell hashtable";
      list = @{
        arg1 = "arg1_1";
        arg2 = "arg2_2";
        arg3 = @{
          arg3_1 = "arg3_1_1";
          arg3_2 = "arg3_2_1"
        }
      };
      list_new = @{
        arg1 = "arg1_1_new";
        arg2_new = "arg2_2";
        arg3 = @{
          arg3_1 = "arg3_1_1_new";
          arg3_2_new = "arg3_2_1"
        }
      }
    }
  ) {
    Register-Completion case $list
    $cache_command_list["case"] | Should -Be $list

    Get-CompletionKeys "" "case" $list | Should -Be @("arg1","arg2","arg3")
    Get-CompletionKeys "2" "case 2" $list | Should -Be @("arg2")
    Get-CompletionKeys "" "case 2" $list | Should -Be @()
    Get-CompletionKeys "" "case arg3" $list | Should -Be @("arg3_1", "arg3_2")
    Get-CompletionKeys "2" "case arg3 2" $list | Should -Be @("arg3_2")
    Get-CompletionKeys "1" "case arg3 arg3_1 1" $list | Should -Be @("arg3_1_1")
    Get-CompletionKeys "" "case arg3 arg3_1 1" $list | Should -Be @()

    $cache_all_completion["case"] | Should -Be $((ConvertTo-Hash $list).Keys)
    Register-Completion case $list_new
    $cache_command_list["case"] | Should -Be $list
    Register-Completion case $list_new -Force
    $cache_command_list.case | Should -Be $list_new
    Remove-Completion case
    $cache_command_list["case"] | Should -Be $null
    $cache_all_completion["case"] | Should -Be $null
  }

  It "test <type>" -ForEach @(
    @{
      type = "js object array";
      list = "{
        'arg1': [
          'arg1_1',
          { arg1_2: 'arg1_2_1' }
        ],
        'arg2': 'arg2_2',
        'arg3': {
          'arg3_1': ['arg3_1_1', 'arg3_1_2'],
          'arg3_2': 'arg3_2_1'
        }
      }";
      list_new = "{
        'arg1_new': [
          'arg1_1',
          { arg1_2: 'arg1_2_1' }
        ],
        'arg2': 'arg2_2_new',
        'arg3': {
          'arg3_1': ['arg3_1_1_new', 'arg3_1_2'],
          'arg3_2': 'arg3_2_1'
        }
      }"
    }
    @{
      type = "powershell hashtable list";
      list = @{
        arg1 = "arg1_1",@{arg1_2 = "arg1_2_1"};
        arg2 = "arg2_2";
        arg3 = @{
          arg3_1 = "arg3_1_1", "arg3_1_2";
          arg3_2 = "arg3_2_1"
        }
      };
      list_new = @{
        arg1_new = "arg1_1",@{arg1_2 = "arg1_2_1"};
        arg2 = "arg2_2_new";
        arg3 = @{
          arg3_1 = "arg3_1_1_new", "arg3_1_2";
          arg3_2 = "arg3_2_1"
        }
      }
    }
  ) {
    Register-Completion case $list
    $cache_command_list["case"] | Should -Be $list

    Get-CompletionKeys "" "case" $list | Should -Be @("arg1","arg2","arg3")
    Get-CompletionKeys "2" "case 2" $list | Should -Be @("arg2")
    Get-CompletionKeys "" "case 2" $list | Should -Be @()
    Get-CompletionKeys "" "case arg1" $list | Should -Be @("arg1_1", "arg1_2")
    Get-CompletionKeys "2" "case arg1 2" $list | Should -Be @("arg1_2")
    Get-CompletionKeys "" "case arg1 arg1_2" $list | Should -Be @("arg1_2_1")
    Get-CompletionKeys "1" "case arg1 arg1_2 1" $list | Should -Be @("arg1_2_1")
    Get-CompletionKeys "" "case arg1 arg1_2 1" $list | Should -Be @()
    Get-CompletionKeys "1" "case arg3 1" $list | Should -Be @("arg3_1")
    Get-CompletionKeys "" "case arg3 1" $list | Should -Be @()
    Get-CompletionKeys "" "case arg3 arg3_1" $list | Should -Be @("arg3_1_1", "arg3_1_2")
    Get-CompletionKeys "2" "case arg3 arg3_1 2" $list | Should -Be @("arg3_1_2")
    Get-CompletionKeys "" "case arg3 arg3_1 2" $list | Should -Be @()

    $cache_all_completion["case"] | Should -Be $((ConvertTo-Hash $list).Keys)
    Register-Completion case $list_new
    $cache_command_list["case"] | Should -Be $list
    Register-Completion case $list_new -Force
    $cache_command_list.case | Should -Be $list_new
    Remove-Completion case
    $cache_command_list["case"] | Should -Be $null
    $cache_all_completion["case"] | Should -Be $null
  }

  It "test <type>" -ForEach @(
    @{
      type = "js array object";
      list = "[
        'arg1',
        { 'arg2': 'arg2_2' },
        ['arg3', {'arg4': 'arg4_1'}]
      ]";
      list_new = "[
        'arg1',
        { 'arg2': 'arg2_2_new' },
        ['arg3', {'arg4_new': 'arg4_1'}]
      ]"
    }
    @{
      type = "powershell list hashtable";
      list = @(
        'arg1',
        @{ arg2 = "arg2_2" },
        @('arg3', @{arg4 = "arg4_1"})
      );
      list_new = @(
        'arg1',
        @{ arg2 = "arg2_2_new" },
        @('arg3', @{arg4_new = "arg4_1"})
      )
    }
  ) {
    Register-Completion case $list
    $cache_command_list["case"] | Should -Be $list

    Get-CompletionKeys "" "case" $list | Should -Be @("arg1","arg2","arg3","arg4")
    Get-CompletionKeys "2" "case 2" $list | Should -Be @("arg2")
    Get-CompletionKeys "" "case 2" $list | Should -Be @()
    Get-CompletionKeys "" "case arg2" $list | Should -Be @("arg2_2")
    Get-CompletionKeys "2" "case arg2 2" $list | Should -Be @("arg2_2")
    Get-CompletionKeys "" "case arg2 2" $list | Should -Be @()
    Get-CompletionKeys "" "case arg4" $list | Should -Be @("arg4_1")
    Get-CompletionKeys "" "case arg4 2" $list | Should -Be @()

    $cache_all_completion["case"] | Should -Be $((ConvertTo-Hash $list).Keys)
    Register-Completion case $list_new
    $cache_command_list["case"] | Should -Be $list
    Register-Completion case $list_new -Force
    $cache_command_list.case | Should -Be $list_new
    Remove-Completion case
    $cache_command_list["case"] | Should -Be $null
    $cache_all_completion["case"] | Should -Be $null
  }
}


