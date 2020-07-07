{ stdenv, fetchFromGitHub, autoconf
, zlib
, python
, perl
, gettext
, git
, mercurial
, curl
}:

# NOTE: git-cinnabar depends on a specific version of git-core, thus you should
# ensure that you install a git-cinnabar version which matches your git version.
#
# NOTE: This package only provides git-cinnabar tools, as a git users might want
# to have additional commands not provided by this forked version of git-core.
stdenv.mkDerivation rec {
  version = "0.5.4";
  name = "git-cinnabar-${version}";
  src = fetchFromGitHub {
    owner = "glandium";
    repo = "git-cinnabar";
    inherit name;
    rev = version; # tag name
    fetchSubmodules = true;
    sha256 = "1cjn2cc6mj4m736wxab9s6qx83p5n5ha8cr3x84s9ra6rxs8d7pi";
  };
  buildInputs = [ autoconf python gettext git curl ];

  ZLIB_PATH = zlib;
  ZLIB_DEV_PATH = zlib.dev;

  PERL_PATH = "${perl}/bin/perl";
  NO_TCLTK = true;
  V=1;

  preBuild = ''
    export ZLIB_PATH;
    export ZLIB_DEV_PATH;
    substituteInPlace git-core/Makefile --replace \
      '$(ZLIB_PATH)/include' '$(ZLIB_DEV_PATH)/include'
    # Comment out calls to git to try to verify that git-core is up to date
    substituteInPlace Makefile \
      --replace '$(eval $(call exec,git' '# $(eval $(call exec,git'


    export PERL_PATH;
    export NO_TCLTK
    export V;
  '';

  makeFlags = "prefix=\${out}";

  installTargets = "git-install";

  postInstall =
    let mercurial-py = mercurial + "/" + mercurial.python.sitePackages; in ''
    # git-cinnabar rebuild git, we do not need that.
    rm -rf $out/bin/* $out/share $out/lib
    for f in $out/libexec/git-core/{git-remote-hg,git-cinnabar} ; do
      substituteInPlace $f --replace \
        "sys.path.append(os.path.join(os.path.dirname(__file__), 'pythonlib'))" \
        "sys.path.extend(['$out/libexec/git-core/pythonlib', '${mercurial-py}'])"
      mv $f $out/bin
    done
    mv $out/libexec/git-core/git-cinnabar-helper $out/bin/git-cinnabar-helper
    mv $out/libexec/git-core/pythonlib $out/pythonlib
    rm -rf $out/libexec/git-core/*
    mv $out/pythonlib $out/libexec/git-core/pythonlib
    substituteInPlace $out/libexec/git-core/pythonlib/cinnabar/helper.py \
      --replace 'Git.config('cinnabar.helper')' "Git.config('cinnabar.helper') or '$out/bin/git-cinnabar-helper'"
  '';
}
