{ name
, writeScript
, xidel
, coreutils
, gnused
, gnugrep
, curl
, channel
, basePath ? "pkgs/firefox-bin" 
, baseUrl ? "http://archive.mozilla.org/pub/firefox/nightly/"
}:

assert builtins.elem channel ["nightly" "developer"];

let
  version = (builtins.parseDrvName name).version;
in writeScript "update-${channel}-bin" ''
  PATH=${coreutils}/bin:${gnused}/bin:${gnugrep}/bin:${xidel}/bin:${curl}/bin

  pushd ${basePath}

  tmpfile=`mktemp`
  url=${baseUrl}

  # retrive last year
  year=`xidel -q $url --extract "//a" | \
        sed s"/.$//" | \
        grep "^[0-9]" | \
        sort | \
        tail -1`

  month=`xidel -q "$url$year/" --extract "//a" | \
         sed s"/.$//" | \
         grep "^[0-9]" | \
         sort | \
         tail -1`

  cat > $tmpfile <<EOF
  {
    sources = [
  EOF

  day=`xidel -q "$url$year/$month/" --extract "//a" | \
       sed s"/.$//" | \
       grep -v "l10n$" | \
       grep "\-${if channel == "nightly" then "mozilla-central" else "mozilla-aurora"}" | \
       grep "^[0-9]" | \
       sort | \
       tail -2 | head -1`  # we dont take the last but second last

  checksums=`xidel -q "$url$year/$month/$day/" --extract "//a" | \
             grep ".checksums$" | \
             grep linux | \
             tr "\n" " "`

  for checksum in `echo $checksums`; do
      arch=`echo $checksum | cut -d"." -f4`
      locale=`echo $checksum | cut -d"." -f3`
      version="`echo $checksum | cut -d'.' -f1 | sed 's/firefox-//'`.`echo $checksum | cut -d'.' -f2`"
      sha512=`curl --silent $url$year/$month/$day/$checksum | grep firefox-$version.$locale.$arch.tar.bz2 | grep sha512 | cut -d' ' -f1`

      cat >> $tmpfile <<EOF
      { url = "$url$year/$month/$day/firefox-$version.$locale.$arch.tar.bz2";
        locale = "$locale";
        arch = "$arch";
        sha512 = "$sha512";
      }
  EOF
  done

  day=`xidel -q "$url$year/$month/" --extract "//a" | \
       sed s"/.$//" | \
       grep "l10n$" | \
       grep "\-${if channel == "nightly" then "mozilla-central" else "mozilla-aurora"}" | \
       grep "^[0-9]" | \
       sort | \
       tail -2 | head -1`  # we dont take the last but second last

  checksums=`xidel -q "$url$year/$month/$day/" --extract "//a" | \
             grep ".checksums$" | \
             grep linux | \
             tr "\n" " "`

  for checksum in `echo $checksums`; do
      arch=`echo $checksum | cut -d"." -f4`
      locale=`echo $checksum | cut -d"." -f3`
      version="`echo $checksum | cut -d'.' -f1 | sed 's/firefox-//'`.`echo $checksum | cut -d'.' -f2`"
      sha512=`curl --silent $url$year/$month/$day/$checksum | grep firefox-$version.$locale.$arch.tar.bz2 | grep sha512 | cut -d' ' -f1`

      cat >> $tmpfile <<EOF
      { url = "$url$year/$month/$day/firefox-$version.$locale.$arch.tar.bz2";
        locale = "$locale";
        arch = "$arch";
        sha512 = "$sha512";
      }
  EOF
  done

  cat >> $tmpfile <<EOF
    ];
    version = "$version";
  }
  EOF

  mv $tmpfile ${channel}_sources.nix

  popd
''
