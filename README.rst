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

Using in nix expressions
------------------------

Example of using in ```shell.nix```:

.. code:: nix

 let
   moz_overlay = import (builtins.fetchTarball https://github.com/mozilla/nixpkgs-mozilla/archive/master.tar.gz);
   nixpkgs = import <nixpkgs> { overlays = [ moz_overlay ]; };
 in
   with nixpkgs;
   stdenv.mkDerivation {
     name = "moz_overlay_shell";
     buildInputs = [
       nixpkgs.latest.rustChannels.nightly.rust
       ];
   }

Gecko Development Environment
-----------------------------

The ``firefox-overlay.nix`` provides a development environment to build Firefox
from its sources, also known as Gecko.

To build Gecko from its sources, it is best to have a local checkout of Gecko,
and to build it with a ``nix-shell``. You can checkout Gecko, either using
mercurial, or git.

Once you have finished the checkout gecko, you should enter the ``nix-shell``
using the ``gecko.<arch>.<cc>`` attribute of the ``release.nix`` file provided
in this repository.

The ``<arch>`` attribute is either ``x86_64-linux`` or ``i686-linux``. The first
one would create a native toolchain for compiling on x64, while the second one
would give a native toolchain for compiling on x86. Note that due to the size of
the compilation units on x86, the compilation might not be able to complete, but
some sub part of Gecko, such as SpiderMonkey would compile fine.

The ``<cc>`` attribute is either ``gcc`` or ``clang``, or any specific version
of the compiler available in the ``compiler-overlay.nix`` file which is repeated
in ``release.nix``. This compiler would only be used for compiling Gecko, and
the rest of the toolchain is compiled against the default ``stdenv`` of the
architecture.

When first enterring the ``nix-shell``, the toolchain will pull and build all
the dependencies necessary to build Gecko, this includes might take some time.
This work will not be necessary the second time, unless you use a different
toolchain or architecture.

.. code:: sh

  ~/$ cd mozilla-central
  ~/mozilla-central$ nix-shell ../nixpkgs-mozilla/release.nix -A gecko.x86_64-linux.gcc --pure
    ... pull the rust compiler
    ... compile the toolchain
  [~/mozilla-central] python ./mach build
    ... build firefox desktop
  [~/mozilla-central] python ./mach run
    ... run firefox

When enterring the ``nix-shell``, the ``MOZCONFIG`` environment variable is set
to a local file, named ``.mozconfig.nix-shell``, created each time you enter the
``nix-shell``. You can create your own ``.mozconfig`` file which extends the
default one, with your own options.

.. code:: sh

  ~/mozilla-central$ nix-shell ../nixpkgs-mozilla/release.nix -A gecko.x86_64-linux.gcc --pure
  [~/mozilla-central] cat .mozconfig
  # Import current nix-shell config.
  . .mozconfig.nix-shell

  ac_add_options --enable-js-shell
  ac_add_options --disable-tests
  [~/mozilla-central] export MOZCONFIG=$(pwd)/.mozconfig
  [~/mozilla-central] python ./mach build

To avoid repeating your-self, you can also rely on the ``NIX_SHELL_HOOK``
environment variable, to reset the ``MOZCONFIG`` environment variable for you.

.. code:: sh

  ~/mozilla-central$ export NIX_SHELL_HOOK="export MOZCONFIG=$(pwd)/.mozconfig;"
  ~/mozilla-central$ nix-shell ../nixpkgs-mozilla/release.nix -A gecko.x86_64-linux.gcc --pure
  [~/mozilla-central] python ./mach build

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
