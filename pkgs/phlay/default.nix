{ fetchFromGitHub
, python36Packages
}:
python36Packages.buildPythonApplication {
  name = "phlay";
  version = "0.2.0";
  src = fetchFromGitHub {
    owner = "mystor";
    repo = "phlay";
    rev = "398fccce05ce31d7d731d437c7febf30d3d83bf4";
    sha256 = "10mp941g639vgmiqpjdpfyazcwlvhj84ad78axn2waq20mi60l88";
  };
  meta = {
    description = "A command-line interface for Phabricator";
    longDescription = ''
      Phlay is an alternative to Arcanist for submitting changes to Phabricator.

      You might like Phlay if you do Mozilla development using git and
      a "commit series" workflow.
    '';
  };
  # phlay is designed as a single-file Python script with no
  # dependencies outside the stdlib.
  format = "other";
  installPhase = "mkdir -p $out/bin; cp phlay $out/bin";
}
