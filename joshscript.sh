#!/bin/bash

set -euo pipefail

BORG_REPO_PASS=$1
export BORG_PASSPHRASE=$BORG_REPO_PASS # https://torsion.org/borgmatic/reference/configuration/environment-variables/

cd $HOME
borgmatic extract --archive latest --path home/josh --progress
