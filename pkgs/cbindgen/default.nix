### NOTE: This file is a copy of the one from Nixpkgs repository
### (taken 2020 February) from commit 82d9ce45fe0b67e3708ab6ba47ffcb4bba09945d.
### It is used when the version of cbindgen in
### upstream nixpkgs is not up-to-date enough to compile Firefox.

{ stdenv, lib, fetchFromGitHub, rustPlatform
# , Security
}:

rustPlatform.buildRustPackage rec {
  name = "rust-cbindgen-${version}";
  version = "0.14.3";

  src = fetchFromGitHub {
    owner = "eqrion";
    repo = "cbindgen";
    rev = "v${version}";
    sha256 = "0pw55334i10k75qkig8bgcnlsy613zw2p5j4xyz8v71s4vh1a58j";
  };

  cargoSha256 = "0088ijnjhqfvdb1wxy9jc7hq8c0yxgj5brlg68n9vws1mz9rilpy";

  # buildInputs = lib.optional stdenv.isDarwin Security;

  checkFlags = [
    # https://github.com/eqrion/cbindgen/issues/338
    "--skip test_expand"
  ];
  # https://github.com/NixOS/nixpkgs/issues/61618
  postConfigure = ''
    mkdir .cargo
    touch .cargo/.package-cache
    export HOME=`pwd`
  '';

  meta = with lib; {
    description = "A project for generating C bindings from Rust code";
    homepage = "https://github.com/eqrion/cbindgen";
    license = licenses.mpl20;
    maintainers = with maintainers; [ jtojnar andir ];
  };
}
