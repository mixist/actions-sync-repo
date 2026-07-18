#!/usr/bin/env bash
set -euo pipefail

target_url="${INPUT_TARGET_URL}"
target_username="${INPUT_TARGET_USERNAME}"
target_token="${INPUT_TARGET_TOKEN}"
force_push="${INPUT_TARGET_FORCE_PUSH:-false}"
mirror="${INPUT_MIRROR:-false}"

if [[ ! "${target_url}" =~ ^https?:// ]]; then
  echo "::error::target-url must be an http(s) URL (got: ${target_url})"
  exit 1
fi

# --- optionally skip unless the version field changed across the push ---------
if [[ "${INPUT_ONLY_ON_VERSION_CHANGE:-false}" == "true" ]]; then
  version_file="${INPUT_VERSION_FILE:-package.json}"
  before_ref="${INPUT_BEFORE_REF:-}"
  zero_sha="0000000000000000000000000000000000000000"

  if [[ -z "${before_ref}" || "${before_ref}" == "${zero_sha}" ]]; then
    echo "No valid before ref; treating version as changed."
  else
    before_json=$(git show "${before_ref}:${version_file}" 2>/dev/null || echo '{}')
    before_version=$(printf '%s' "${before_json}" | jq -r '.version // ""' 2>/dev/null || echo '')
    after_version=$(jq -r '.version // ""' "${version_file}" 2>/dev/null || echo '')
    echo "version before=${before_version} after=${after_version}"
    if [[ "${before_version}" == "${after_version}" ]]; then
      echo "${version_file} version unchanged; skipping sync."
      exit 0
    fi
  fi
fi

# --- authenticate via an HTTP header, keeping the token out of the remote URL
# --- and out of .git/config (which git may echo on push errors) --------------
basic_auth=$(printf '%s:%s' "${target_username}" "${target_token}" | base64 | tr -d '\n')

git remote add target "${target_url}" 2>/dev/null \
  || git remote set-url target "${target_url}"

push_target() {
  git -c http.extraheader="AUTHORIZATION: basic ${basic_auth}" push "$@"
}

# --- push --------------------------------------------------------------------
if [[ "${mirror}" == "true" ]]; then
  # Faithful mirror: every ref incl. tags, and prune refs deleted on the source.
  # --mirror is inherently forced, so target-force-push does not apply here.
  push_target target --mirror
else
  force_flag=()
  if [[ "${force_push}" == "true" ]]; then
    force_flag=(--force)
  fi
  # --all pushes branches only; tags need a second push (--all and --tags are
  # incompatible in a single invocation).
  push_target target --all "${force_flag[@]}"
  push_target target --tags "${force_flag[@]}"
fi
