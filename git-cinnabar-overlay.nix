final: prev:

{
  git-cinnabar = prev.callPackage ./pkgs/git-cinnabar {
    # we need urllib to recognize ssh.
    # python = final.pythonFull;
    python = final.mercurial.python;
  };
}
