# To pin a specific version of nixpkgs, change the nixpkgsSrc argument.
{ nixpkgsSrc ? <nixpkgs>
, supportedSystems ? [ "x86_64-linux" "i686-linux" /* "x86_64-darwin" */ ]
}:

let
  lib = (import nixpkgsSrc {}).lib;

  # Make an attribute set for each system, the builder is then specialized to
  # use the selected system.
  forEachSystem = systems: builder /* system -> stdenv -> pkgs */:
    lib.genAttrs systems builder;

  # Make an attribute set for each compiler, the builder is then be specialized
  # to use the selected compiler.
  forEachCompiler = compilers: builder: system:
    builtins.listToAttrs (map (compiler: {
      name = compiler;
      value = builder compiler system;
    }) compilers);


  # Overide the previous derivation, with a different stdenv.
  builder = path: compiler: system:
    lib.getAttrFromPath path (import nixpkgsSrc {
      inherit system;
      overlays = [
        # Add all packages from nixpkgs-mozilla.
        (import ./default.nix)

        # Define customStdenvs, which is a set of various compilers which can be
        # used to compile the given package against.
        (import ./compilers-overlay.nix)

        # Use the following overlay to override the requested package from
        # nixpkgs, with a custom stdenv taken from the compilers-overlay.
        (self: super:
          if compiler == null then {}
          else lib.setAttrByPath path ((lib.getAttrFromPath path super).override {
            stdenv = self.customStdenvs."${compiler}";
          }))
      ];
    });

  build = path: { systems ? supportedSystems, compilers ? null }:
    forEachSystem systems (
      if compilers == null
      then builder path null
      else forEachCompiler compilers (builder path)
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
    #   $ nix-shell release.nix -A gecko.i686-linux.gcc --pure --command '$CC --version'
    #   $ nix-shell release.nix -A gecko.x86_64-linux.clang --pure
    #
    # As some of the test script of Gecko are checking against absolute path, a
    # fake-FHS is provided for Gecko.  It can be accessed by appending
    # ".fhs.env" behind the previous commands:
    #
    #   $ nix-shell release.nix -A gecko.x86_64-linux.gcc.fhs.env
    #
    # Which will spawn a new shell where the closure of everything used to build
    # Gecko would be part of the fake-root.
    gecko = build [ "devEnv" "gecko" ] { compilers = geckoCompilers; };
    servo = build [ "servo" ];
    VidyoDesktop = build [ "VidyoDesktop" ];
  };

in jobs
