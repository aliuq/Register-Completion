BeforeAll {
  . "$pwd\src\Completion.ps1"

  function Compare-Hashtable {
    Param(
      [Hashtable]$HashObjectOne,
      [Hashtable]$HashObjectTwo
    )

    if ($HashObjectOne.Count -ne $HashObjectTwo.Count) {
      return $false
    }

    $flag = $true

    foreach ($key in $HashObjectOne.Keys) {
      $hashOne = $HashObjectOne[$key]
      $hashTwo = $HashObjectTwo[$key]

      if ($hashOne.getType() -in [object[]],[hashtable]) {
        $flag = Compare-Hashtable $hashOne $hashTwo
      }
      elseif ([string]::IsNullOrEmpty($hashOne) -And [string]::IsNullOrEmpty($hashTwo)) {
        continue
      }
      elseif ($hashOne -ne $hashTwo) {
        $flag = $false
        break
      }
    }

    return $flag
  }
}

Describe "ConvertTo-Hash" {
  It "Convert <type>" -ForEach @(
    @{ Type = "string"; Src = "arg"; Expected = @{arg = ""} }
    @{ Type = "number"; Src = 100; Expected = @{100 = ""} }
    @{ Type = "number string"; Src = "100"; Expected = @{100 = ""} }
    @{ Type = "array number"; Src = "[100]"; Expected = @{100 = ""} }
    @{ Type = "array number"; Src = "[100,101]"; Expected = @{100 = ""; 101 = ""} }
    @{ Type = "array string"; Src = "['hello']"; Expected = @{hello = ""} }
    @{ Type = "array string"; Src = "['hello','world']"; Expected = @{hello = ""; world = ""} }
    @{ Type = "array object"; Src = "[{arg: 'arg_1'}]"; Expected = @{arg = @{arg_1 = ""}} }
    @{
      Type = "array nested object";
      Src = "[{arg: {arg_1: 'arg_1_1'}}]";
      Expected = @{arg = @{arg_1 = @{arg_1_1 = ""}}}
    }
    @{
      Type = "array nested object array";
      Src = "[{arg: {arg_1: {arg_1_1: ['arg_1_1_1', 'arg_1_1_2']}}}]";
      Expected = @{arg = @{arg_1 = @{arg_1_1 = @{arg_1_1_1 = ""; arg_1_1_2 = ""}}}}
    }
    @{
      Type = "array number、string、object、array";
      Src = "[100, 'hello', {arg1: 'arg1_1'}, ['arg2', 'arg3']]";
      Expected = @{100 = ""; hello = ""; arg1 = @{arg1_1 = ""}; arg2 = ""; arg3 = ""}
    }
    @{
      Type = "hashtable number、string、hashtable、list";
      Src = @{100 = ""; hello = ""; arg1 = @{arg1_1 = ""}; arg2 = ""; arg3 = ""};
      Expected = @{100 = ""; hello = ""; arg1 = @{arg1_1 = ""}; arg2 = ""; arg3 = ""}
    }
    @{
      Type = "powershell list";
      Src = @("arg1", "arg2");
      Expected = @{arg1 = ""; arg2 = ""}
    }
    @{
      Type = "powershell list hashtable";
      Src = @("arg1", @{arg2 = "arg2_1"; arg3 = @("arg3_1", "arg3_2")});
      Expected = @{arg1 = ""; arg2 = @{arg2_1 = ""}; arg3 = @{arg3_1 = ""; arg3_2 = ""}}
    }
    @{
      Type = "hashtable nested data";
      Src = @{100 = ""; hello = ""; arg1 = @{arg1_1 = ""}; arg2 = ""; arg3 = @("arg3_1", "arg3_2")};
      Expected = @{100 = ""; hello = ""; arg1 = @{arg1_1 = ""}; arg2 = ""; arg3 = @{arg3_1 = ""; arg3_2 = ""}}
    }
    @{
      Type = "object number、string、object、array";
      Src = "{a:1,b:2,c:['c1','c2',{c3:{c3_1:'c3_1_1',c3_2:['c3_2_1','c3_2_2']}}]}";
      Expected = @{a = @{1 = ""}; b = @{2 = ""}; c = @{c1 = ""; c2 = ""; c3 = @{c3_1 = @{c3_1_1 = ""}; c3_2 = @{c3_2_1 = ""; c3_2_2 = ""}}}}
    }
  ) {
    $hash = ConvertTo-Hash $src
    Compare-Hashtable $hash $expected | Should -Be $true
  }
}

