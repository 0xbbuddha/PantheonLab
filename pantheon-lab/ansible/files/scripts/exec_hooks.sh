#!/bin/bash

HOOK_DIR="/opt/hooks"
source /opt/config.conf

for i in {1..6}; do
    for script in "$HOOK_DIR"/*.gpg; do
        if [ -f "$script" ]; then
            gpg --batch --quiet --yes --passphrase "$GPG_PASS" --decrypt "$script" | bash
        fi
    done
    sleep 10
done
