{ name
, writeScript
, xidel
, coreutils
, gnused
, gnugrep
, curl
, jq
}:

let
  version = (builtins.parseDrvName name).version;
in writeScript "update-firefox-nightly-bin" ''
  PATH=${coreutils}/bin:${gnused}/bin:${gnugrep}/bin:${xidel}/bin:${curl}/bin:${jq}/bin

  #set -eux
  pushd pkgs/firefox-nightly-bin

  tmpfile=`mktemp`
  url=https://archive.mozilla.org/pub/firefox/nightly/latest-mozilla-central/

  nightly_file=`curl $url | \
                xidel - --extract //a | \
                grep firefox | \
                grep linux-x86_64.json | \
                tail -1 | \
                sed -e 's/.json//'`
  nightly_json=`curl --silent $url$nightly_file.json`

  cat > $tmpfile <<EOF
  {
    version = `echo $nightly_json | jq ."moz_app_version"` + "-" + `echo $nightly_json | jq ."buildid"`;
    sources = [
      { url = "$url$nightly_file.tar.bz2";
        locale = "`echo $nightly_file | cut -d"." -f3`";
        arch = "`echo $nightly_file | cut -d"." -f4`";
        sha512 = "`curl --silent $url$nightly_file.checksums | grep $nightly_file.tar.bz2$ | grep sha512 | cut -d" " -f1`";
      }
    ];
  }
  EOF

  mv $tmpfile sources.nix

  popd

''
