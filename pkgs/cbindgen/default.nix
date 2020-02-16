### NOTE: This file is a copy of the one from Nixpkgs repository
### (taken 2020 February) from commit 82d9ce45fe0b67e3708ab6ba47ffcb4bba09945d.
### It is used when the version of cbindgen in
### upstream nixpkgs is not up-to-date enough to compile Firefox.

{ stdenv, fetchFromGitHub, rustPlatform
# , Security
}:

rustPlatform.buildRustPackage rec {
  pname = "rust-cbindgen";
  version = "0.13.1";

  src = fetchFromGitHub {
    owner = "eqrion";
    repo = "cbindgen";
    rev = "v${version}";
    sha256 = "1x21g66gri6z9bnnfn7zmnf2lwdf5ing76pcmw0ilx4nzpvfhkg0";
  };

  cargoSha256 = "13fb8cdg6r0g5jb3vaznvv5aaywrnsl2yp00h4k8028vl8jwwr79";

  # buildInputs = stdenv.lib.optional stdenv.isDarwin Security;

  checkFlags = [
    # https://github.com/eqrion/cbindgen/issues/338
    "--skip test_expand"
  ];

  meta = with stdenv.lib; {
    description = "A project for generating C bindings from Rust code";
    homepage = https://github.com/eqrion/cbindgen;
    license = licenses.mpl20;
    maintainers = with maintainers; [ jtojnar andir ];
  };
}
