{ pkgs
, channel
}:

assert builtins.elem channel ["nightly" "developer"];

let

  unwrapped = pkgs.callPackage "${pkgs.path}/pkgs/applications/networking/browsers/firefox-bin" {
    inherit (pkgs) stdenv;
    generated = import (./. + "/${channel}_sources.nix");
    gconf = pkgs.gnome2.GConf;
    inherit (pkgs.gnome2) libgnome libgnomeui;
    inherit (pkgs.gnome3) defaultIconTheme;
  };

  name = "firefox-${channel}-bin-${(builtins.parseDrvName unwrapped.name).version}";

  self = pkgs.wrapFirefox unwrapped {
    browserName = "firefox";
    desktopName = "Firefox ${channel} Edition";
    inherit name;
  };

in self // {
  updateScript = import ./update.nix {
    inherit channel name;
    inherit (pkgs) writeScript xidel coreutils gnused gnugrep curl;
  };
}
