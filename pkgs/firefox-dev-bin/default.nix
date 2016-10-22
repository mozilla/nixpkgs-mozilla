{ pkgs, callPackage }:
let
  ff = callPackage <nixpkgs/pkgs/applications/networking/browsers/firefox-bin> {
    generated = import ./dev_sources.nix;
    gconf = pkgs.gnome2.GConf;
    inherit (pkgs.gnome2) libgnome libgnomeui;
    inherit (pkgs.gnome3) defaultIconTheme;
  };
in
  pkgs.wrapFirefox ff {
    browserName = "firefox";
    name = "firefox-developer-bin-" +
      (builtins.parseDrvName ff.name).version;
    desktopName = "Firefox Developer Edition";
  }
