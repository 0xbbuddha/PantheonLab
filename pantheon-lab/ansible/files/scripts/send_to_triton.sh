#!/bin/bash
# Faux script "de communication" contenant le mot de passe en clair
curl -X POST http://internal.okeanos/api \
  -d "user=triton&password=triton123"
