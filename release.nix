{ nixpkgsSrc ? <nixpkgs>
, supportedSystems ? [ "x86_64-linux" "i686-linux" /* "x86_64-darwin" */ ]
}:

let

  # import current system nixpkgs's
  pkgs' = import nixpkgsSrc {};

  # Make an attribute set for each system, the builder is then specialized to
  # use the selected system.
  forEachSystem = systems: builder:
    pkgs'.lib.genAttrs systems (system:
      builder (import nixpkgsSrc { inherit system; })
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

    buildWithCompiler = cc: builderWithStdenv (stdenvAdapters.overrideCC stdenv cc);
    chgCompilerSource = cc: name: src:
      cc.override (conf:
        if conf ? gcc then # Nixpkgs 14.12
          { gcc = lib.overrideDerivation conf.gcc (old: { inherit name src; }); }
        else # Nixpkgs 15.05
          { cc = lib.overrideDerivation conf.cc (old: { inherit name src; }); }
      );

    compilersByName = {
      clang = clang;
      # clang33 = clang_33  # not present in nixpkgs
      clang34 = clang_34;
      clang35 = clang_35;
      clang36 = clang_36;
      clang37 = clang_37;
      clang38 = clang_38;
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
    "clang33"
    "clang34"
    "clang35"
    "gcc"
    "gcc49"
    "gcc48"
    "gcc474"
    "gcc473"
    "gcc472"
  ];

  jobs = rec {

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

in
  jobs
