#!/bin/sh

set -e
set -u

cimi_super="curl -ksSL -H 'content-type: application/json' -H 'slipstream-authn-info: bootstrap ADMIN'"
# shellcheck disable=SC2139
alias cimi_super_get="$cimi_super -XGET"
# shellcheck disable=SC2139
alias cimi_super_post="$cimi_super --fail -o /dev/null -XPOST"
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

echo "Performing special bootstrap steps..."
user_count="$(cimi_super_get "$CIMI_URL/api/user" | jq '.count')"
if [ "$user_count" -eq 0 ]; then
    echo "No existing mF2C users found, registering initial user."
    echo "The MF2C_USER and MF2C_PASS environemnt variables must be set!"
    # also conveniently fails if this isn't set
    echo "They are MF2C_USER=$MF2C_USER and MF2C_PASS=$MF2C_PASS"

    envsubst <resources/special/first-user.json >resources/special/first-user-envsubst.json

    filename="resources/special/first-user-envsubst.json"
    echo "    submitting $filename"
    abs_filename="$(realpath "$filename")"
    cimi_super_post -d "@$abs_filename" "$CIMI_URL/api/user"
else
    echo "At least one user exists in the system ($user_count)."
fi


echo "Bootstrapping services..."
for filename in resources/services/*; do
    [ -e "$filename" ] || continue
    echo "    submitting $filename"
    abs_filename="$(realpath "$filename")"
    cimi_super_post -d "@$abs_filename" "$CIMI_URL/api/service"
done

echo "Bootstrapping session templates..."
for filename in resources/session-templates/*; do
    [ -e "$filename" ] || continue
    echo "    submitting $filename"
    abs_filename="$(realpath "$filename")"
    cimi_super_post -d "@$abs_filename" "$CIMI_URL/api/session-template"
done

echo "    done!"
