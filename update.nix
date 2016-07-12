{ pkg ? null
}:

let
  pkgs = import <nixpkgs> {};
  mozilla = import ./default.nix {};

  updateGithub = name: { owner, repo, branch ? "master" }: ''
    echo "=== ${owner}/${repo}@${branch} ==="

    echo -n "Looking up latest revision ... "
    rev=$(github_rev "${owner}" "${repo}" "${branch}");
    echo "revision is \`$rev\`."

    echo -n "Downloading repository archive to calculate its sha256 ... "
    sha256=$(github_sha256 "${owner}" "${repo}" "$rev");
    echo "sha256 is \`$sha256\`."

    echo "Content of source file (`realpath $source_file`) written."
    source_file=$HOME/pkgs/${name}/source.json
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

  packages = if pkg == null
    then map
      (name: { inherit name; source = (builtins.getAttr name mozilla).source; })
      (builtins.filter
        (name: builtins.hasAttr "source" (builtins.getAttr name mozilla))
        (builtins.attrNames mozilla)
      )
    else [{ name = pkg;
            source = (builtins.getAttr pkg mozilla).source;
          }];

in pkgs.stdenv.mkDerivation {
  name = "update-nixpkgs-mozilla";
  buildInputs = with pkgs; [ jq curl nix-prefetch-scripts ];
  buildCommand = ''
    echo "+--------------------------------------------------------+"
    echo "| Not possible to update repositories using \`nix-build\`. |"
    echo "|         Please run \`nix-shell update.nix\`.             |"
    echo "+--------------------------------------------------------+"
  '';
  shellHook = ''
    export SSL_CERT_FILE=${pkgs.cacert}/etc/ssl/certs/ca-bundle.crt
    export HOME=$PWD

    github_rev() {
      curl -sSf "https://api.github.com/repos/$1/$2/branches/$3" | \
        jq '.commit.sha' | \
        sed 's/"//g'
    }

    github_sha256() {
      nix-prefetch-url --type sha256 "https://github.com/$1/$2/archive/$3.tar.gz" 2>&1 | \
        tail -n1
    }

    ${builtins.concatStringsSep "\n\n" (map (x: updateGithub x.name x.source) packages)}

    echo "Packages updated!"
    exit
  '';
}
