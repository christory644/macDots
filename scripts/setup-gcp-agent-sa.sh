#!/usr/bin/env bash
#
# Create a per-developer limited GCP service account for AI coding agents.
# Each dev gets their own SA so agent activity is traceable per person.
# Agents impersonate this SA so they can't use your admin creds.
#
# Usage: ./setup-gcp-agent-sa.sh <project-id> [username]
#
# Examples:
#   ./setup-gcp-agent-sa.sh my-project              # uses $(whoami) → claude-agent-christopherstory
#   ./setup-gcp-agent-sa.sh my-project alice         # → claude-agent-alice
#
# After running this script:
# 1. Add the SA email to .zshenv_secrets:
#      export GCP_AGENT_SA="claude-agent-<you>@<project-id>.iam.gserviceaccount.com"
# 2. Add the MCPs to your work Claude config:
#      CLAUDE_CONFIG_DIR=~/.claude-work claude mcp add gcloud -- npx -y @google-cloud/gcloud-mcp
#      CLAUDE_CONFIG_DIR=~/.claude-work claude mcp add observability -- npx -y @google-cloud/observability-mcp

set -euo pipefail

PROJECT_ID="${1:?Usage: $0 <project-id> [username]}"
DEV_NAME="${2:-$(whoami)}"
SA_NAME="claude-agent-${DEV_NAME}"

# SA names must be 6-30 chars, lowercase alphanumeric + hyphens
SA_NAME=$(echo "$SA_NAME" | tr '[:upper:]' '[:lower:]' | sed 's/[^a-z0-9-]/-/g' | cut -c1-30)
SA_EMAIL="${SA_NAME}@${PROJECT_ID}.iam.gserviceaccount.com"

echo "==> Creating service account: ${SA_EMAIL}"
gcloud iam service-accounts create "$SA_NAME" \
  --project="$PROJECT_ID" \
  --display-name="Claude Agent — ${DEV_NAME}" \
  --description="AI coding agent SA for ${DEV_NAME} (impersonated via CLOUDSDK_AUTH_IMPERSONATE_SERVICE_ACCOUNT)" \
  2>/dev/null || echo "    (already exists)"

echo ""
echo "==> Granting read-only roles..."

# Spanner: read data + schema, no mutations
gcloud projects add-iam-policy-binding "$PROJECT_ID" \
  --member="serviceAccount:${SA_EMAIL}" \
  --role="roles/spanner.databaseReader" \
  --condition=None --quiet

# Viewer: see project resources (instances, services, etc.)
gcloud projects add-iam-policy-binding "$PROJECT_ID" \
  --member="serviceAccount:${SA_EMAIL}" \
  --role="roles/viewer" \
  --condition=None --quiet

# Logs: read logs for debugging
gcloud projects add-iam-policy-binding "$PROJECT_ID" \
  --member="serviceAccount:${SA_EMAIL}" \
  --role="roles/logging.viewer" \
  --condition=None --quiet

# Monitoring: read metrics
gcloud projects add-iam-policy-binding "$PROJECT_ID" \
  --member="serviceAccount:${SA_EMAIL}" \
  --role="roles/monitoring.viewer" \
  --condition=None --quiet

echo ""
echo "==> Granting your account permission to impersonate the SA..."

# Allow YOUR identity to impersonate this SA (no key file needed)
CURRENT_USER=$(gcloud config get-value account 2>/dev/null)
gcloud iam service-accounts add-iam-policy-binding "$SA_EMAIL" \
  --project="$PROJECT_ID" \
  --member="user:${CURRENT_USER}" \
  --role="roles/iam.serviceAccountTokenCreator" \
  --quiet

echo ""
echo "==> Done! Service account: ${SA_EMAIL}"
echo "    Developer: ${DEV_NAME}"
echo ""
echo "Next steps:"
echo ""
echo "  1. Add to your secrets file:"
echo "     echo 'export GCP_AGENT_SA=\"${SA_EMAIL}\"' >> ~/repos/macDots/.zshenv_secrets"
echo ""
echo "  2. Add MCPs to work Claude config:"
echo "     CLAUDE_CONFIG_DIR=~/.claude-work claude mcp add gcloud -- npx -y @google-cloud/gcloud-mcp"
echo "     CLAUDE_CONFIG_DIR=~/.claude-work claude mcp add observability -- npx -y @google-cloud/observability-mcp"
echo ""
echo "  3. Rebuild and source:"
echo "     rebuild && source ~/.zshrc"
echo ""
echo "  4. Test impersonation:"
echo "     CLOUDSDK_AUTH_IMPERSONATE_SERVICE_ACCOUNT=${SA_EMAIL} gcloud spanner instances list --project=${PROJECT_ID}"
echo ""
echo "Roles granted (all read-only):"
echo "  - spanner.databaseReader  (read Spanner data + schema)"
echo "  - viewer                  (see project resources)"
echo "  - logging.viewer          (read logs)"
echo "  - monitoring.viewer       (read metrics)"
echo ""
echo "To add write permissions later (e.g., for agents that create PRs/branches):"
echo "  gcloud projects add-iam-policy-binding ${PROJECT_ID} \\"
echo "    --member='serviceAccount:${SA_EMAIL}' \\"
echo "    --role='roles/spanner.databaseUser'"
