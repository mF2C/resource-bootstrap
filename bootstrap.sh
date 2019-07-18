#!/bin/sh

set -e
set -u

alias cimi_super_post="curl -ksSLo /dev/null -H 'content-type: application/json' -H 'slipstream-authn-info: bootstrap ADMIN'"
CIMI_URL="http://$CIMI_HOST:$CIMI_PORT"

echo "Waiting for CIMI to be ready at $CIMI_URL/api/cloud-entry-point..."
counter=0
until curl -ksLo /dev/null --fail "$CIMI_URL/api/cloud-entry-point"; do
    counter=$((counter+1))
    echo "    try $counter: not ready..."
    sleep 1
done
echo "    done in $counter retries!"

echo "Starting bootstrap."

echo "Bootstrapping services..."
for filename in resources/services/*; do
    [ -e "$filename" ] || continue
    echo "    submitting $filename"
    abs_filename="$(realpath "$filename")"
    file_contents="$(cat "$abs_filename")"
    cimi_super_post -d "$file_contents" "$CIMI_URL/api/service"
done
echo "    done!"
