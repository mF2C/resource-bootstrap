#!/bin/sh

set -e
set -u

cimi_super="curl -ksSL -H 'content-type: application/json' -H 'slipstream-authn-info: bootstrap ADMIN'"
# shellcheck disable=SC2139
alias cimi_super_get="$cimi_super -XGET"
# shellcheck disable=SC2139
alias cimi_super_post="$cimi_super --fail -o /dev/null -XPOST"
# shellcheck disable=SC2139
alias cimi_super_put="$cimi_super --fail -o /dev/null -XPUT"
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
    echo "    the MF2C_USER and MF2C_PASS environemnt variables must be set!"
    # also conveniently fails if this isn't set
    echo "    they are MF2C_USER=$MF2C_USER and MF2C_PASS=$MF2C_PASS"
    printf "%${#MF2C_USER}s                   don't look at this %.${#MF2C_PASS}s\n" \
        " " \
        "^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^"

    envsubst <resources/special/first-user.json >resources/special/first-user-envsubst.json

    filename="resources/special/first-user-envsubst.json"
    echo "    submitting $filename"
    abs_filename="$(realpath "$filename")"
    cimi_super_post -d "@$abs_filename" "$CIMI_URL/api/user"

    echo "    forcing user '$MF2C_USER' into an active state"
    cimi_super_put -d "{\"id\": \"user/$MF2C_USER\", \"state\": \"ACTIVE\"}" "$CIMI_URL/api/user/$MF2C_USER"

    echo "    done!"
else
    echo "At least one user exists in the system ($user_count), doing nothing."
fi

# shellcheck disable=SC2154
if [ -z ${isCloud+nonblank} ]; then
    echo "The isCloud environment variable is not set!"
    echo "Set it to \"true\" to enable service and session template bootstrap. Failing."
    exit 1
fi

# shellcheck disable=SC2154
if ! { [ "$isCloud" = "true" ] || [ "$isCloud" = "True" ]; }; then
    echo "Not in the cloud (isCloud is not exactly \"true\")."
    echo "    Not bootstrapping services, session templates."
    exit 0
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

echo "Done!"
