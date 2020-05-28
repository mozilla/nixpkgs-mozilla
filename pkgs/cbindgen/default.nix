### NOTE: This file is a copy of the one from Nixpkgs repository
### (taken 2020 February) from commit 82d9ce45fe0b67e3708ab6ba47ffcb4bba09945d.
### It is used when the version of cbindgen in
### upstream nixpkgs is not up-to-date enough to compile Firefox.

{ stdenv, fetchFromGitHub, rustPlatform
# , Security
}:

rustPlatform.buildRustPackage rec {
  pname = "rust-cbindgen";
  version = "0.14.2";

  src = fetchFromGitHub {
    owner = "eqrion";
    repo = "cbindgen";
    rev = "v${version}";
    sha256 = "15mk7q89rs723c7i9wwq4rrvakwh834wvrsmsnayji5k1kwaj351";
  };

  cargoSha256 = "1avdpfsylf7cdsyk0sj8xyfamj07dqxivxxwshsfckrzhizdqm50";

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
