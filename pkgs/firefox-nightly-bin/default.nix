{ pkgs
}:

let

  unwrapped = pkgs.callPackage "${pkgs.path}/pkgs/applications/networking/browsers/firefox-bin" {
    inherit (pkgs) stdenv;
    generated = import (./. + "/sources.nix");
    gconf = pkgs.gnome2.GConf;
    inherit (pkgs.gnome2) libgnome libgnomeui;
    inherit (pkgs.gnome3) defaultIconTheme;
  };

  name = "firefox-nightly-bin-${(builtins.parseDrvName unwrapped.name).version}";

  self = pkgs.wrapFirefox unwrapped {
    browserName = "firefox";
    desktopName = "Firefox Nightly";
    inherit name;
  };

in self // {
  updateScript = import ./update.nix {
    inherit name;
    inherit (pkgs) writeScript xidel coreutils gnused gnugrep curl jq;
  };
}
