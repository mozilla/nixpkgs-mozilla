# This file provide the latest binary versions of Firefox published by Mozilla.
self: super:

let
  # This URL needs to be updated about every 2 years when the subkey is rotated.
  pgpKey = super.fetchurl {
    url = "https://download.cdn.mozilla.net/pub/firefox/candidates/113.0.1-candidates/build1/KEY";
    sha256 = "beaf64d50d347175af3308e73aaeeb547f912e453bb15594122cb669cc4cabfb";
  };

  # This file is currently maintained manually, if this Nix expression attempt
  # to download the wrong version, this is likely to be the problem.
  #
  # Open a pull request against https://github.com/mozilla-releng/ship-it/ to
  # update the version, as done in
  # https://github.com/mozilla-releng/ship-it/pull/182
  firefox_versions = with builtins;
    fromJSON (readFile (fetchurl "https://product-details.mozilla.org/1.0/firefox_versions.json"));

  arch = if self.stdenv.system == "i686-linux"
    then "linux-i686"
    else "linux-x86_64";

  yearOf = with super.lib; yyyymmddhhmmss:
    head (splitString "-" yyyymmddhhmmss);
  monthOf = with super.lib; yyyymmddhhmmss:
    head (tail (splitString "-" yyyymmddhhmmss));

  # Given SHA512SUMS file contents and file name, extract matching sha512sum.
  extractSha512Sum = sha512sums: file:
    with builtins;
    # Nix 1.x do not have `builtins.split`.
    # Nix 2.0 have an bug in `builtins.match` (see https://github.com/NixOS/nix/issues/2147).
    # So I made separate logic for Nix 1.x and Nix 2.0.
    if builtins ? split then
      substring 0 128 (head
        (super.lib.filter
          (s: isString s && substring 128 (stringLength s) s == "  ${file}")
          (split "\n" sha512sums)))
    else
      head (match ".*[\n]([0-9a-f]*)  ${file}.*" sha512sums);

  # The timestamp argument is a yyyy-mm-dd-hh-mm-ss date, which corresponds to
  # one specific version. This is used mostly for bisecting.
  versionInfo = { name, version, release, system ? arch, timestamp ? null, info ? null, ... }: with builtins;
    if (info != null) then info else
    if release then
      # For versions such as Beta & Release:
      # https://download.cdn.mozilla.net/pub/firefox/releases/55.0b3/SHA256SUMS
      let
        dir = "https://download.cdn.mozilla.net/pub/firefox/releases/${version}";
        file = "${system}/en-US/firefox-${version}.tar.bz2";
        sha512Of = chksum: file: extractSha512Sum (readFile (fetchurl chksum)) file;
      in rec {
        chksum = "${dir}/SHA512SUMS";
        chksumSig = "${chksum}.asc";
        chksumSha256 = hashFile "sha256" (fetchurl "${dir}/SHA512SUMS");
        chksumSigSha256 = hashFile "sha256" (fetchurl "${chksum}.asc");
        inherit file;
        url = "${dir}/${file}";
        sha512 = sha512Of chksum file;
        sig = null;
        sigSha512 = null;
      }
    else
      # For Nightly versions:
      # https://download.cdn.mozilla.net/pub/firefox/nightly/latest-mozilla-central/firefox-56.0a1.en-US.linux-x86_64.checksums
      let
        dir =
          if timestamp == null then
            let
              buildhubJSON = with builtins;
                fromJSON (readFile (fetchurl "https://download.cdn.mozilla.net/pub/firefox/nightly/latest-mozilla-central/firefox-${version}.en-US.${system}.buildhub.json"));
            in builtins.replaceStrings [ "/${file}" ] [ "" ] buildhubJSON.download.url
          else "https://download.cdn.mozilla.net/pub/firefox/nightly/${yearOf timestamp}/${monthOf timestamp}/${timestamp}-mozilla-central" ;
        file = "firefox-${version}.en-US.${system}.tar.bz2";
        sha512Of = chksum: file: head (match ".*[\n]([0-9a-f]*) sha512 [0-9]* ${file}[\n].*" (readFile (fetchurl chksum)));
      in rec {
        chksum = "${dir}/firefox-${version}.en-US.${system}.checksums";
        chksumSig = null;
        # file content:
        # <hash> sha512 62733881 firefox-56.0a1.en-US.linux-x86_64.tar.bz2
        # <hash> sha256 62733881 firefox-56.0a1.en-US.linux-x86_64.tar.bz2
        url = "${dir}/${file}";
        sha512 = sha512Of chksum file;
        sig = "${dir}/${file}.asc";
        sigSha512 = sha512Of chksum "${file}.asc";
      };

  # From the version info, check the authenticity of the check sum file, such
  # that we guarantee that we have
  verifyFileAuthenticity = { file, sha512, chksum, chksumSig }:
    assert extractSha512Sum (builtins.readFile chksum) file == sha512;
    super.runCommand "check-firefox-signature" {
      buildInputs = [ self.gnupg ];
      FILE = chksum;
      ASC = chksumSig;
    } ''
      set -eu
      gpg --dearmor < ${pgpKey} > keyring.gpg
      gpgv --keyring=./keyring.gpg $ASC $FILE
      mkdir $out
    '';

  # From the version info, create a fetchurl derivation which will get the
  # sources from the remote.
  fetchVersion = info:
    if info.chksumSig != null then
      super.fetchurl {
        inherit (info) url sha512;

        # This is a fixed derivation, but we still add as a dependency the
        # verification of the checksum.  Thus, this fetch script can only be
        # executed once the verifyAuthenticity script finished successfully.
        postFetch = ''
          : # Authenticity Check (${verifyFileAuthenticity {
            inherit (info) file sha512;
            chksum = builtins.fetchurl { url = info.chksum; sha256 = info.chksumSha256; };
            chksumSig = builtins.fetchurl { url = info.chksumSig; sha256 = info.chksumSigSha256; };
          }})
        '';
      }
    else
      super.fetchurl {
        inherit (info) url sha512;

        # This would download the tarball, and then verify that the content
        # match the signature file. Fortunately, any failure of this code would
        # prevent the output from being reused.
        postFetch =
          let asc = super.fetchurl { url = info.sig; sha512 = info.sigSha512; }; in ''
          : # Authenticity Check
          set -eu
          export PATH="$PATH:${self.gnupg}/bin/"
          gpg --dearmor < ${pgpKey} > keyring.gpg
          gpgv --keyring=./keyring.gpg ${asc} $out
        '';
      };

  firefoxVersion = version:
    let
      info = versionInfo version;
      pkg = ((self.firefox-bin-unwrapped.override {
        generated = {
          version = version.version;
          sources = { inherit (info) url sha512; };
        };
        channel = version.channel;
      }).overrideAttrs (old: {
        # Add a dependency on the signature check.
        src = fetchVersion info;
      }));
      in super.wrapFirefox pkg {
        pname = "${pkg.binaryName}-bin";
        desktopName = version.name;
        wmClass = version.wmClass;
      };

  firefoxVariants = {
    firefox-nightly-bin = {
      name = "Firefox Nightly";
      channel = "nightly";
      wmClass = "firefox-nightly";
      version = firefox_versions.FIREFOX_NIGHTLY;
      release = false;
    };
    firefox-beta-bin = {
      name = "Firefox Beta";
      channel = "beta";
      wmClass = "firefox-beta";
      version = firefox_versions.LATEST_FIREFOX_DEVEL_VERSION;
      release = true;
    };
    firefox-bin = {
      name = "Firefox";
      channel = "release";
      wmClass = "firefox";
      version = firefox_versions.LATEST_FIREFOX_VERSION;
      release = true;
    };
    firefox-esr-bin = {
      name = "Firefox ESR";
      channel = "release";
      wmClass = "firefox";
      version = firefox_versions.FIREFOX_ESR;
      release = true;
    };
  };
