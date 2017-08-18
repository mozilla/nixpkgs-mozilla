nixpkgs-mozilla
===============

Gathering nix efforts in one repository.


Current packages
----------------

- servo (https://github.com/servo/servo)
- gecko (https://github.com/mozilla/gecko-dev)
- firefox-dev-bin (`Firefox Developer Edition <https://www.mozilla.org/en-US/firefox/developer/>`)
- VidyoDesktop ()

Rust overlay
------------

**NOTE:** Nix overlays only works on up-to-date versions of NixOS/nixpkgs, starting from 17.03.

A nixpkgs overlay is provided to contains all of the latest rust releases.

To use the rust overlay run the ``./rust-overlay-install.sh`` command. It will
link the current ``./rust-overlay.nix`` into you ``~/.config/nixpkgs/overlays`` folders.

Once this is done, use ``nix-env -iA nixpkgs.latest.rustChannels.nightly.rust`` for
example. Replace the ``nixpkgs.`` prefix with ``nixos.`` on NixOS.

TODO
----

- setup hydra and have to have binary channels

- make sure pinned revisions get updated automatically (if build passes we
  should update revisions in default.nix)

- pin to specific (working) nixpkgs revision (as we do for other sources

- servo can currently only be used with nix-shell. its build system tries to
  dowload quite few things (it is doing ``pip install`` and ``cargo install``).
  it should be possible to replace that with nix

- can we make this work on darwin as well?

- assign maintainers for our packages that will montior that it "always" builds

- hook it with vulnix report to monitor CVEs (once vulnix is ready, it must be
  ready soon :P)
