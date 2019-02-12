{ fetchFromGitHub
, python36Packages
}:
python36Packages.buildPythonApplication {
  name = "phlay";
  version = "0.1.5";
  src = fetchFromGitHub {
    owner = "mystor";
    repo = "phlay";
    rev = "da238512d89eacda526a4f53fc0a096ad594efd9";
    sha256 = "1cq1jq89xwx25yyqa4n4jhy55bvbyqm0knd7m8vacivqn9p3krks";
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
