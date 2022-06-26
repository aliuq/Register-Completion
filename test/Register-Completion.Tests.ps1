BeforeAll {
  . "$pwd\src\Register-Completion.ps1"

  $hash_object = "
    {
      'arg1': 'arg1_1',
      'arg2': 'arg2_2',
      'arg3': {
        'arg3_1': 'arg3_1_1',
        'arg3_2': 'arg3_2_1'
      }
    }
  "
}

Describe "Register-Completion" {
  Context "Test function - Convert-JsonToHash" {
    It "Convert string to <type>" -ForEach @(
      @{ type = 'number'; src = "100"; expected = 1001 }
      @{ type = 'string'; src = "World"; expected = "World" }
      @{ type = 'array'; src = "['arg1','arg2','arg3']"; expected = "arg1","arg2","arg3" }
    ) {
      Convert-JsonToHash $src | Should -Be $expected
    }
    It "Convert string to hashtable" {
      $res = Convert-JsonToHash $hash_object
      $res | Should -BeOfType System.Collections.Hashtable
      $res.Keys | Should -BeIn "arg1", "arg2", "arg3"
    }
  }

  Context "Test function - Get-CompletionKeys" {
    It "Typing '<ast>' should complete '<expected>'" -ForEach @(
      @{ word = ""; ast = "test_number "; list = "100"; "expected" = @(100) }
      @{ word = "1"; ast = "test_number 1"; list = "100"; "expected" = @(100) }
      @{ word = "2"; ast = "test_number 2"; list = "100"; "expected" = @() }
      @{ word = ""; ast = "test_string "; list = "world"; "expected" = @("world") }
      @{ word = "d"; ast = "test_string d"; list = "world"; "expected" = @("world") }
      @{ word = "c"; ast = "test_string c"; list = "world"; "expected" = @() }
      @{ word = ""; ast = "test_array "; list = "['arg1','arg2','arg3']"; "expected" = @('arg1','arg2','arg3') }
      @{ word = "2"; ast = "test_array 2"; list = "['arg1','arg2','arg3']"; "expected" = @('arg2') }
      @{ word = "x"; ast = "test_array x"; list = "['arg1','arg2','arg3']"; "expected" = @() }
    ) {
      Get-CompletionKeys $word $ast $list | Should -Be $expected
    }

    It "Typing 'test_object ' should return completion @('arg1','arg2','arg3')" {
      Get-CompletionKeys "" "test_object " $hash_object | Should -Be 'arg1','arg2','arg3'
    }

    It "Typing 'test_object 2' should return completion @('arg2')" {
      Get-CompletionKeys "2" "test_object 2" $hash_object | Should -Be 'arg2'
    }

    It "Typing 'test_object arg2 ' should return completion @('arg2_2')" {
      Get-CompletionKeys "arg2" "test_object arg2 " $hash_object | Should -Be 'arg2_2'
    }

    It "Typing 'test_object arg2' should return completion @('arg2')" {
      Get-CompletionKeys "arg2" "test_object arg2" $hash_object | Should -Be 'arg2'
    }

    It "Typing 'test_object arg3 ' should return completion @('arg3_1','arg3_2')" {
      Get-CompletionKeys "arg3" "test_object arg3 " $hash_object | Should -Be 'arg3_1','arg3_2'
    }

    It "Typing 'test_object arg3 2' should return completion @('arg3_2')" {
      Get-CompletionKeys "2" "test_object arg3 2" $hash_object | Should -Be 'arg3_2'
    }

    It "Typing 'test_object arg3 arg3_2 ' should return completion @('arg3_2_1')" {
      Get-CompletionKeys "arg3_2" "test_object arg3 arg3_2 " $hash_object | Should -Be 'arg3_2_1'
    }

    It "Typing 'test_object arg2 4' should return completion @()" {
      Get-CompletionKeys "4" "test_object arg2 4" $hash_object | Should -Be @()
    }
  }

  Context "Test function - Register-Completion" {
    It "register completion rc_number" {
      Register-Completion rc_number "100"
      $list = $cache_command_list["rc_number"]

      Get-CompletionKeys "" "rc_number " $list | Should -Be @(100)
      Get-CompletionKeys "1" "rc_number 1" $list | Should -Be @(100)
      Get-CompletionKeys "1" "rc_number 1 " $list | Should -Be @()
      Get-CompletionKeys "2" "rc_number 2" $list | Should -Be @()
      Get-CompletionKeys "2" "rc_number 2 " $list | Should -Be @()
    }

    It "register completion rc_string" {
      Register-Completion rc_string "world"
      $list = $cache_command_list["rc_string"]

      Get-CompletionKeys "" "rc_string " $list | Should -Be @("world")
      Get-CompletionKeys "d" "rc_string d" $list | Should -Be @("world")
      Get-CompletionKeys "d" "rc_string d " $list | Should -Be @()
      Get-CompletionKeys "c" "rc_string c" $list | Should -Be @()
      Get-CompletionKeys "c" "rc_string c " $list | Should -Be @()
    }

    It "register completion rc_array" {
      Register-Completion rc_array "['arg1','arg2','arg3']"
      $list = $cache_command_list["rc_array"]

      Get-CompletionKeys "" "rc_array " $list | Should -Be @("arg1","arg2","arg3")
      Get-CompletionKeys "2" "rc_array 2" $list | Should -Be @("arg2")
      Get-CompletionKeys "2" "rc_array 2 " $list | Should -Be @()
      Get-CompletionKeys "x" "rc_array x" $list | Should -Be @()
      Get-CompletionKeys "x" "rc_array x " $list | Should -Be @()
    }

    It "register completion rc_object" {
      Register-Completion rc_object $hash_object
      $list = $cache_command_list["rc_object"]

      Get-CompletionKeys "" "rc_object " $list | Should -Be @("arg1","arg2","arg3")
      Get-CompletionKeys "2" "rc_object 2" $list | Should -Be @("arg2")
      Get-CompletionKeys "arg2" "rc_object arg2 " $list | Should -Be @("arg2_2")
      Get-CompletionKeys "arg2" "rc_object arg2" $list | Should -Be @("arg2")
      Get-CompletionKeys "arg3" "rc_object arg3 " $list | Should -Be @("arg3_1","arg3_2")
      Get-CompletionKeys "arg3_2" "rc_object arg3 arg3_2 " $list | Should -Be @("arg3_2_1")
      Get-CompletionKeys "4" "rc_object arg3 arg3_2 4" $list | Should -Be @()
    }
  }
}
