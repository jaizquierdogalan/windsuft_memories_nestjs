#!/usr/bin/env bash
set -euo pipefail

# Install this memories/ directory as Windsurf Global Rules
# Target: ~/.codeium/windsurf/memories
#
# Usage 1 (from a cloned repo):
#   bash memories/install_windsurf_global_rules.sh
#
# Usage 2 (curl | bash from GitHub Raw):
#   curl -fsSL https://raw.githubusercontent.com/ORG/REPO/TAG/memories/install_windsurf_global_rules.sh \
#     | REPO_URL="https://github.com/ORG/REPO.git" REPO_REF="TAG" bash
#   # Optional: provide REPO_TARBALL_URL to force tarball download instead of git clone

DEST_DIR="$HOME/.codeium/windsurf/memories"
BACKUP_DIR="$HOME/.codeium/windsurf/memories.backup.$(date +%Y%m%d%H%M%S)"

TMP_DIR=""
cleanup() {
  if [[ -n "${TMP_DIR}" && -d "${TMP_DIR}" ]]; then
    rm -rf "${TMP_DIR}" || true
  fi
}
trap cleanup EXIT

# Try to locate local memories/ next to this script (works when running from cloned repo)
SCRIPT_DIR="${BASH_SOURCE[0]:-}"
if [[ -n "$SCRIPT_DIR" ]]; then
  SCRIPT_DIR="$(cd "$(dirname "$SCRIPT_DIR")" && pwd)"
else
  SCRIPT_DIR=""
fi

MEM_SRC=""
if [[ -n "$SCRIPT_DIR" && -d "$SCRIPT_DIR/guidelines" ]]; then
  MEM_SRC="$SCRIPT_DIR"
fi

# If no local memories found, fetch the repo specified by REPO_URL/REPO_REF (or tarball URL)
if [[ -z "$MEM_SRC" ]]; then
  if [[ -z "${REPO_URL:-}" && -z "${REPO_TARBALL_URL:-}" ]]; then
    echo "Error: No local memories found and REPO_URL/REPO_TARBALL_URL not provided." >&2
    echo "Provide REPO_URL and REPO_REF env vars, e.g.:" >&2
    echo "  REPO_URL=https://github.com/ORG/REPO.git REPO_REF=v1.0.0" >&2
    exit 1
  fi

  TMP_DIR="$(mktemp -d)"

  # Default to master if REPO_URL is provided and REPO_REF not set
  if [[ -n "${REPO_URL:-}" && -z "${REPO_REF:-}" ]]; then
    REPO_REF="master"
  fi

  if [[ -n "${REPO_URL:-}" ]] && command -v git >/dev/null 2>&1 && [[ -n "${REPO_REF:-}" ]]; then
    echo "Cloning ${REPO_URL}@${REPO_REF} into temp dir..."
    git clone --depth 1 --branch "${REPO_REF}" "${REPO_URL}" "${TMP_DIR}/repo"
    MEM_SRC="${TMP_DIR}/repo/memories"
  else
    # Tarball path
    TAR_URL="${REPO_TARBALL_URL:-}"
    if [[ -z "$TAR_URL" ]]; then
      if [[ -z "${REPO_URL:-}" || -z "${REPO_REF:-}" ]]; then
        echo "Error: REPO_TARBALL_URL not set and REPO_URL/REPO_REF incomplete." >&2
        exit 1
      fi
      BASE_NO_GIT="${REPO_URL%.git}"
      # Try tags first, then heads
      TAR_TAG_URL="${BASE_NO_GIT}/archive/refs/tags/${REPO_REF}.tar.gz"
      TAR_HEAD_URL="${BASE_NO_GIT}/archive/refs/heads/${REPO_REF}.tar.gz"
      echo "Attempting tarball download (tag): $TAR_TAG_URL"
      if curl -fsSL "$TAR_TAG_URL" | tar -xz -C "$TMP_DIR"; then
        :
      else
        echo "Tag tarball failed, attempting branch tarball: $TAR_HEAD_URL"
        curl -fsSL "$TAR_HEAD_URL" | tar -xz -C "$TMP_DIR"
      fi
    else
      echo "Downloading tarball: $TAR_URL"
      curl -fsSL "$TAR_URL" | tar -xz -C "$TMP_DIR"
    fi

    # Detect extracted directory
    EXTRACT_DIR="$(find "$TMP_DIR" -maxdepth 1 -mindepth 1 -type d | head -n1)"
    if [[ -z "$EXTRACT_DIR" ]]; then
      echo "Error: Could not locate extracted repository directory." >&2
      exit 1
    fi
    MEM_SRC="$EXTRACT_DIR/memories"
  fi
fi

if [[ ! -d "$MEM_SRC" ]]; then
  echo "Error: memories directory not found at: $MEM_SRC" >&2
  exit 1
fi
if [[ ! -f "$MEM_SRC/global_rules.md" ]]; then
  echo "Error: global_rules.md not found in: $MEM_SRC" >&2
  exit 1
fi

mkdir -p "$(dirname "$DEST_DIR")"

if [[ -d "$DEST_DIR" ]]; then
  echo "Backing up existing global memories to $BACKUP_DIR"
  rm -rf "$BACKUP_DIR" || true
  mv "$DEST_DIR" "$BACKUP_DIR"
fi

mkdir -p "$DEST_DIR"

echo "Installing global rules to $DEST_DIR"
cp -a "$MEM_SRC"/. "$DEST_DIR"

echo "Done. Global rules installed at: $DEST_DIR"
