let
  _pkgs = import <nixpkgs> {};
  _nixpkgs = _pkgs.fetchFromGitHub (_pkgs.lib.importJSON ./pkgs/nixpkgs.json);
in

{ nixpkgsSrc ? _nixpkgs
, supportedSystems ? [ "x86_64-linux" "i686-linux" /* "x86_64-darwin" */ ]
}:

let
  # Make an attribute set for each system, the builder is then specialized to
  # use the selected system.
  forEachSystem = systems: builder:
    _pkgs.lib.genAttrs systems (system:
      builder (import _nixpkgs { inherit system; })
    );

  # Make an attribute set for each compiler, the builder is then be specialized
  # to use the selected compiler.
  forEachCompiler = compilers: builder: pkgs:
    with pkgs;
    let

    # Override, in a non-recursive matter to avoid recompilations, the standard
    # environment used for building packages.
    builderWithStdenv = stdenv: builder (pkgs // { inherit stdenv; });

    noSysDirs = (system != "x86_64-darwin"
               && system != "x86_64-freebsd" && system != "i686-freebsd"
               && system != "x86_64-kfreebsd-gnu");
    crossSystem = null;

    gcc473 = wrapCC (callPackage ./pkgs/gcc-4.7 {
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
    });

    # By default wrapCC keep the same header files, but NixOS is using the
    # latest header files from GCC, which are not supported by clang, because
    # clang implement a different set of locking primitives than GCC.  This
    # expression is used to wrap clang with a matching verion of the libc++.
    maybeWrapClang = cc:
      if cc ? clang then clangWrapCC cc
      else cc;
    clangWrapCC = llvmPackages:
      let libcxx =
        pkgs.lib.overrideDerivation llvmPackages.libcxx (drv: {
          # https://bugzilla.mozilla.org/show_bug.cgi?id=1277619
          # https://llvm.org/bugs/show_bug.cgi?id=14435
          patches = drv.patches ++ [ ./pkgs/clang/bug-14435.patch ];
        });
      in
      callPackage <nixpkgs/pkgs/build-support/cc-wrapper> {
        cc = llvmPackages.clang-unwrapped or llvmPackages.clang;
        isClang = true;
        stdenv = clangStdenv;
        libc = glibc;
        # cc-wrapper pulls gcc headers, which are not compatible with features
        # implemented in clang.  These packages are used to override that.
        extraPackages = [ libcxx llvmPackages.libcxxabi ];
        nativeTools = false;
        nativeLibc = false;
      };

    buildWithCompiler = cc: builderWithStdenv
      (stdenvAdapters.overrideCC stdenv (maybeWrapClang cc));
    chgCompilerSource = cc: name: src:
      cc.override (conf:
        if conf ? gcc then # Nixpkgs 14.12
          { gcc = lib.overrideDerivation conf.gcc (old: { inherit name src; }); }
        else # Nixpkgs 15.05
          { cc = lib.overrideDerivation conf.cc (old: { inherit name src; }); }
      );

    compilersByName = {
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

  in builtins.listToAttrs (map (x: { name = x; value = buildWithCompiler (builtins.getAttr x compilersByName); }) compilers);

  build = name: { systems ? supportedSystems, compilers ? null }:
    forEachSystem systems (
      let 
        builder = pkgs: builtins.getAttr name (import ./default.nix { inherit pkgs; });
      in
        if compilers == null
        then builder
        else forEachCompiler compilers builder
    );

  geckoCompilers = [
    "clang"
    "clang36"
    "clang37"
    "clang38"
    "gcc"
    "gcc49"
    "gcc48"
    #"gcc474"
    #"gcc473"
    #"gcc472"
  ];

  jobs = {

    # For each system, and each compiler, create an attribute with the name of
    # the system and compiler. Use this attribute name to select which
    # environment you are interested in for building firefox.  These can be
    # build using the following command:
    #
    #   $ nix-build release.nix -A gecko.x86_64-linux.clang -o firefox-x64
    #   $ nix-build release.nix -A gecko.i686-linux.gcc48 -o firefox-x86
    #
    # If you are only interested in getting a build environment, the use the
    # nix-shell command instead, which will skip the copy of Firefox sources,
    # and pull the the dependencies needed for building firefox with this
    # environment.
    #
    #   $ nix-shell release.nix -A gecko.i686-linux.gcc472 --pure --command 'gcc --version'
    #   $ nix-shell release.nix -A gecko.x86_64-linux.clang --pure
    #
    gecko = build "gecko" { compilers = geckoCompilers; };
    servo = build "servo";
    VidyoDesktop = build "VidyoDesktop";
  };

in jobs
