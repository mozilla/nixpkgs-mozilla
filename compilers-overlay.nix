# This overlays add a customStdenv attribute which provide an stdenv with
# different versions of the compilers. This can be used to test Gecko builds
# against different compiler settings, or different compiler versions.
#
# See release.nix "builder" function, to understand how these different stdenv
# are used.
self: super: 

let
  noSysDirs = (super.stdenv.system != "x86_64-darwin"
             && super.stdenv.system != "x86_64-freebsd"
             && super.stdenv.system != "i686-freebsd"
             && super.stdenv.system != "x86_64-kfreebsd-gnu");
  crossSystem = null;

  gcc473 = super.wrapCC (super.callPackage ./pkgs/gcc-4.7 (with self; {
    inherit noSysDirs;
    texinfo = texinfo4;
    # I'm not sure if profiling with enableParallelBuilding helps a lot.
    # We can enable it back some day. This makes the *gcc* builds faster now.
    profiledCompiler = false;

    # When building `gcc.crossDrv' (a "Canadian cross", with host == target
    # and host != build), `cross' must be null but the cross-libc must still
    # be passed.
    cross = null;
    libcCross = if crossSystem != null then libcCross else null;
    libpthreadCross =
      if crossSystem != null && crossSystem.config == "i586-pc-gnu"
      then gnu.libpthreadCross
      else null;
  }));

  # By default wrapCC keep the same header files, but NixOS is using the
  # latest header files from GCC, which are not supported by clang, because
  # clang implement a different set of locking primitives than GCC.  This
  # expression is used to wrap clang with a matching verion of the libc++.
  maybeWrapClang = cc:
    if cc ? clang
    then clangWrapCC cc
    else cc;

  clangWrapCC = llvmPackages:
    let libcxx =
      super.lib.overrideDerivation llvmPackages.libcxx (drv: {
        # https://bugzilla.mozilla.org/show_bug.cgi?id=1277619
        # https://llvm.org/bugs/show_bug.cgi?id=14435
        patches = drv.patches ++ [ ./pkgs/clang/bug-14435.patch ];
      });
    in
    super.callPackage <nixpkgs/pkgs/build-support/cc-wrapper> {
      cc = llvmPackages.clang-unwrapped or llvmPackages.clang;
      isClang = true;
      stdenv = self.clangStdenv;
      libc = self.glibc;
      # cc-wrapper pulls gcc headers, which are not compatible with features
      # implemented in clang.  These packages are used to override that.
      extraPackages = [ self.libcxx llvmPackages.libcxxabi ];
      nativeTools = false;
      nativeLibc = false;
    };

  buildWithCompiler = cc:
    super.stdenvAdapters.overrideCC self.stdenv (maybeWrapClang cc);
  chgCompilerSource = cc: name: src:
    cc.override (conf:
      if conf ? gcc then # Nixpkgs 14.12
        { gcc = super.lib.overrideDerivation conf.gcc (old: { inherit name src; }); }
      else # Nixpkgs 15.05
        { cc = super.lib.overrideDerivation conf.cc (old: { inherit name src; }); }
    );

  compilersByName = with self; {
    clang = llvmPackages;
    clang36 = llvmPackages_36;
    clang37 = llvmPackages_37;
    clang38 = llvmPackages_38; # not working yet.
    gcc = gcc;
    gcc49 = gcc49;
    gcc48 = gcc48;
    gcc474 = chgCompilerSource gcc473 "gcc-4.7.4" (fetchurl {
      url = "mirror://gnu/gcc/gcc-4.7.4/gcc-4.7.4.tar.bz2";
      sha256 = "10k2k71kxgay283ylbbhhs51cl55zn2q38vj5pk4k950qdnirrlj";
    });
    gcc473 = gcc473;
    # Version used on Linux slaves, except Linux x64 ASAN.
    gcc472 = chgCompilerSource gcc473 "gcc-4.7.2" (fetchurl {
      url = "mirror://gnu/gcc/gcc-4.7.2/gcc-4.7.2.tar.bz2";
      sha256 = "115h03hil99ljig8lkrq4qk426awmzh0g99wrrggxf8g07bq74la";
    });
  };

in {
  customStdenvs =
    super.lib.mapAttrs (name: value: buildWithCompiler value) compilersByName;
}
