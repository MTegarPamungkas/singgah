#!/usr/bin/env bash
# Pushes the server-side configuration for Singgah's Appwrite Functions.
#
# Run with the Appwrite CLI already pointed at the shared instance:
#   appwrite client --endpoint "$APPWRITE_ENDPOINT" \
#     --project-id "$APPWRITE_PROJECT_ID" --key "$APPWRITE_API_KEY"
#
# Values are read from the environment so no secret ever lands in the repo.
set -euo pipefail

: "${APPWRITE_API_KEY:?APPWRITE_API_KEY is required}"

FUNCTIONS=(accept-titipan parse-reminder geocode notify-titipan social send-titipan chat)

# Functions run in the runtimes network. Locally the Appwrite API is reachable
# through host.docker.internal; in production use the public HTTPS endpoint.
FUNCTION_ENDPOINT="${APPWRITE_FUNCTION_ENDPOINT:-http://host.docker.internal/v1}"

# create-or-update <function-id> <variable-id> <key> <value> [secret]
create_or_update() {
  local function_id="$1" variable_id="$2" key="$3" value="$4" secret="${5:-}"
  local extra=()
  if [[ "$secret" == "secret" ]]; then extra+=(--secret); fi

  if appwrite functions create-variable \
      --function-id "$function_id" \
      --variable-id "$variable_id" \
      --key "$key" \
      --value "$value" \
      "${extra[@]}" >/dev/null 2>&1; then
    echo "created $function_id/$key"
  else
    appwrite functions update-variable \
      --function-id "$function_id" \
      --variable-id "$variable_id" \
      --key "$key" \
      --value "$value" \
      "${extra[@]}" >/dev/null
    echo "updated $function_id/$key"
  fi
}

for fn in "${FUNCTIONS[@]}"; do
  # The Functions use this server key for privileged table access (invite
  # acceptance, AI/geocode quota, cache writes, FCM push). It never reaches the
  # client.
  create_or_update "$fn" "${fn}_api_key" APPWRITE_API_KEY "$APPWRITE_API_KEY" secret
  create_or_update "$fn" "${fn}_endpoint" APPWRITE_ENDPOINT "$FUNCTION_ENDPOINT"
done

if [[ -n "${GEMINI_API_KEY:-}" ]]; then
  create_or_update parse-reminder parse_gemini_key GEMINI_API_KEY "$GEMINI_API_KEY" secret
fi
if [[ -n "${GEMINI_MODEL:-}" ]]; then
  create_or_update parse-reminder parse_gemini_model GEMINI_MODEL "$GEMINI_MODEL"
fi
if [[ -n "${OSM_USER_AGENT:-}" ]]; then
  create_or_update geocode geocode_osm_agent OSM_USER_AGENT "$OSM_USER_AGENT"
fi

echo "Function configuration is up to date."



