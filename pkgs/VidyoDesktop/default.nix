{ stdenv, pkgs, fetchurl, buildFHSUserEnv, makeWrapper, dpkg, alsaLib,
  libGL, alsaUtils, alsaOss, alsaTools, alsaPlugins, utillinux, mesa_glu, qt4,
  zlib, patchelf, xorg, libpulseaudio
}:

let
  vidyoVersion = "3.6.3";
  vidyoBuild = "017";
  vidyoVersionUnderscore = builtins.replaceStrings ["."] ["_"] vidyoVersion;
  VidyoDesktopDeb = stdenv.mkDerivation {
    name = "VidyoDesktopDeb-${vidyoVersion}";
    builder = ./builder.sh;
    inherit dpkg;
    src = fetchurl {
      url = "https://v.mozilla.com/upload/VidyoDesktopInstaller-ubuntu64-TAG_VD_${vidyoVersionUnderscore}_${vidyoBuild}.deb";
      sha256 = "01spq6r49myv82fdimvq3ykwb1lc5bymylzcydfdp9xz57f5a94x";
    };
    buildInputs = [ makeWrapper ];
  };
  libidn = stdenv.mkDerivation rec {
    name = "libidn-1.34";
  
    src = fetchurl {
      url = "mirror://gnu/libidn/${name}.tar.gz";
      sha256 = "0g3fzypp0xjcgr90c5cyj57apx1cmy0c6y9lvw2qdcigbyby469p";
    };
  
    outputs = [ "bin" "dev" "out" "info" "devdoc" ];
  
    # broken with gcc-7
    #doCheck = !stdenv.isDarwin && !stdenv.hostPlatform.isMusl;
  
    hardeningDisable = [ "format" ];
  
    buildInputs = stdenv.lib.optional stdenv.isDarwin pkgs.libiconv;
  
    doCheck = false; # fails
  
    meta = {
      homepage = http://www.gnu.org/software/libidn/;
      description = "Library for internationalized domain names";
  
      longDescription = ''
        GNU Libidn is a fully documented implementation of the
        Stringprep, Punycode and IDNA specifications.  Libidn's purpose
        is to encode and decode internationalized domain names.  The
        native C, C\# and Java libraries are available under the GNU
        Lesser General Public License version 2.1 or later.
  
        The library contains a generic Stringprep implementation.
        Profiles for Nameprep, iSCSI, SASL, XMPP and Kerberos V5 are
        included.  Punycode and ASCII Compatible Encoding (ACE) via IDNA
        are supported.  A mechanism to define Top-Level Domain (TLD)
        specific validation tables, and to compare strings against those
        tables, is included.  Default tables for some TLDs are also
        included.
      '';
  
      repositories.git = git://git.savannah.gnu.org/libidn.git;
      license = stdenv.lib.licenses.lgpl2Plus;
      platforms = stdenv.lib.platforms.all;
      maintainers = [ ];
    };
  };
in
buildFHSUserEnv {
  name = "VidyoDesktop";
  targetPkgs = pkgs: [ VidyoDesktopDeb ];
  multiPkgs = pkgs: [
    patchelf dpkg alsaLib alsaUtils alsaOss alsaTools alsaPlugins
    libidn libGL utillinux mesa_glu qt4 zlib xorg.libXext xorg.libXv xorg.libX11
    xorg.libXfixes xorg.libXrandr xorg.libXScrnSaver
    libpulseaudio
  ];
  extraBuildCommands = ''
    ln -s ${VidyoDesktopDeb}/opt $out/opt
  '';
  runScript = "VidyoDesktop";
  # for debugging
  #runScript = "bash";
}
