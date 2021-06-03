# Overlay that builds on top of rust-overlay.nix.
# Adds rust-src component to all channels which is helpful for racer, intellij, ...

self: super:

let mapAttrs = super.lib.mapAttrs;
    flip = super.lib.flip;
in {
  # install stable rust with rust-src:
  # "nix-env -i -A nixos.latest.rustChannels.stable.rust"

  latest.rustChannels =
    flip mapAttrs super.latest.rustChannels (name: value: value // {
      rust = value.rust.override {
        extensions = ["rust-src"];
      };
    });
}
