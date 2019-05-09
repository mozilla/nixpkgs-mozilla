### NOTE: This file is a copy of the one from Nixpkgs repository
### (taken 2018 October).  It is used when the version of cbindgen in
### upstream nixpkgs is not up-to-date enough to compile Firefox.
{ stdenv, fetchFromGitHub, rustPlatform }:

rustPlatform.buildRustPackage rec {
  name = "rust-cbindgen-${version}";
  version = "0.8.6";

  src = fetchFromGitHub {
    owner = "eqrion";
    repo = "cbindgen";
    rev = "v${version}";
    sha256 = "0krh76ng3i19q5wffym74iamyx2bg6iw941cppfzayg4k3q2ai1w";
  };

  cargoSha256 = "00j5nm491zil6kpjns31qyd6z7iqd77b5qp4h7149s70qjwfq2cb";

  meta = with stdenv.lib; {
    description = "A project for generating C bindings from Rust code";
    homepage = https://github.com/eqrion/cbindgen;
    license = licenses.mpl20;
    maintainers = with maintainers; [ jtojnar ];
  };
}
