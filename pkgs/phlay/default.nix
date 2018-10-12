{ fetchFromGitHub
, python36Packages
}:
python36Packages.buildPythonApplication {
  name = "phlay";
  version = "0.1.2";
  src = fetchFromGitHub {
    owner = "mystor";
    repo = "phlay";
    rev = "0deedf7397e2133bf270c41136c7650433610d4e";
    sha256 = "1jdxk0a551zcfq6j8cp6ajm4dvsp7c0rqbdkk7h3lpdvws24z0n6";
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
