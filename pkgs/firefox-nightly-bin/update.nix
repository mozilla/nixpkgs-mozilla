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

  set -eux
  pushd pkgs/firefox-nightly-bin

  tmpfile=`mktemp`
  url=http://archive.mozilla.org/pub/firefox/nightly/latest-mozilla-central/

  nightly_file=`xidel -q $url --extract //a | \
                grep firefox | \
                grep linux-x86_64.json | \
                sed -e 's/.json//'`
  nightly_json=`curl --silent $url$nightly_file.json`
  nightly_checksum=

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
#  day=`xidel -q "$url$year/$month/" --extract "//a" | \
#       sed s"/.$//" | \
#       grep -v "l10n$" | \
#       grep "^[0-9]" | \
#       sort | \
#       tail -2 | head -1`  # we dont take the last but second last
#
#  checksums=`xidel -q "$url$year/$month/$day/" --extract "//a" | \
#             grep ".checksums$" | \
#             grep linux | \
#             tr "\n" " "`
#
#  for checksum in `echo $checksums`; do
#      arch=`echo $checksum | cut -d"." -f4`
#      locale=`echo $checksum | cut -d"." -f3`
#      version="`echo $checksum | cut -d'.' -f1 | sed 's/firefox-//'`.`echo $checksum | cut -d'.' -f2`"
#      sha512=`curl --silent $url$year/$month/$day/$checksum | grep firefox-$version.$locale.$arch.tar.bz2 | grep sha512 | cut -d' ' -f1`
#
#      cat >> $tmpfile <<EOF
#      { url = "$url$year/$month/$day/firefox-$version.$locale.$arch.tar.bz2";
#        locale = "$locale";
#        arch = "$arch";
#        sha512 = "$sha512";
#      }
#  EOF
#  done
#
#  day=`xidel -q "$url$year/$month/" --extract "//a" | \
#       sed s"/.$//" | \
#       grep "l10n$" | \
#       grep "^[0-9]" | \
#       sort | \
#       tail -2 | head -1`  # we dont take the last but second last
#
#  checksums=`xidel -q "$url$year/$month/$day/" --extract "//a" | \
#             grep ".checksums$" | \
#             grep linux | \
#             tr "\n" " "`
#
#  for checksum in `echo $checksums`; do
#      arch=`echo $checksum | cut -d"." -f4`
#      locale=`echo $checksum | cut -d"." -f3`
#      version="`echo $checksum | cut -d'.' -f1 | sed 's/firefox-//'`.`echo $checksum | cut -d'.' -f2`"
#      sha512=`curl --silent $url$year/$month/$day/$checksum | grep firefox-$version.$locale.$arch.tar.bz2 | grep sha512 | cut -d' ' -f1`
#
#      cat >> $tmpfile <<EOF
#      { url = "$url$year/$month/$day/firefox-$version.$locale.$arch.tar.bz2";
#        locale = "$locale";
#        arch = "$arch";
#        sha512 = "$sha512";
#      }
#  EOF
#  done
