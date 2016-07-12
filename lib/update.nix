{ pkgs_mozilla }:

let
  inherit (pkgs_mozilla.nixpkgs) cacert nix jq;
in {

  packagesToUpdate = map
    (pkg: pkg.update_src)
    (builtins.filter
      (pkg: builtins.hasAttr "update_src" pkg)
      (builtins.attrValues pkgs_mozilla)
    );

  updateFromGitHub = { owner, repo, path, branch }: ''
    export SSL_CERT_FILE=${cacert}/etc/ssl/certs/ca-bundle.crt

    github_rev() {
      curl -sSf "https://api.github.com/repos/$1/$2/branches/$3" | \
        ${jq}/bin/jq '.commit.sha' | \
        sed 's/"//g'
    }

    github_sha256() {
      ${nix.out}/bin/nix-prefetch-url --type sha256 "https://github.com/$1/$2/archive/$3.tar.gz" | \
        tail -n1
    }

    echo "=== ${owner}/${repo}@${branch} ==="

    echo -n "Looking up latest revision ... "
    rev=$(github_rev "${owner}" "${repo}" "${branch}");
    echo "revision is \`$rev\`."

    sha256=$(github_sha256 "${owner}" "${repo}" "$rev");
    echo "sha256 is \`$sha256\`."

    source_file=$HOME/${path}
    echo "Content of source file (``$source_file``) written."
    cat <<REPO | tee "$source_file"
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
