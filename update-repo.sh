#!/bin/sh
#
# Updates the repo's SHA
#

github_rev() {
  curl -sSf "https://api.github.com/repos/$1/$2/branches/$3" | \
    jq '.commit.sha' | \
    sed 's/"//g'
}

github_sha256() {
  nix-prefetch-zip \
    --hash-type sha256 \
    "https://github.com/$1/$2/archive/$3.tar.gz" 2>&1 | \
    grep "hash is " | \
    sed 's/hash is //'
}

file=$1
branch=${2:-master}

owner=$(jq -r -e .owner < "$file")
echo "owner: $owner"
repo=$(jq -r -e .repo < "$file")
echo "repo: $repo"
rev=$(github_rev "$owner" "$repo" "$branch");
echo "rev: $rev"
sha256=$(github_sha256 "$owner" "$repo" "$rev");

cat <<REPO | tee "$file"
{
  "owner": "${owner}",
  "repo": "${repo}",
  "rev": "${rev}",
  "sha256": "${sha256}"
}
REPO
