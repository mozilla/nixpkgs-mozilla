# This file provide the latest binary versions of Firefox published by Mozilla.
final: prev:

# firefox.key file was downloaded from:
#   https://gpg.mozilla.org/pks/lookup?search=Mozilla+Software+Releases+%3Crelease%40mozilla.com%3E&op=get
#
# Now, the KEY file is stored next to the published version, such as:
#   https://archive.mozilla.org/pub/firefox/releases/66.0.2/KEY
#
# Any time there are changes, this file should be copied by the manager of the firefox-overlay and move
# in this repository under the name firefox.key.

let
  # This file is currently maintained manually, if this Nix expression attempt
  # to download the wrong version, this is likely to be the problem.
  #
  # Open a pull request against https://github.com/mozilla-releng/ship-it/ to
  # update the version, as done in
  # https://github.com/mozilla-releng/ship-it/pull/182
  firefox_versions = with builtins;
    fromJSON (readFile (fetchurl https://product-details.mozilla.org/1.0/firefox_versions.json));

  arch = if final.stdenv.system == "i686-linux"
    then "linux-i686"
    else "linux-x86_64";

  yearOf = with prev.lib; yyyymmddhhmmss:
    head (splitString "-" yyyymmddhhmmss);
  monthOf = with prev.lib; yyyymmddhhmmss:
    head (tail (splitString "-" yyyymmddhhmmss));

  # Given SHA512SUMS file contents and file name, extract matching sha512sum.
  extractSha512Sum = sha512sums: file:
    with builtins;
    # Nix 1.x do not have `builtins.split`.
    # Nix 2.0 have an bug in `builtins.match` (see https://github.com/NixOS/nix/issues/2147).
    # So I made separate logic for Nix 1.x and Nix 2.0.
    if builtins ? split then
      substring 0 128 (head
        (prev.lib.filter
          (s: isString s && substring 128 (stringLength s) s == "  ${file}")
          (split "\n" sha512sums)))
    else
      head (match ".*[\n]([0-9a-f]*)  ${file}.*" sha512sums);

  # The timestamp argument is a yyyy-mm-dd-hh-mm-ss date, which corresponds to
  # one specific version. This is used mostly for bisecting.
  versionInfo = { name, version, release, system ? arch, timestamp ? null }: with builtins;
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
  verifyFileAuthenticity = { file, asc }:
    if asc == null then "" else prev.runCommandNoCC "check-firefox-signature" {
      buildInputs = [ final.gnupg ];
      FILE = file;
      ASC = asc;
    } ''
      HOME=`mktemp -d`
      set -eu
      cat ${./firefox.key} | gpg --import
      gpgv --keyring=$HOME/.gnupg/pubring.kbx $ASC $FILE
      mkdir $out
    '';

  # From the version info, create a fetchurl derivation which will get the
  # sources from the remote.
  fetchVersion = info:
    if info.chksumSig != null then
      prev.fetchurl {
        inherit (info) url sha512;

        # This is a fixed derivation, but we still add as a dependency the
        # verification of the checksum.  Thus, this fetch script can only be
        # executed once the verifyAuthenticity script finished successfully.
        postFetch = ''
          : # Authenticity Check (${verifyFileAuthenticity {
            file = builtins.fetchurl info.chksum;
            asc = builtins.fetchurl info.chksumSig;
          }})
        '';
      }
    else
      prev.fetchurl {
        inherit (info) url sha512;

        # This would download the tarball, and then verify that the content
        # match the signature file. Fortunately, any failure of this code would
        # prevent the output from being reused.
        postFetch =
          let asc = prev.fetchurl { url = info.sig; sha512 = info.sigSha512; }; in ''
          : # Authenticity Check
          HOME=`mktemp -d`
          set -eu
          export PATH="$PATH:${final.gnupg}/bin/"
          cat ${./firefox.key} | gpg --import
          gpgv --keyring=$HOME/.gnupg/pubring.kbx ${asc} $out
        '';
      };

  firefoxVersion = version:
    let info = versionInfo version; in
    prev.wrapFirefox ((final.firefox-bin-unwrapped.override {
      generated = {
        version = version.version;
        sources = { inherit (info) url sha512; };
      };
    }).overrideAttrs (old: {
      # Add a dependency on the signature check.
      src = fetchVersion info;
    })) {
      browserName = "firefox";
      pname = "firefox-bin";
      desktopName = "Firefox";
    };
in

{
  lib = prev.lib // {
    firefoxOverlay = {
      inherit firefoxVersion;
    };
  };

  # Set of packages which are automagically updated. Do not rely on these for
  # reproducible builds.
  latest = (prev.latest or {}) // {
    firefox-nightly-bin = firefoxVersion {
      name = "Firefox Nightly";
      version = firefox_versions.FIREFOX_NIGHTLY;
      release = false;
    };
    firefox-beta-bin = firefoxVersion {
      name = "Firefox Beta";
      version = firefox_versions.LATEST_FIREFOX_DEVEL_VERSION;
      release = true;
    };
    firefox-bin = firefoxVersion {
      name = "Firefox";
      version = firefox_versions.LATEST_FIREFOX_VERSION;
      release = true;
    };
    firefox-esr-bin = firefoxVersion {
      name = "Firefox Esr";
      version = firefox_versions.FIREFOX_ESR;
      release = true;
    };
  };

  # Set of packages which used to build developer environment
  devEnv = (prev.shell or {}) // {
    gecko = prev.callPackage ./pkgs/gecko {
      inherit (final.python35Packages) setuptools;
      pythonFull = final.python35Full;
      nodejs =
        if builtins.compareVersions final.nodejs.name "nodejs-8.11.3" < 0
        then final.nodejs-8_x else final.nodejs;

      rust-cbindgen =
        if !(final ? "rust-cbindgen") then final.rust-cbindgen-latest
        else if builtins.compareVersions final.rust-cbindgen.version final.rust-cbindgen-latest.version < 0
        then final.rust-cbindgen-latest else final.rust-cbindgen;

      # Due to std::ascii::AsciiExt changes in 1.23, Gecko does not compile, so
      # use the latest Rust version before 1.23.
      # rust = (prev.rustChannelOf { channel = "stable"; date = "2017-11-22"; }).rust;
      inherit (final.latest.rustChannels.stable) rust;
      valgrind = final.valgrind-3_14;
    };
  };

  # Use rust-cbindgen imported from Nixpkgs (September 2018) unless the current
  # version of Nixpkgs already packages a version of rust-cbindgen.
  rust-cbindgen-latest = prev.callPackage ./pkgs/cbindgen {
    rustPlatform = prev.makeRustPlatform {
      cargo = final.latest.rustChannels.stable.rust;
      rustc = final.latest.rustChannels.stable.rust;
    };
  };

  valgrind-3_14 = prev.valgrind.overrideAttrs (attrs: {
    name = "valgrind-3.14.0";
    src = prev.fetchurl {
      url = "http://www.valgrind.org/downloads/valgrind-3.14.0.tar.bz2";
      sha256 = "19ds42jwd89zrsjb94g7gizkkzipn8xik3xykrpcqxylxyzi2z03";
    };
  });
}
