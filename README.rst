nixpkgs-mozilla
===============

Gathering nix efforts in one repository.


Current packages
----------------

- gecko (https://github.com/mozilla/gecko-dev)
- firefox-bin variants including Nightly

firefox-bin variants
--------------------

Nixpkgs already has definitions for `firefox
<https://github.com/NixOS/nixpkgs/blob/246d2848ff657d56fcf2d8596709e8869ce8616a/pkgs/applications/networking/browsers/firefox/packages.nix>`_,
which is built from source, as well as `firefox-bin
<https://github.com/NixOS/nixpkgs/blob/ba2fe3c9a626a8fb845c786383b8b23ad8355951/pkgs/applications/networking/browsers/firefox-bin/default.nix>`_,
which is the binary Firefox version built by Mozilla.

The ``firefox-overlay.nix`` in this repository adds definitions for
some other firefox-bin variants that Mozilla ships:
``firefox-nightly-bin``, ``firefox-beta-bin``, and
``firefox-esr-bin``. All are exposed under a ``latest`` attribute,
e.g. ``latest.firefox-nightly-bin``.

Unfortunately, these variants do not auto-update, and you may see some
annoying pop-ups complaining about this.

Note that all the ``-bin`` packages are "unfree" (because of the
Firefox trademark, held by Mozilla), so you will need to set
``nixpkgs.config.allowUnfree`` in order to use them. More info `here
<https://nixos.wiki/wiki/FAQ#How_can_I_install_a_proprietary_or_unfree_package.3F>`_.

Rust overlay
------------

**NOTE:** Nix overlays only works on up-to-date versions of NixOS/nixpkgs, starting from 17.03.

A nixpkgs overlay is provided to contain all of the latest rust releases.

To use the rust overlay run the ``./rust-overlay-install.sh`` command. It will
link the current ``./rust-overlay.nix`` into your ``~/.config/nixpkgs/overlays`` folder.

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
       # to use the latest nightly:
       nixpkgs.latest.rustChannels.nightly.rust
       # to use a specific nighly:
       (nixpkgs.rustChannelOf { date = "2018-04-11"; channel = "nightly"; }).rust
       # to use the project's rust-toolchain file:
       (nixpkgs.rustChannelOf { rustToolchain = ./rust-toolchain; }).rust
     ];
   }

Firefox Development Environment
-------------------------------

This repository provides several tools to facilitate development on
Firefox. Firefox is built on an engine called Gecko, which lends its
name to some of the files and derivations in this repo.

Checking out Firefox
~~~~~~~~~~~~~~~~~~~~

To build Firefox from source, it is best to have a local checkout of
``mozilla-central``. ``mozilla-central`` is hosted in Mercurial, but
some people prefer to access it using ``git`` and
``git-cinnabar``. The tools in this repo support either using
mercurial or git.

This repository provides a ``git-cinnabar-overlay.nix`` which defines
a ``git-cinnabar`` derivation. This overlay can be used to install
``git-cinnabar``, either using ``nix-env`` or as part of a system-wide
``configuration.nix``.

Building Firefox
~~~~~~~~~~~~~~~~

The ``firefox-overlay.nix`` provides an environment to build Firefox
from its sources, once you have finished the checkout of
``mozilla-central``. You can use ``nix-shell`` to enter this
environment to launch ``mach`` commands to build Firefox and test your
build.

Some debugging tools are available in this environment as well, but
other development tools (such as those used to submit changes for
review) are outside the scope of this environment.

The ``nix-shell`` environment is available in the
``gecko.<arch>.<cc>`` attribute of the ``release.nix`` file provided
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

When first entering the ``nix-shell``, the toolchain will pull and build all
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

When entering the ``nix-shell``, the ``MOZCONFIG`` environment variable is set
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
  [~/mozilla-central] export MOZCONFIG="$(pwd)/.mozconfig"
  [~/mozilla-central] python ./mach build

To avoid repeating yourself, you can also rely on the ``NIX_SHELL_HOOK``
environment variable, to reset the ``MOZCONFIG`` environment variable for you.

.. code:: sh

  ~/mozilla-central$ export NIX_SHELL_HOOK="export MOZCONFIG=$(pwd)/.mozconfig;"
  ~/mozilla-central$ nix-shell ../nixpkgs-mozilla/release.nix -A gecko.x86_64-linux.gcc --pure
  [~/mozilla-central] python ./mach build

Submitting Firefox patches
~~~~~~~~~~~~~~~~~~~~~~~~~~

Firefox development happens in `Mozilla Phabricator
<https://phabricator.services.mozilla.com/>`_. Mozilla Phabricator
docs are `here
<https://moz-conduit.readthedocs.io/en/latest/phabricator-user.html>`_.

To get your commits into Phabricator, some options include:

- Arcanist, the upstream tool for interacting with
  Phabricator. Arcanist is packaged in nixpkgs already; you can find
  it in `nixos.arcanist`. Unfortunately, as of this writing, upstream
  Arcanist does not support ``git-cinnabar`` (according to `the
  "Setting up Arcanist"
  <https://moz-conduit.readthedocs.io/en/latest/phabricator-user.html#setting-up-arcanist>`_
  documentation). `Mozilla maintains a fork of Arcanist
  <https://github.com/mozilla-conduit/arcanist>`_ but it isn't yet
  packaged. (PRs welcome.)

- `moz-phab <https://github.com/mozilla-conduit/review>`_, a small
  Python script that wraps Arcanist to try to handle commit series
  better than stock Arcanist. Because it wraps Arcanist, it suffers
  from the same problems that Arcanist does if you use git-cinnabar,
  and may work better if you use Mozilla's Arcanist fork.  ``moz-phab``
  isn't packaged yet. (PRs welcome.)

- `phlay <https://github.com/mystor/phlay>`_, a small Python script
  that speaks to the Phabricator API directly. This repository ships a
  ``phlay-overlay.nix`` that you can use to make ``phlay`` available
  in a nix-shell or nix-env.

Note: although the ``nix-shell`` from the previous section may have
all the tools you would normally use to do Firefox development, it
isn't recommended that you use that shell for anything besides tasks
that involve running ``mach``. Other development tasks such as
committing code and submitting patches to code review are best handled
in a separate nix-shell.

TODO
----

- setup hydra to have binary channels

- make sure pinned revisions get updated automatically (if build passes we
  should update revisions in default.nix)

- pin to specific (working) nixpkgs revision (as we do for other sources)

- can we make this work on darwin as well?

- assign maintainers for our packages that will montior that it "always" builds

- hook it with vulnix report to monitor CVEs (once vulnix is ready, it must be
  ready soon :P)
