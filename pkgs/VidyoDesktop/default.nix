{ stdenv, fetchurl, buildFHSUserEnv, makeWrapper, dpkg, alsaLib,
  alsaUtils, alsaOss, alsaTools, alsaPlugins, libidn, utillinux, mesa_glu, qt4,
  zlib, patchelf, xorg
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

in buildFHSUserEnv {
  name = "VidyoDesktop";
  targetPkgs = pkgs: [ VidyoDesktopDeb ];
  multiPkgs = pkgs: [
    patchelf dpkg alsaLib alsaUtils alsaOss alsaTools alsaPlugins
    libidn utillinux mesa_glu qt4 zlib xorg.libXext xorg.libXv xorg.libX11
    xorg.libXfixes xorg.libXrandr xorg.libXScrnSaver
  ];
  extraBuildCommands = ''
    ln -s ${VidyoDesktopDeb}/opt $out/opt
  '';
  runScript = "VidyoDesktop";
  # for debugging
  #runScript = "bash";
}
