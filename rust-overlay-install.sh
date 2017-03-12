#!/bin/sh -e

cd "$(dirname "$0")" || exit

overlay_dir=$HOME/.nixpkgs/overlays
name=rust-overlay.nix

mkdir -p "$overlay_dir"

ln -s "$PWD/$name" "$overlay_dir/$name"
