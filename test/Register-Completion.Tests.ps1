BeforeAll {
  . "$pwd\src\Completion.ps1"

  function Compare-Hashtable {
    Param(
      [object]$HashObjectOne,
      [object]$HashObjectTwo
    )
    if ($HashObjectOne.Count -ne $HashObjectTwo.Count) {
      return $false
    }

    $flag = $true

    foreach ($key in $HashObjectOne.Keys) {
      # Check the key is valid
      # Write-Host "key: $key"

      if ($key -Match "[\[\]\{\}]") {
        $flag = $false
        break
      }
      
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

Describe 'Test funtion ConvertTo-Hash' {
  It "Convert <type>" -ForEach @(
    @{Type = 'number'; Src = 100; Expected = @{100 = ''}}
    @{Type = 'array number'; Src = '[100,101]'; Expected = @{100 = ''; 101 = ''}}
    @{Type = 'powershell array number'; Src = 100,101; Expected = @{100 = ''; 101 = ''}}
    @{Type = 'string'; Src = 'hello'; Expected = @{'hello' = ''}}
    @{Type = 'array string'; Src = '["hello","world"]'; Expected = @{'hello' = ''; 'world' = ''}}
    @{Type = 'powershell array string'; Src = 'hello','world'; Expected = @{'hello' = ''; 'world' = ''}}
    @{
      Type = 'object';
      Src = '{arg1: "hello", arg2: "world"}';
      Expected = @{arg1 = @{'hello' = ''}; arg2 = @{'world' = ''}}
    }
    @{
      Type = 'array object';
      Src = '[{arg1: "hello", arg2: "world"}]';
      Expected = @{arg1 = @{'hello' = ''}; arg2 = @{'world' = ''}}
    }
    @{
      Type = 'array nested object';
      Src = '[{arg: {arg_1: "arg_1_1"}}]';
      Expected = @{arg = @{arg_1 = @{arg_1_1 = ''}}}
    }
    @{
      Type = 'array nested object array';
      Src = '[{arg: {arg_1: {arg_1_1: ["arg_1_1_1", "arg_1_1_2"]}}}]';
      Expected = @{arg = @{arg_1 = @{arg_1_1 = @{arg_1_1_1 = ''; arg_1_1_2 = ''}}}}
    }
    @{
      Type = 'mixed type 1';
      Src = '[100, "hello", {arg1: "arg1_1"}, ["arg2", "arg3"]]';
      Expected = @{100 = ''; hello = ''; arg1 = @{arg1_1 = ''}; arg2 = ''; arg3 = ''}
    }
    @{
      Type = 'mixed type 2';
      Src = '{a:1,b:2,c:["c1","c2",{c3:{c3_1:"c3_1_1",c3_2:["c3_2_1","c3_2_2"]}}]}';
      Expected = @{a = @{1 = ''}; b = @{2 = ''}; c = @{c1 = ''; c2 = ''; c3 = @{c3_1 = @{c3_1_1 = ''}; c3_2 = @{c3_2_1 = ''; c3_2_2 = ''}}}}
    }
    @{
      Type = 'powershell hashtable mixed type';
      Src = @{100 = ''; hello = ''; arg1 = @{arg1_1 = ''}; arg2 = ''; arg3 = ''};
      Expected = @{100 = ''; hello = ''; arg1 = @{arg1_1 = ''}; arg2 = ''; arg3 = ''}
    }
    @{
      Type = 'powershell list mixed type';
      Src = @('arg1', @{arg2 = 'arg2_1'; arg3 = @('arg3_1', 'arg3_2')});
      Expected = @{arg1 = ''; arg2 = @{arg2_1 = ''}; arg3 = @{arg3_1 = ''; arg3_2 = ''}}
    }
    @{
      Type = 'tooltip';
      Src = '[{arg1: {"#tooltip": "arg1 tooltip"}, arg2: {"#tooltip": "arg2 tooltip"}}]';
      Expected = @{arg1 = @{'#tooltip' = 'arg1 tooltip'}; arg2 = @{'#tooltip' = 'arg2 tooltip'}}
    }
    @{
      Type = 'tooltip listitemtext';
      Src = '[{arg1: {"#tooltip": "arg1 tooltip", "#listitemtext": "arg1 listitemtext"}}]';
      Expected = @{arg1 = @{'#tooltip' = 'arg1 tooltip'; '#listitemtext' = 'arg1 listitemtext'}}
    }
    @{
      Type = 'powershell tooltip 1';
      Src = @{arg1 = @{'#tooltip' = 'arg1 tooltip'}; arg2 = @{'#tooltip' = 'arg2 tooltip'}};
      Expected = @{arg1 = @{'#tooltip' = 'arg1 tooltip'}; arg2 = @{'#tooltip' = 'arg2 tooltip'}}
    }
    @{
      Type = 'powershell tooltip 2';
      Src = @(@{arg1 = @{'#tooltip' = 'arg1 tooltip'}; arg2 = @{'#tooltip' = 'arg2 tooltip'}});
      Expected = @{arg1 = @{'#tooltip' = 'arg1 tooltip'}; arg2 = @{'#tooltip' = 'arg2 tooltip'}}
    }
    @{
      Type = 'powershell tooltip listitemtext';
      Src = @{arg1 = @{'#tooltip' = 'arg1 tooltip'; '#listitemtext' = 'arg1 listitemtext'}};
      Expected = @{arg1 = @{'#tooltip' = 'arg1 tooltip'; '#listitemtext' = 'arg1 listitemtext'}}
    }
  ) {
    $hash = ConvertTo-Hash $src
    Compare-Hashtable $hash $expected | Should -Be $true
  }
}

Describe 'Test Cases' {
  It 'test number' {
    New-Completion case 100
    $CacheCommands.case.Commands | Should -Be 100

    (Get-CompletionKeys '' 'case' 100).key | Should -Be @(100)
    (Get-CompletionKeys '1' 'case 1' 100).key | Should -Be @(100)
    Get-CompletionKeys '' 'case 1' 100 | Should -Be @()
    Get-CompletionKeys '2' 'case 2' 100 | Should -Be @()
    Get-CompletionKeys '' 'case 2' 100 | Should -Be @()

    Compare-Hashtable $CacheAllCompletions.case (ConvertTo-Hash 100) | Should -Be $true
    New-Completion case 1001
    $CacheCommands.case.Commands | Should -Be 100
    New-Completion case 1001 -Force
    $CacheCommands.case.Commands | Should -Be 1001
    Remove-Completion case
    $CacheCommands.case | Should -Be $null
    $CacheAllCompletions.case | Should -Be $null
  }

  It 'test number string' {
    New-Completion case '100'
    $CacheCommands.case.Commands | Should -Be '100'

    (Get-CompletionKeys '' 'case' '100').key | Should -Be @('100')
    (Get-CompletionKeys '1' 'case 1' '100').key | Should -Be @('100')
    Get-CompletionKeys '' 'case 1' '100' | Should -Be @()
    Get-CompletionKeys '2' 'case 2' '100' | Should -Be @()
    Get-CompletionKeys '' 'case 2' '100' | Should -Be @()

    Compare-Hashtable $CacheAllCompletions.case (ConvertTo-Hash '100') | Should -Be $true
    New-Completion case '1001'
    $CacheCommands.case.Commands | Should -Be '100'
    New-Completion case '1001' -Force
    $CacheCommands.case.Commands | Should -Be '1001'
    Remove-Completion case
    $CacheCommands.case | Should -Be $null
    $CacheAllCompletions.case | Should -Be $null
  }

  It 'test string' {
    New-Completion case 'world'
    $CacheCommands.case.Commands | Should -Be 'world'

    (Get-CompletionKeys '' "case" 'world').key | Should -Be @('world')
    (Get-CompletionKeys 'w' 'case w' 'world').key | Should -Be @('world')
    Get-CompletionKeys '' 'case w' 'world' | Should -Be @()
    Get-CompletionKeys 'c' 'case c' 'world' | Should -Be @()
    Get-CompletionKeys '' 'case c' 'world' | Should -Be @()

    Compare-Hashtable $CacheAllCompletions.case (ConvertTo-Hash 'world') | Should -Be $true
    New-Completion case 'world new'
    $CacheCommands.case.Commands | Should -Be 'world'
    New-Completion case 'world new' -Force
    $CacheCommands.case.Commands | Should -Be 'world new'
    Remove-Completion case
    $CacheCommands.case | Should -Be $null
    $CacheAllCompletions.case | Should -Be $null
  }

  It 'test <type>' -ForEach @(
    @{
      Type = 'js array';
      List = '["arg1","arg2","arg3"]';
      ListNew = '["arg1_new","arg2_new","arg3_new"]'
    }
    @{
      Type = 'powershell list';
      List = 'arg1','arg2','arg3';
      ListNew = 'arg1_new','arg2_new','arg3_new'
    }
  ) {
    New-Completion case $list
    $CacheCommands.case.Commands | Should -Be $list

    (Get-CompletionKeys '' 'case' $list).key | Should -Be @('arg1','arg2','arg3')
    (Get-CompletionKeys '2' 'case 2' $list).key | Should -Be @('arg2')
    Get-CompletionKeys '' 'case w' $list | Should -Be @()
    Get-CompletionKeys "c" 'case c' $list | Should -Be @()
    Get-CompletionKeys '' 'case c' $list | Should -Be @()
    (Get-CompletionKeys 'arg1' 'case arg1' $list).key | Should -Be @('arg1')
    Get-CompletionKeys '' 'case arg1' $list | Should -Be @()

    Compare-Hashtable $CacheAllCompletions.case (ConvertTo-Hash $list) | Should -Be $true
    New-Completion case $listNew
    $CacheCommands.case.Commands | Should -Be $list
    New-Completion case $listNew -Force
    $CacheCommands.case.Commands | Should -Be $listNew
    Remove-Completion case
    $CacheCommands.case | Should -Be $null
    $CacheAllCompletions.case | Should -Be $null
  }

  It 'test <type>' -ForEach @(
    @{
      Type = 'js object';
      List = '{
        arg1: "arg1_1",
        arg2: "arg2_2",
        arg3: {
          arg3_1: "arg3_1_1",
          arg3_2: "arg3_2_1"
        }
      }';
      ListNew = '{arg1: "arg1_1_new"}'
    }
    @{
      Type = 'powershell hashtable';
      List = @{
        arg1 = 'arg1_1';
        arg2 = 'arg2_2';
        arg3 = @{
          arg3_1 = 'arg3_1_1';
          arg3_2 = 'arg3_2_1'
        }
      };
      ListNew = @{arg1 = 'arg1_1_new'}
    }
  ) {
    New-Completion case $list
    $CacheCommands.case.Commands | Should -Be $list

    (Get-CompletionKeys '' 'case' $list).key | Should -Be @('arg1','arg2','arg3')
    (Get-CompletionKeys '2' 'case 2' $list).key | Should -Be @('arg2')
    Get-CompletionKeys '' 'case 2' $list | Should -Be @()
    (Get-CompletionKeys '' 'case arg3' $list).key | Should -Be @('arg3_1', 'arg3_2')
    (Get-CompletionKeys '2' 'case arg3 2' $list).key | Should -Be @('arg3_2')
    (Get-CompletionKeys '1' 'case arg3 arg3_1 1' $list).key | Should -Be @('arg3_1_1')
    Get-CompletionKeys '' 'case arg3 arg3_1 1' $list | Should -Be @()

    Compare-Hashtable $CacheAllCompletions.case (ConvertTo-Hash $list) | Should -Be $true
    New-Completion case $listNew
    $CacheCommands.case.Commands | Should -Be $list
    New-Completion case $listNew -Force
    $CacheCommands.case.Commands | Should -Be $listNew
    Remove-Completion case
    $CacheCommands.case | Should -Be $null
    $CacheAllCompletions.case | Should -Be $null
  }

  It 'test <type>' -ForEach @(
    @{
      Type = 'js object array';
      List = '{
        arg1: [
          "arg1_1",
          { arg1_2: "arg1_2_1" }
        ],
        arg2: "arg2_2",
        arg3: {
          arg3_1: ["arg3_1_1", "arg3_1_2"],
          arg3_2: "arg3_2_1"
        }
      }';
      ListNew = '{arg2: "arg2_2_new"}'
    }
    @{
      Type = 'powershell hashtable list';
      List = @{
        arg1 = 'arg1_1',@{arg1_2 = 'arg1_2_1'};
        arg2 = 'arg2_2';
        arg3 = @{
          arg3_1 = 'arg3_1_1', 'arg3_1_2';
          arg3_2 = 'arg3_2_1'
        }
      };
      ListNew = @{arg2 = 'arg2_2_new'}
    }
  ) {
    New-Completion case $list
    $CacheCommands.case.Commands | Should -Be $list

    (Get-CompletionKeys '' 'case' $list).key | Should -Be @('arg1','arg2','arg3')
    (Get-CompletionKeys '2' 'case 2' $list).key | Should -Be @('arg2')
    Get-CompletionKeys '' 'case 2' $list | Should -Be @()
    (Get-CompletionKeys '' 'case arg1' $list).key | Should -Be @('arg1_1', 'arg1_2')
    (Get-CompletionKeys '2' 'case arg1 2' $list).key | Should -Be @('arg1_2')
    (Get-CompletionKeys '' 'case arg1 arg1_2' $list).key | Should -Be @('arg1_2_1')
    (Get-CompletionKeys '1' 'case arg1 arg1_2 1' $list).key | Should -Be @('arg1_2_1')
    Get-CompletionKeys '' 'case arg1 arg1_2 1' $list | Should -Be @()
    (Get-CompletionKeys '1' 'case arg3 1' $list).key | Should -Be @('arg3_1')
    Get-CompletionKeys '' 'case arg3 1' $list | Should -Be @()
    (Get-CompletionKeys '' 'case arg3 arg3_1' $list).key | Should -Be @('arg3_1_1', 'arg3_1_2')
    (Get-CompletionKeys '2' 'case arg3 arg3_1 2' $list).key | Should -Be @('arg3_1_2')
    Get-CompletionKeys '' 'case arg3 arg3_1 2' $list | Should -Be @()

    Compare-Hashtable $CacheAllCompletions.case (ConvertTo-Hash $list) | Should -Be $true
    New-Completion case $listNew
    $CacheCommands.case.Commands | Should -Be $list
    New-Completion case $listNew -Force
    $CacheCommands.case.Commands | Should -Be $listNew
    Remove-Completion case
    $CacheCommands.case | Should -Be $null
    $CacheAllCompletions.case | Should -Be $null
  }

  It 'test <type>' -ForEach @(
    @{
      Type = 'js array object';
      List = '[
        "arg1",
        { arg2: "arg2_2" },
        ["arg3", {arg4: "arg4_1"}]
      ]';
      ListNew = '["arg1"]'
    }
    @{
      Type = 'powershell list hashtable';
      List = @(
        'arg1',
        @{ arg2 = 'arg2_2' },
        @('arg3', @{arg4 = 'arg4_1'})
      );
      ListNew = @('arg1')
    }
  ) {
    New-Completion case $list
    $CacheCommands.case.Commands | Should -Be $list

    (Get-CompletionKeys '' 'case' $list).key | Should -Be @('arg1','arg2','arg3','arg4')
    (Get-CompletionKeys '2' 'case 2' $list).key | Should -Be @('arg2')
    Get-CompletionKeys '' 'case 2' $list | Should -Be @()
    (Get-CompletionKeys '' 'case arg2' $list).key | Should -Be @('arg2_2')
    (Get-CompletionKeys '2' 'case arg2 2' $list).key | Should -Be @('arg2_2')
    Get-CompletionKeys '' 'case arg2 2' $list | Should -Be @()
    (Get-CompletionKeys '' 'case arg4' $list).key | Should -Be @('arg4_1')
    Get-CompletionKeys '' 'case arg4 2' $list | Should -Be @()

    Compare-Hashtable $CacheAllCompletions.case (ConvertTo-Hash $list) | Should -Be $true
    New-Completion case $listNew
    $CacheCommands.case.Commands | Should -Be $list
    New-Completion case $listNew -Force
    $CacheCommands.case.Commands | Should -Be $listNew
    Remove-Completion case
    $CacheCommands.case | Should -Be $null
    $CacheAllCompletions.case | Should -Be $null
  }

  It "custom filter function" {
    $list = '{
      "access": ["public", { grant: ["read-only", "read-write"] }, "edit", "--help"],
      "--help": "",
      "add": ["--help"]
    }'
    New-Completion case $list -filter {
      Param($Keys, $Word)
      $Keys | Where-Object { $_ -Like "*$Word*" } | Sort-Object -Descending
    }
    $CacheCommands.case.Commands | Should -Be $list
    $CacheCommands.case.Filter.ToString() | Should -Be ({
      Param($Keys, $Word)
      $Keys | Where-Object { $_ -Like "*$Word*" } | Sort-Object -Descending
    }).ToString()

    (Get-CompletionKeys '' 'case' $list).key | Should -Be @('access','add','--help')
    (Get-CompletionKeys 'g' 'case access g' $list).key | Should -Be @('grant')
    (Get-CompletionKeys '' 'case access grant' $list).key | Should -Be @('read-only','read-write')
    (Get-CompletionKeys 't' 'case access t' $list).key | Should -Be @('edit','grant')
    Get-CompletionKeys '' 'case access t' $list | Should -Be @()

    Compare-Hashtable $CacheAllCompletions.case (ConvertTo-Hash $list) | Should -Be $true
    Remove-Completion case
    $CacheCommands.case | Should -Be $null
    $CacheAllCompletions.case | Should -Be $null
  }

  It "custom where function" {
    $list = '{
      "access": ["public", { grant: ["read-only", "read-write"] }, "edit", "--help"],
      "--help": "",
      "add": ["--help"]
    }'
    $where = {
      Param($Keys, $Word)
      $Keys | Where-Object { $_.Key -Like "*$Word*" }
    }
    New-Completion case $list -Where $where
    $CacheCommands.case.Commands | Should -Be $list
    $CacheCommands.case.Where.ToString() | Should -Be $where.ToString()

    (Get-CompletionKeys '' 'case' $list -Where $where).key | Should -Be @('access','add','--help')

    $where = {
      Param($Keys, $Word)
      $Keys | Where-Object {
        if ($Word) {
          $_.Key.StartsWith($Word)
        } else {
          -not $_.Key.StartsWith('-')
        }
      }
    }
    (Get-CompletionKeys '' 'case' $list -Where $where).key | Should -Be @('access', 'add')
    (Get-CompletionKeys 'c' 'case c' $list -Where $where).key | Should -Be @()
    (Get-CompletionKeys 'g' 'case access g' $list -Where $where).key | Should -Be @('grant')
    (Get-CompletionKeys '-' 'case -' $list -Where $where).key | Should -Be @('--help')

    Remove-Completion case
    $CacheCommands.case | Should -Be $null
  }
  
  It "custom sort function" {
    $list = '["arg1", "arg2", "--help", "--set", "arg3", "--get", "arg4"]'
    $sort = {
      Param($Keys)
      $Keys | Sort-Object -Property `
        @{Expression = { $_.Key.ToString().StartsWith('-') }; Descending = $false }, `
        @{Expression = { $_.Key }; Descending = $true}
    }
    New-Completion case $list
    $CacheCommands.case.Commands | Should -Be $list
    $CacheCommands.case.Sort | Should -Be $null

    (Get-CompletionKeys '' 'case' $list).key | Should -Be @('arg1', 'arg2', 'arg3', 'arg4', '--get', '--help', '--set')

    New-Completion case $list -Sort $sort -Force
    $CacheCommands.case.Sort.ToString() | Should -Be $sort.ToString()
    (Get-CompletionKeys '' 'case' $list -Sort $sort).key | Should -Be @('arg4', 'arg3', 'arg2', 'arg1', '--set', '--help', '--get')

    Remove-Completion case
    $CacheCommands.case | Should -Be $null
  }

  It "custom default sort" {
    $list = '["arg1", "arg2", "--help", "--set", "arg3", "--get", "arg4"]'
    New-Completion case $list -DefaultSort $false
    $CacheCommands.case.Commands | Should -Be $list
    $CacheCommands.case.Sort | Should -Be $null
    $arr = Get-CompletionKeys '' 'case' $list
    $arr.key | Should -Be @('arg1', 'arg2', 'arg3', 'arg4', '--get', '--help', '--set')

    $arr = Get-CompletionKeys 'g' 'case g' $list
    $arr.key | Should -Be @('arg1', 'arg2', 'arg3', 'arg4', '--get')

    Remove-Completion case
    $CacheCommands.case | Should -Be $null
  }
}
