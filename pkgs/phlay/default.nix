{ fetchFromGitHub
, python36Packages
}:
python36Packages.buildPythonApplication {
  name = "phlay";
  version = "0.1.4";
  src = fetchFromGitHub {
    owner = "mystor";
    repo = "phlay";
    rev = "d3594b4c48b40f742bbd8b6293aeb29f33be45ef";
    sha256 = "0b7xzrkafm6nb8rm19izyaymmc3mbr0ana1yspffxw819xwzl6vx";
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