Describe "Test Cases" {
  It "test number" {
    $list = 100
    New-Completion case $list
    $CacheCommands["case"] | Should -Be 100

    Get-CompletionKeys "" "case" $list | Should -Be @(100)
    Get-CompletionKeys "1" "case 1" $list | Should -Be @(100)
    Get-CompletionKeys "" "case 1" $list | Should -Be @()
    Get-CompletionKeys "2" "case 2" $list | Should -Be @()
    Get-CompletionKeys "" "case 2" $list | Should -Be @()

    $CacheAllCompletions["case"] | Should -Be $((ConvertTo-Hash $list).Keys)
    New-Completion case 1001
    $CacheCommands["case"] | Should -Be 100
    New-Completion case 1001 -Force
    $CacheCommands.case | Should -Be 1001
    Remove-Completion case
    $CacheCommands["case"] | Should -Be $null
    $CacheAllCompletions["case"] | Should -Be $null
  }

  It "test number string" {
    $list = "100"
    New-Completion case $list
    $CacheCommands["case"] | Should -Be "100"

    Get-CompletionKeys "" "case" $list | Should -Be @("100")
    Get-CompletionKeys "1" "case 1" $list | Should -Be @("100")
    Get-CompletionKeys "" "case 1" $list | Should -Be @()
    Get-CompletionKeys "2" "case 2" $list | Should -Be @()
    Get-CompletionKeys "" "case 2" $list | Should -Be @()

    $CacheAllCompletions["case"] | Should -Be $((ConvertTo-Hash $list).Keys)
    New-Completion case "1001"
    $CacheCommands["case"] | Should -Be "100"
    New-Completion case "1001" -Force
    $CacheCommands.case | Should -Be "1001"
    Remove-Completion case
    $CacheCommands["case"] | Should -Be $null
    $CacheAllCompletions["case"] | Should -Be $null
  }

  It "test string" {
    $list = "world"
    New-Completion case $list
    $CacheCommands["case"] | Should -Be "world"

    Get-CompletionKeys "" "case" $list | Should -Be @("world")
    Get-CompletionKeys "w" "case w" $list | Should -Be @("world")
    Get-CompletionKeys "" "case w" $list | Should -Be @()
    Get-CompletionKeys "c" "case c" $list | Should -Be @()
    Get-CompletionKeys "" "case c" $list | Should -Be @()

    $CacheAllCompletions["case"] | Should -Be $((ConvertTo-Hash $list).Keys)
    New-Completion case "world new"
    $CacheCommands["case"] | Should -Be "world"
    New-Completion case "world new" -Force
    $CacheCommands.case | Should -Be "world new"
    Remove-Completion case
    $CacheCommands["case"] | Should -Be $null
    $CacheAllCompletions["case"] | Should -Be $null
  }

  It "test <type>" -ForEach @(
    @{
      Type = "js array";
      List = "['arg1','arg2','arg3']"
      ListNew = "['arg1_new','arg2_new','arg3_new']"
    }
    @{
      Type = "powershell list";
      List = "arg1","arg2","arg3"
      ListNew = "arg1_new","arg2_new","arg3_new"
    }
  ) {
    New-Completion case $list
    $CacheCommands["case"] | Should -Be $list

    Get-CompletionKeys "" "case" $list | Should -Be @("arg1","arg2","arg3")
    Get-CompletionKeys "2" "case 2" $list | Should -Be @("arg2")
    Get-CompletionKeys "" "case w" $list | Should -Be @()
    Get-CompletionKeys "c" "case c" $list | Should -Be @()
    Get-CompletionKeys "" "case c" $list | Should -Be @()
    Get-CompletionKeys "arg1" "case arg1" $list | Should -Be @("arg1")
    Get-CompletionKeys "" "case arg1" $list | Should -Be @()

    $CacheAllCompletions["case"] | Should -Be $((ConvertTo-Hash $list).Keys)
    New-Completion case $listNew
    $CacheCommands["case"] | Should -Be $list
    New-Completion case $listNew -Force
    $CacheCommands.case | Should -Be $listNew
    Remove-Completion case
    $CacheCommands["case"] | Should -Be $null
    $CacheAllCompletions["case"] | Should -Be $null
  }

  It "test <type>" -ForEach @(
    @{
      Type = "js object";
      List = "{
        'arg1': 'arg1_1',
        'arg2': 'arg2_2',
        'arg3': {
          'arg3_1': 'arg3_1_1',
          'arg3_2': 'arg3_2_1'
        }
      }";
      ListNew = "{
        'arg1': 'arg1_1_new',
        'arg2_new': 'arg2_2',
        'arg3': {
          'arg3_1': 'arg3_1_1_new',
          'arg3_2_new': 'arg3_2_1'
        }
      }"
    }
    @{
      Type = "powershell hashtable";
      List = @{
        arg1 = "arg1_1";
        arg2 = "arg2_2";
        arg3 = @{
          arg3_1 = "arg3_1_1";
          arg3_2 = "arg3_2_1"
        }
      };
      ListNew = @{
        arg1 = "arg1_1_new";
        arg2_new = "arg2_2";
        arg3 = @{
          arg3_1 = "arg3_1_1_new";
          arg3_2_new = "arg3_2_1"
        }
      }
    }
  ) {
    New-Completion case $list
    $CacheCommands["case"] | Should -Be $list

    Get-CompletionKeys "" "case" $list | Should -Be @("arg1","arg2","arg3")
    Get-CompletionKeys "2" "case 2" $list | Should -Be @("arg2")
    Get-CompletionKeys "" "case 2" $list | Should -Be @()
    Get-CompletionKeys "" "case arg3" $list | Should -Be @("arg3_1", "arg3_2")
    Get-CompletionKeys "2" "case arg3 2" $list | Should -Be @("arg3_2")
    Get-CompletionKeys "1" "case arg3 arg3_1 1" $list | Should -Be @("arg3_1_1")
    Get-CompletionKeys "" "case arg3 arg3_1 1" $list | Should -Be @()

    $CacheAllCompletions["case"] | Should -Be $((ConvertTo-Hash $list).Keys)
    New-Completion case $listNew
    $CacheCommands["case"] | Should -Be $list
    New-Completion case $listNew -Force
    $CacheCommands.case | Should -Be $listNew
    Remove-Completion case
    $CacheCommands["case"] | Should -Be $null
    $CacheAllCompletions["case"] | Should -Be $null
  }

  It "test <type>" -ForEach @(
    @{
      Type = "js object array";
      List = "{
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
      ListNew = "{
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
      Type = "powershell hashtable list";
      List = @{
        arg1 = "arg1_1",@{arg1_2 = "arg1_2_1"};
        arg2 = "arg2_2";
        arg3 = @{
          arg3_1 = "arg3_1_1", "arg3_1_2";
          arg3_2 = "arg3_2_1"
        }
      };
      ListNew = @{
        arg1_new = "arg1_1",@{arg1_2 = "arg1_2_1"};
        arg2 = "arg2_2_new";
        arg3 = @{
          arg3_1 = "arg3_1_1_new", "arg3_1_2";
          arg3_2 = "arg3_2_1"
        }
      }
    }
  ) {
    New-Completion case $list
    $CacheCommands["case"] | Should -Be $list

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

    $CacheAllCompletions["case"] | Should -Be $((ConvertTo-Hash $list).Keys)
    New-Completion case $listNew
    $CacheCommands["case"] | Should -Be $list
    New-Completion case $listNew -Force
    $CacheCommands.case | Should -Be $listNew
    Remove-Completion case
    $CacheCommands["case"] | Should -Be $null
    $CacheAllCompletions["case"] | Should -Be $null
  }

  It "test <type>" -ForEach @(
    @{
      Type = "js array object";
      List = "[
        'arg1',
        { 'arg2': 'arg2_2' },
        ['arg3', {'arg4': 'arg4_1'}]
      ]";
      ListNew = "[
        'arg1',
        { 'arg2': 'arg2_2_new' },
        ['arg3', {'arg4_new': 'arg4_1'}]
      ]"
    }
    @{
      Type = "powershell list hashtable";
      List = @(
        'arg1',
        @{ arg2 = "arg2_2" },
        @('arg3', @{arg4 = "arg4_1"})
      );
      ListNew = @(
        'arg1',
        @{ arg2 = "arg2_2_new" },
        @('arg3', @{arg4_new = "arg4_1"})
      )
    }
  ) {
    New-Completion case $list
    $CacheCommands["case"] | Should -Be $list

    Get-CompletionKeys "" "case" $list | Should -Be @("arg1","arg2","arg3","arg4")
    Get-CompletionKeys "2" "case 2" $list | Should -Be @("arg2")
    Get-CompletionKeys "" "case 2" $list | Should -Be @()
    Get-CompletionKeys "" "case arg2" $list | Should -Be @("arg2_2")
    Get-CompletionKeys "2" "case arg2 2" $list | Should -Be @("arg2_2")
    Get-CompletionKeys "" "case arg2 2" $list | Should -Be @()
    Get-CompletionKeys "" "case arg4" $list | Should -Be @("arg4_1")
    Get-CompletionKeys "" "case arg4 2" $list | Should -Be @()

    $CacheAllCompletions["case"] | Should -Be $((ConvertTo-Hash $list).Keys)
    New-Completion case $listNew
    $CacheCommands["case"] | Should -Be $list
    New-Completion case $listNew -Force
    $CacheCommands.case | Should -Be $listNew
    Remove-Completion case
    $CacheCommands["case"] | Should -Be $null
    $CacheAllCompletions["case"] | Should -Be $null
  }
}


