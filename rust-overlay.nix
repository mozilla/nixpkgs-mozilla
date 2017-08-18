# This file provide a Rust overlay, which provides pre-packaged bleeding edge versions of rustc
# and cargo.
self: super:

let
  fromTOML = (import ./lib/parseTOML.nix).fromTOML;

  # See https://github.com/rust-lang-nursery/rustup.rs/blob/master/src/rustup-dist/src/dist.rs
  defaultDistRoot = "https://static.rust-lang.org";
  manifest_v1_url = {
    dist_root ? defaultDistRoot + "/dist",
    date ? null,
    staging ? false,
    # A channel can be "nightly", "beta", "stable", "\d{1}.\d{1}.\d{1}", or "\d{1}.\d{2\d{1}".
    channel ? "nightly"
  }:
    if date == null && staging == false
    then "${dist_root}/channel-rust-${channel}"
    else if date != null && staging == false
    then "${dist_root}/${date}/channel-rust-${channel}"
    else if date == null && staging == true
    then "${dist_root}/staging/channel-rust-${channel}"
    else throw "not a real-world case";

  manifest_v2_url = args: (manifest_v1_url args) + ".toml";

  # Intersection of rustup-dist/src/dist.rs listed platforms and stdenv/default.nix.
  hostTripleOf = system: { # switch
    "i686-linux"      = "i686-unknown-linux-gnu";
    "x86_64-linux"    = "x86_64-unknown-linux-gnu";
    "armv5tel-linux"  = "arm-unknown-linux-gnueabi";
    "armv6l-linux"    = "arm-unknown-linux-gnueabi";
    "armv7l-linux"    = "armv7-unknown-linux-gnueabihf";
    "aarch64-linux"   = "aarch64-unknown-linux-gnu";
    "mips64el-linux"  = "mips64el-unknown-linux-gnuabi64";
    "x86_64-darwin"   = "x86_64-apple-darwin";
    "i686-cygwin"     = "i686-pc-windows-gnu"; # or msvc?
    "x86_64-cygwin"   = "x86_64-pc-windows-gnu"; # or msvc?
    "x86_64-freebsd"  = "x86_64-unknown-freebsd";
  }.${system} or (throw "Rust overlay does not support ${system} yet.");

  getComponentsWithFixedPlatform = pkgs: pkgname: stdenv:
    let
      pkg = pkgs.${pkgname};
      srcInfo = pkg.target.${hostTripleOf stdenv.system} or pkg.target."*";
      components = srcInfo.components or [];
      componentNamesList =
        builtins.map (pkg: pkg.pkg) (builtins.filter (pkg: (pkg.target != "*")) components);
    in
      componentNamesList;

  getExtensions = pkgs: pkgname: stdenv:
    let
      inherit (super.lib) unique;
      pkg = pkgs.${pkgname};
      srcInfo = pkg.target.${hostTripleOf stdenv.system} or pkg.target."*";
      extensions = srcInfo.extensions or [];
      extensionNamesList = unique (builtins.map (pkg: pkg.pkg) extensions);
    in
      extensionNamesList;

  hasTarget = pkgs: pkgname: target:
    pkgs ? ${pkgname}.target.${target};

  getTuples = pkgs: name: targets:
    builtins.map (target: { inherit name target; }) (builtins.filter (target: hasTarget pkgs name target) targets);

  # In the manifest, a package might have different components which are bundled with it, as opposed as the extensions which can be added.
  # By default, a package will include the components for the same architecture, and offers them as extensions for other architectures.
  #
  # This functions returns a list of { name, target } attribute sets, which includes the current system package, and all its components for the selected targets.
  # The list contains the package for the pkgTargets as well as the packages for components for all compTargets
  getTargetPkgTuples = pkgs: pkgname: pkgTargets: compTargets: stdenv:
    let
      inherit (builtins) elem;
      inherit (super.lib) intersectLists;
      components = getComponentsWithFixedPlatform pkgs pkgname stdenv;
      extensions = getExtensions pkgs pkgname stdenv;
      compExtIntersect = intersectLists components extensions;
      tuples = (getTuples pkgs pkgname pkgTargets) ++ (builtins.map (name: getTuples pkgs name compTargets) compExtIntersect);
    in
      tuples;

  getFetchUrl = pkgs: pkgname: target: stdenv: fetchurl:
    let
      pkg = pkgs.${pkgname};
      srcInfo = pkg.target.${target};
    in
      (super.fetchurl { url = srcInfo.url; sha256 = srcInfo.hash; });

  checkMissingExtensions = pkgs: pkgname: stdenv: extensions:
    let
      inherit (builtins) head;
      inherit (super.lib) concatStringsSep subtractLists;
      availableExtensions = getExtensions pkgs pkgname stdenv;
      missingExtensions = subtractLists availableExtensions extensions;
      extensionsToInstall =
        if missingExtensions == [] then extensions else throw ''
          While compiling ${pkgname}: the extension ${head missingExtensions} is not available.
          Select extensions from the following list:
          ${concatStringsSep "\n" availableExtensions}'';
    in
      extensionsToInstall;

  getSrcs = pkgs: pkgname: targets: extensions: targetExtensions: stdenv: fetchurl:
    let
      inherit (builtins) head map;
      inherit (super.lib) flatten remove subtractLists unique;
      targetExtensionsToInstall = checkMissingExtensions pkgs pkgname stdenv targetExtensions;
      extensionsToInstall = checkMissingExtensions pkgs pkgname stdenv extensions;
      hostTargets = [ "*" (hostTripleOf stdenv.system)];
      pkgTuples = flatten (getTargetPkgTuples pkgs pkgname hostTargets targets stdenv);
      extensionTuples = flatten (map (name: getTargetPkgTuples pkgs name hostTargets targets stdenv) extensionsToInstall);
      targetExtensionTuples = flatten (map (name: getTargetPkgTuples pkgs name targets targets stdenv) targetExtensionsToInstall);
      pkgsTuples = pkgTuples ++ extensionTuples ++ targetExtensionTuples;
      missingTargets = subtractLists (map (tuple: tuple.target) pkgsTuples) (remove "*" targets);
      pkgsTuplesToInstall =
        if missingTargets == [] then pkgsTuples else throw ''
          While compiling ${pkgname}: the target ${head missingTargets} is not available for any package.'';
    in
      map (tuple: (getFetchUrl pkgs tuple.name tuple.target stdenv fetchurl)) pkgsTuplesToInstall;

  # Manifest files are organized as follow:
  # { date = "2017-03-03";
  #   pkg.cargo.version= "0.18.0-nightly (5db6d64 2017-03-03)";
  #   pkg.cargo.target.x86_64-unknown-linux-gnu = {
  #     available = true;
  #     hash = "abce..."; # sha256
  #     url = "https://static.rust-lang.org/dist/....tar.gz";
  #   };
  # }
  #
  # The packages available usually are:
  #   cargo, rust-analysis, rust-docs, rust-src, rust-std, rustc, and
  #   rust, which aggregates them in one package.
  #
  # For each package the following options are available:
  #   extensions        - The extensions that should be installed for the package.
  #                       For example, install the package rust and add the extension rust-src.
  #   targets           - The package will always be installed for the host system, but with this option
  #                       extra targets can be specified, e.g. "mips-unknown-linux-musl". The target
  #                       will only apply to components of the package that support being installed for
  #                       a different architecture. For example, the rust package will install rust-std
  #                       for the host system and the targets.
  #   targetExtensions  - If you want to force extensions to be installed for the given targets, this is your option.
  #                       All extensions in this list will be installed for the target architectures.
  #                       *Attention* If you want to install an extension like rust-src, that has no fixed architecture (arch *),
  #                       you will need to specify this extension in the extensions options or it will not be installed!
  fromManifestFile = manifest: { stdenv, fetchurl, patchelf }:
    let
      inherit (builtins) elemAt;
      inherit (super) makeOverridable;
      inherit (super.lib) flip mapAttrs;
      pkgs = fromTOML (builtins.readFile manifest);
    in
    flip mapAttrs pkgs.pkg (name: pkg:
      makeOverridable ({extensions, targets, targetExtensions}:
        let
          version' = builtins.match "([^ ]*) [(]([^ ]*) ([^ ]*)[)]" pkg.version;
          version = "${elemAt version' 0}-${elemAt version' 2}-${elemAt version' 1}";
          srcs = getSrcs pkgs.pkg name targets extensions targetExtensions stdenv fetchurl;
        in
          stdenv.mkDerivation {
            name = name + "-" + version;
            inherit srcs;
            sourceRoot = ".";
            # (@nbp) TODO: Check on Windows and Mac.
            # This code is inspired by patchelf/setup-hook.sh to iterate over all binaries.
            installPhase = ''
              for i in * ; do
                if [ -d "$i" ]; then
                  cd $i
                  patchShebangs install.sh
                  CFG_DISABLE_LDCONFIG=1 ./install.sh --prefix=$out --verbose
                  cd ..
                fi
              done

              setInterpreter() {
                local dir="$1"
                [ -e "$dir" ] || return 0

                header "Patching interpreter of ELF executables and libraries in $dir"
                local i
                while IFS= read -r -d ''$'\0' i; do
                  if [[ "$i" =~ .build-id ]]; then continue; fi
                  if ! isELF "$i"; then continue; fi
                  echo "setting interpreter of $i"
                  patchelf --set-interpreter "$(cat $NIX_CC/nix-support/dynamic-linker)" "$i" || true
                done < <(find "$dir" -type f -print0)
              }

              setInterpreter $out
            '';

            postFixup = ''
              # Function moves well-known files from etc/
              handleEtc() {
                local oldIFS="$IFS"

                # Directories we are aware of, given as substitution lists
                for paths in \
                  "etc/bash_completion.d","share/bash_completion/completions","etc/bash_completions.d","share/bash_completions/completions";
                  do
                  # Some directoties may be missing in some versions. If so we just skip them.
                  # See https://github.com/mozilla/nixpkgs-mozilla/issues/48 for more infomation.
                  if [ ! -e $paths ]; then continue; fi

                  IFS=","
                  set -- $paths
                  IFS="$oldIFS"

                  local orig_path="$1"
                  local wanted_path="$2"

                  # Rename the files
                  if [ -d ./"$orig_path" ]; then
                    mkdir -p "$(dirname ./"$wanted_path")"
                  fi
                  mv -v ./"$orig_path" ./"$wanted_path"

                  # Fail explicitly if etc is not empty so we can add it to the list and/or report it upstream
                  rmdir ./etc || {
                    echo Installer tries to install to /etc:
                    find ./etc
                    exit 1
                  }
                done
              }

              if [ -d "$out"/etc ]; then
                pushd "$out"
                handleEtc
                popd
              fi
            '';

            # Add the compiler as part of the propagated build inputs in order
            # to run:
            #
            #    $ nix-shell -p rustChannels.stable.rust
            #
            # And get a fully working Rust compiler, with the stdenv linker.
            propagatedBuildInputs = [ stdenv.cc ];
          }
      ) { extensions = []; targets = []; targetExtensions = []; }
    );

  fromManifest = manifest: { stdenv, fetchurl, patchelf }:
    fromManifestFile (builtins.fetchurl manifest) { inherit stdenv fetchurl patchelf; };

in

rec {
  lib = super.lib // {
    inherit fromTOML;
    rustLib = {
      inherit fromManifest fromManifestFile manifest_v2_url;
    };
  };

  rustChannelOf = manifest_args: fromManifest
    (manifest_v2_url manifest_args)
    { inherit (self) stdenv fetchurl patchelf; }
    ;

  # Set of packages which are automagically updated. Do not rely on these for
  # reproducible builds.
  latest = (super.latest or {}) // {
    rustChannels = {
      nightly = rustChannelOf { channel = "nightly"; };
      beta    = rustChannelOf { channel = "beta"; };
      stable  = rustChannelOf { channel = "stable"; };
    };
  };

  # For backward compatibility
  rustChannels = latest.rustChannels;

  # For each channel:
  #   latest.rustChannels.nightly.cargo
  #   latest.rustChannels.nightly.rust   # Aggregate all others. (recommended)
  #   latest.rustChannels.nightly.rustc
  #   latest.rustChannels.nightly.rust-analysis
  #   latest.rustChannels.nightly.rust-docs
  #   latest.rustChannels.nightly.rust-src
  #   latest.rustChannels.nightly.rust-std

  # For a specific date:
  #   rustChannelOf { date = "2017-06-06"; channel = "beta"; }.rust
}
