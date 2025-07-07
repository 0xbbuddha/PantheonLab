#!/bin/bash
# Script de sync des scores
smbclient //pantheon-dc01.pantheon.god/scores -U 'smbscores'%'Sc0r3sS3rv1c3!2024' -c "put /srv/olympe/scores/scores.txt" 