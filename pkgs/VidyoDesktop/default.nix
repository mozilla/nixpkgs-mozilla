{ stdenv, fetchurl, buildFHSUserEnv, makeWrapper, dpkg, alsaLib,
  alsaUtils, alsaOss, alsaTools, alsaPlugins, libidn, utillinux, mesa_glu, qt4,
  zlib, patchelf, xorg
}:

let
  VidyoDesktopDeb = stdenv.mkDerivation {
    name = "VidyoDesktopDeb-123";
    builder = ./builder.sh;
    inherit dpkg;
    src = fetchurl {
      url = "https://v.mozilla.com/upload/VidyoDesktopInstaller-ubuntu64-TAG_VD_3_3_0_027.deb";
      sha256 = "045f9z421qpcm45bmh98f3h7bd46rdjvcbdpv4rlw9ribncv66dc";
    };
    buildInputs = [ makeWrapper ];
  };

in buildFHSUserEnv {
  name = "VidyoDesktop-123";
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
