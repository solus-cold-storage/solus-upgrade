#!/bin/bash
#
# This file is part of solus-upgrade
# 
# Copyright (C) 2015 Ikey Doherty <ikey@solus-project.com>
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 2 of the License, or
# (at your option) any later version.
#

function do_die()
{
    echo "Fatal: $*"
    exit 1
}

function removeRepo()
{
    local repo="$*"

    eopkg remove-repo "$repo" || do_die "Failed to remove repo: $repo"
}

function listRepos()
{
    echo /var/lib/eopkg/index/* | sed 's@/var/lib/eopkg/index/@@g'
}

function removePackage()
{
    local pkg="$*"

    eopkg rm --ignore-safety --ignore-comar "$pkg"
}

function addRepo()
{
    local repo="$1"
    local url="$2"

    eopkg add-repo "$repo" "$url" || do_die "Failed to add repo: $repo"
}

# Remove all listed repos
if [[ $(ls -A /var/lib/eopkg/index/) ]]; then
    for repo in `listRepos` ; do
        removeRepo $repo
    done
fi

# Add the Shannon Solus repo
addRepo Solus "https://packages.solus-project.com/shannon/eopkg-index.xml.xz"

oddPackages=(python-reportlab python-lxml)

for pkg in "${oddPackages[@]}"; do
    # This is fine to fail.
    removePackage "$pkg"
done
