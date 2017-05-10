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

  getExtensions = pkgs: pkgname: stdenv:
    let
      pkg = pkgs.${pkgname};
      srcInfo = pkg.target.${hostTripleOf stdenv.system} or pkg.target."*";
      extensions = srcInfo.extensions or [];
      extensionNamesList =
        builtins.map (pkg: pkg.pkg) (builtins.filter (pkg:  (pkg.target == (hostTripleOf stdenv.system)) || (pkg.target == "*")) extensions);
    in
      extensionNamesList;

  getFetchUrl = pkgs: pkgname: stdenv: fetchurl:
    let
      pkg = pkgs.${pkgname};
      srcInfo = pkg.target.${hostTripleOf stdenv.system} or pkg.target."*";
    in
      (fetchurl { url = srcInfo.url; sha256 = srcInfo.hash; });

  getSrcs = pkgs: pkgname: extensions: stdenv: fetchurl:
    let
      inherit (builtins) head;
      inherit (super.lib) subtractLists concatStringsSep;
      availableExtensions = getExtensions pkgs pkgname stdenv;
      missingExtensions = subtractLists availableExtensions extensions;
      extensionsToInstall =
        if missingExtensions == [] then extensions else throw ''
          While compiling ${pkgname}: the extension ${head missingExtensions} is not available.
          Select extensions from the following list:
          ${concatStringsSep "\n" availableExtensions}'';
      pkgsToInstall = [pkgname] ++ extensionsToInstall;
    in
      (builtins.map (pkg: (getFetchUrl pkgs pkg stdenv fetchurl)) pkgsToInstall);

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
  fromManifestFile = manifest: { stdenv, fetchurl, patchelf }:
    let
      inherit (builtins) elemAt;
      inherit (super) makeOverridable;
      inherit (super.lib) flip mapAttrs;
      pkgs = fromTOML (builtins.readFile manifest);
    in
    flip mapAttrs pkgs.pkg (name: pkg:
      makeOverridable ({extensions}:
        let
          version' = builtins.match "([^ ]*) [(]([^ ]*) ([^ ]*)[)]" pkg.version;
          version = "${elemAt version' 0}-${elemAt version' 2}-${elemAt version' 1}";
          srcs = getSrcs pkgs.pkg name extensions stdenv fetchurl;
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
          }
      ) { extensions = []; }
    );

  fromManifest = manifest: { stdenv, fetchurl, patchelf }:
    fromManifestFile (builtins.fetchurl manifest) { inherit stdenv fetchurl patchelf; };

in

{
  lib = super.lib // {
    inherit fromTOML;
    rustLib = {
      inherit fromManifest fromManifestFile manifest_v2_url;
    };
  };

  # For each channel:
  #   rustChannels.nightly.cargo
  #   rustChannels.nightly.rust   # Aggregate all others. (recommended)
  #   rustChannels.nightly.rustc
  #   rustChannels.nightly.rust-analysis
  #   rustChannels.nightly.rust-docs
  #   rustChannels.nightly.rust-src
  #   rustChannels.nightly.rust-std
  rustChannels = {
    nightly = fromManifest (manifest_v2_url { channel = "nightly"; }) {
      inherit (self) stdenv fetchurl patchelf;
    };
    beta    = fromManifest (manifest_v2_url { channel = "beta"; }) {
      inherit (self) stdenv fetchurl patchelf;
    };
    stable  = fromManifest (manifest_v2_url { channel = "stable"; }) {
      inherit (self) stdenv fetchurl patchelf;
    };
  };
}
