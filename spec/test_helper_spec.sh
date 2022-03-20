Describe 'lib/test_helper.sh'
  Describe 'exists'
    It 'Verifies that the lib/test_helper.sh exists'
      The path 'lib/test_helper.sh' should be exist
    End
  End
  Include lib/test_helper.sh
  Describe 'func mk_tmp_test_dir'
    It 'Verifies that mk_tmp_test_dir is defined as a command'
      When call mk_tmp_test_dir
      The output should eq ''
      # More here, but not familiar enough with ShellSpec yet.
    End
  End
End
