{ pkgs }:

let
  inherit (pkgs) cacert nix-prefetch-scripts jq curl gnused gnugrep coreutils;
in {

  updateFromGitHub = { owner, repo, path, branch }: ''
    export SSL_CERT_FILE=${cacert}/etc/ssl/certs/ca-bundle.crt

    github_rev() {
      ${curl.bin}/bin/curl -sSf "https://api.github.com/repos/$1/$2/branches/$3" | \
        ${jq}/bin/jq '.commit.sha' | \
        ${gnused}/bin/sed 's/"//g'
    }

    github_sha256() {
      ${nix-prefetch-scripts}/bin/nix-prefetch-zip \
         --hash-type sha256 \
         "https://github.com/$1/$2/archive/$3.tar.gz" 2>&1 | \
         ${gnugrep}/bin/grep "hash is " | \
         ${gnused}/bin/sed 's/hash is //'
    }

    echo "=== ${owner}/${repo}@${branch} ==="

    echo -n "Looking up latest revision ... "
    rev=$(github_rev "${owner}" "${repo}" "${branch}");
    echo "revision is \`$rev\`."

    sha256=$(github_sha256 "${owner}" "${repo}" "$rev");
    echo "sha256 is \`$sha256\`."

    if [ "$sha256" == "" ]; then
      echo "sha256 is not valid!"
      exit 2
    fi
    source_file=$HOME/${path}
    echo "Content of source file (``$source_file``) written."
    cat <<REPO | ${coreutils}/bin/tee "$source_file"
    {
      "owner": "${owner}",
      "repo": "${repo}",
      "rev": "$rev",
      "sha256": "$sha256"
    }
    REPO
    echo
  '';

}
