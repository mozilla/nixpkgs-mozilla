{ pkgs }:

let

  ff = pkgs.callPackage "${pkgs.path}/pkgs/applications/networking/browsers/firefox-bin" {
    inherit (pkgs) stdenv;
    generated = import ./nightly_sources.nix;
    gconf = pkgs.gnome2.GConf;
    inherit (pkgs.gnome2) libgnome libgnomeui;
    inherit (pkgs.gnome3) defaultIconTheme;
  };

  self = pkgs.wrapFirefox ff {
    browserName = "firefox";
    name = "firefox-nightly-bin" +
      (builtins.parseDrvName ff.name).version;
    desktopName = "Firefox Nightly Edition";
  };

in self // {
  updateSrc = pkgs.writeScript "update-firefox-nightly-bin" ''
    ${pkgs.ruby}/bin/ruby ${./generate_sources_nightly.rb} > pkgs/firefox-bin/nightly_sources.nix
  '';
}
