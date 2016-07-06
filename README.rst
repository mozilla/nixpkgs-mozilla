nixpkgs-mozilla
===============

Gathering nix efforts in one repository.


Current packages
----------------

- servo (https://github.com/servo/servo)
- gecko (https://github.com/mozilla/gecko-dev)
- VidyoDesktop ()


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
