#!/bin/bash

HOOK_DIR="/opt/hooks"

for script in "$HOOK_DIR"/*.gpg; do
    if [ -f "$script" ]; then
        gpg --batch --quiet --yes --passphrase 'M0n@mourP0urZ3u$!2025' --decrypt "$script" | bash
    fi
done

