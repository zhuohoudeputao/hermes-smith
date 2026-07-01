#!/usr/bin/env bash
set -euo pipefail

# Hermes Smith — Install Script
# Creates the smith profile, copies files, configures Kanban routing.

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SMITH_SRC="${SCRIPT_DIR}/smith"
HERMES_HOME="${HERMES_HOME:-$HOME/.hermes}"
SMITH_PROFILE="${HERMES_HOME}/profiles/smith"

echo "╔══════════════════════════════════════════════╗"
echo "║         Hermes Smith — Installer              ║"
echo "╚══════════════════════════════════════════════╝"
echo ""

# ── Check Hermes is installed ──────────────────────────────────────
if ! command -v hermes &>/dev/null; then
    echo "✗ Hermes Agent is not installed or not on PATH."
    echo "  Install it first: curl -fsSL https://hermes-agent.nousresearch.com/install.sh | bash"
    exit 1
fi
echo "✓ Hermes Agent found: $(hermes --version 2>/dev/null || echo 'version unknown')"

# ── Check source files exist ───────────────────────────────────────
if [ ! -f "${SMITH_SRC}/SOUL.md" ]; then
    echo "✗ Smith source files not found at ${SMITH_SRC}"
    echo "  Make sure you're running this from the repo root."
    exit 1
fi
echo "✓ Source files found"

# ── Check if smith profile already exists ──────────────────────────
if [ -d "${SMITH_PROFILE}" ]; then
    echo "⚠  Profile 'smith' already exists at ${SMITH_PROFILE}"
    read -p "  Overwrite? (y/N) " -r
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "  Aborted."
        exit 0
    fi
    echo "  Deleting existing smith profile..."
    echo "smith" | hermes profile delete smith 2>/dev/null || true
fi

# ── Create the smith profile ───────────────────────────────────────
echo ""
echo "── Creating smith profile ──────────────────────────"
hermes profile create smith --clone \
    --description "Meta-agent that builds and routes Hermes profiles"
echo "✓ Profile created"

# ── Copy SOUL.md ───────────────────────────────────────────────────
echo ""
echo "── Copying SOUL.md ─────────────────────────────────"
cp "${SMITH_SRC}/SOUL.md" "${SMITH_PROFILE}/SOUL.md"
echo "✓ SOUL.md copied"

# ── Copy profile-smith skill ───────────────────────────────────────
echo ""
echo "── Copying skills ──────────────────────────────────"
SKILL_DIR="${SMITH_PROFILE}/skills/profile-smith"
mkdir -p "${SKILL_DIR}/references"
cp "${SMITH_SRC}/skills/profile-smith/SKILL.md" "${SKILL_DIR}/SKILL.md"
cp "${SMITH_SRC}/skills/profile-smith/references/kanban-routing-details.md" \
   "${SKILL_DIR}/references/kanban-routing-details.md" 2>/dev/null || true
echo "✓ profile-smith skill copied"

# ── Copy smith-team skill ──────────────────────────────────────────
TEAM_DIR="${SMITH_PROFILE}/skills/smith-team"
mkdir -p "${TEAM_DIR}"
cp "${SMITH_SRC}/skills/smith-team/SKILL.md" "${TEAM_DIR}/SKILL.md" 2>/dev/null || true
echo "✓ smith-team skill copied"

# ── Copy templates ──────────────────────────────────────────────────
echo ""
echo "── Copying templates ───────────────────────────────"
mkdir -p "${SMITH_PROFILE}/templates"
cp "${SMITH_SRC}/templates/profiles.yaml" "${SMITH_PROFILE}/templates/profiles.yaml"
cp "${SMITH_SRC}/templates/skill-recommendations.yaml" "${SMITH_PROFILE}/templates/skill-recommendations.yaml"
echo "✓ Templates copied (6 profile templates + skill recommender)"

# ── Copy profile.yaml ──────────────────────────────────────────────
echo ""
echo "── Copying profile.yaml ────────────────────────────"
cp "${SMITH_SRC}/profile.yaml" "${SMITH_PROFILE}/profile.yaml"
echo "✓ Profile metadata copied"

# ── Configure Kanban routing ───────────────────────────────────────
echo ""
echo "── Configuring Kanban routing ──────────────────────"
hermes config set kanban.default_assignee smith
hermes config set kanban.auto_decompose false
hermes -p smith config set kanban.default_assignee smith
hermes -p smith config set kanban.orchestrator_profile smith
hermes -p smith config set kanban.auto_decompose false
echo "✓ Kanban routing configured"

# ── Verify ─────────────────────────────────────────────────────────
echo ""
echo "── Verifying ───────────────────────────────────────"
hermes profile show smith
echo ""

echo "╔══════════════════════════════════════════════╗"
echo "║  ✓ Smith installed successfully!              ║"
echo "╠══════════════════════════════════════════════╣"
echo "║                                              ║"
echo "║  Interactive mode:                           ║"
echo "║    smith chat                                ║"
echo "║                                              ║"
echo "║  Task router mode:                           ║"
echo "║    hermes kanban create \"Task\" --body \"...\"  ║"
echo "║    hermes gateway start                      ║"
echo "║                                              ║"
echo "║  Or dispatch manually:                       ║"
echo "║    hermes kanban dispatch                    ║"
echo "║                                              ║"
echo "╚══════════════════════════════════════════════╝"
