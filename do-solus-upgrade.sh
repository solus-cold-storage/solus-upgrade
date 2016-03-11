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

oddPackages=(python-reportlab python-lxml)
badProcesses=(evolve-sc solus-sc pisi eopkg)

function do_die()
{
    echo "Fatal: $*"
    exit 1
}

function do_eopkg_error()
{
    echo "eopkg upgrade did not complete successfully. Please re-run this script"
    echo "If this issue persists, please seek support and do _not_ reboot"
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

    eopkg rm --ignore-safety --ignore-comar -y "$pkg"
}

function addRepo()
{
    local repo="$1"
    local url="$2"

    eopkg add-repo "$repo" "$url" || do_die "Failed to add repo: $repo"
}

# *REALLY* kill it.
function killComar()
{
    killall -9 comar 2>/dev/null; sleep 1; killall -9 comar 2>/dev/null;
}

# Ensure the given process is *not* running
function checkDead()
{
    local badP="$*"

    if [[ `/bin/ps aux | /bin/grep -v grep | /bin/grep "${badP}"` ]]; then
        do_die "Cannot continue as ${badP} is still running. Please ensure it is closed."
    fi
}

# Remove all listed repos
if [[ $(ls -A /var/lib/eopkg/index/) ]]; then
    for repo in `listRepos` ; do
        removeRepo $repo
    done
fi

# Add the Shannon Solus repo
addRepo Solus "https://packages.solus-project.com/shannon/eopkg-index.xml.xz"

for pkg in "${oddPackages[@]}"; do
    # This is fine to fail.
    removePackage "$pkg"
done

for badPs in "${badProcesses[@]}"; do
    checkDead "${badPs}"
done

# Must be dead due to the Python UCS4 migration
killComar
checkDead comar

# Now we continue with the upgrade, it's up to the user to hit yes.
eopkg upgrade --ignore-comar --ignore-file-conflicts || do_eopkg_error

# Ensure comar really dead.
killComar

# No, seriously.
checkDead comar

# Now configure any pending, bobs your uncle, etc.
eopkg configure-pending

# configure GRUB.
if [[ ! -e /sys/firmware/efi ]]; then
    if [[ -e /boot/grub/grub.cfg ]]; then
        echo "Now updating GRUB2 config"
        sudo update-grub
    fi
fi
