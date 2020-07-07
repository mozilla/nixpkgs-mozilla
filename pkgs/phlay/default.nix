{ fetchFromGitHub
, python3Packages
}:
python3Packages.buildPythonApplication rec {
  name = "phlay-${version}";
  version = "0.2.3";
  src = fetchFromGitHub {
    owner = "mystor";
    repo = "phlay";
    rev = "98fcbead18c785db24a4b62fad4a8a525b81f8e1";
    sha256 = "1m5c7lq12pgcaab4xrifzi0axaxpx24kb9x2f017pb5ni7lbcg3s";
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