in

{
  lib = super.lib // {
    firefoxOverlay = {
      inherit pgpKey firefoxVersion versionInfo firefox_versions firefoxVariants;
    };
  };

  # Set of packages which are automagically updated. Do not rely on these for
  # reproducible builds.
  latest = (super.latest or {}) // (builtins.mapAttrs (n: v: firefoxVersion v) firefoxVariants);

  # Set of packages which used to build developer environment
  devEnv = (super.shell or {}) // {
    gecko = super.callPackage ./pkgs/gecko {
      inherit (self.python38Packages) setuptools;
      pythonFull = self.python38Full;
      nodejs =
        if builtins.compareVersions self.nodejs.name "nodejs-8.11.3" < 0
        then self.nodejs-8_x else self.nodejs;

      rust-cbindgen =
        if !(self ? "rust-cbindgen") then self.rust-cbindgen-latest
        else if builtins.compareVersions self.rust-cbindgen.version self.rust-cbindgen-latest.version < 0
        then self.rust-cbindgen-latest else self.rust-cbindgen;

      # Due to std::ascii::AsciiExt changes in 1.23, Gecko does not compile, so
      # use the latest Rust version before 1.23.
      # rust = (super.rustChannelOf { channel = "stable"; date = "2017-11-22"; }).rust;
      # rust = (super.rustChannelOf { channel = "stable"; date = "2020-03-12"; }).rust;
      inherit (self.latest.rustChannels.stable) rust;
    };
  };

  # Use rust-cbindgen imported from Nixpkgs (September 2018) unless the current
  # version of Nixpkgs already packages a version of rust-cbindgen.
  rust-cbindgen-latest = super.callPackage ./pkgs/cbindgen {
    rustPlatform = super.makeRustPlatform {
      cargo = self.latest.rustChannels.stable.rust;
      rustc = self.latest.rustChannels.stable.rust;
    };
  };

  jsdoc = super.callPackage ./pkgs/jsdoc {};
}
