#!/usr/bin/env bash
# Netlify build entry. On Netlify's build image pnpm is already on PATH and
# dependencies were installed in the "Install dependencies" stage, so this just
# runs the normal build. In environments that skip that stage (no pnpm, no
# node_modules), it provides pnpm through corepack and installs from the lockfile first.
set -euo pipefail

if ! command -v pnpm >/dev/null 2>&1; then
  export COREPACK_ENABLE_DOWNLOAD_PROMPT=0
  shim_dir="$(mktemp -d)"
  # package.json scripts call `pnpm` again, so it must exist as a real command on PATH.
  printf '#!/usr/bin/env bash\nexec corepack pnpm@10 "$@"\n' > "$shim_dir/pnpm"
  chmod +x "$shim_dir/pnpm"
  export PATH="$shim_dir:$PATH"
fi

if [ ! -d node_modules ]; then
  # shellcheck disable=SC2086 # PNPM_FLAGS is a space-separated flag list, same as Netlify uses it
  pnpm install ${PNPM_FLAGS:-}
fi

pnpm --filter 'aetheros-simulator...' run build
