Describe 'Makefile'
  Describe 'exists'
    It 'Verifies that the Makefile exists'
      The path 'Makefile' should be exist
    End
  End
  # Intended tests I'm unsure how to write in ShellSpec yet:
  #     * “make test” runs ShellSpec test suite whether or not ShellSpec exists
  #     * “make test” downloads ShellSpec if it doesn’t exist
  #     * ShellSpec download fails if git doesn’t exist
  #     * ShellSpec download fails is neither wget nor curl exist
  #     * ShellSpec download initiated if curl but not wget exists
  #     * ShellSpec download initiated if wget but not curl exists
  #     * If curl download fails, make fails
  #     * If wget download fails, make fails
End
