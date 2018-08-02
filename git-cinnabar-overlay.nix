self: super:

{
  git-cinnabar = super.callPackage ./pkgs/git-cinnabar {
    # we need urllib to recognize ssh.
    # python = self.pythonFull;
    python = self.mercurial.python;
  };
}
