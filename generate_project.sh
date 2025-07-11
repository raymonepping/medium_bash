#!/usr/bin/env bash
set -euo pipefail

# 📌 Usage
if [[ "${1:-}" != "--project" || -z "${2:-}" ]]; then
  echo "Usage: $0 --project <project-name>"
  exit 1
fi

PROJECT_NAME="$2"
SANITY_CHECK_CMD="sanity_check"
DEFAULT_GITIGNORE="$HOME/.gitignore_global"
COMMIT_SCRIPT_NAME="commit_gh"
COMMIT_SCRIPT_FALLBACK="$HOME/Documents/GitHub/---scripting/Couchbase/Docker/$COMMIT_SCRIPT_NAME"

# 🔧 Prerequisites
for bin in git gh; do
  if ! command -v "$bin" &>/dev/null; then
    echo "❌ Required tool missing: $bin"
    exit 1
  fi
done

# 🏗️ Create structure
mkdir -p "$PROJECT_NAME"
cd "$PROJECT_NAME"

echo "📁 Created project: $PROJECT_NAME"

# 📄 .gitignore (fallback logic)
if [[ -f "$DEFAULT_GITIGNORE" ]]; then
  cp "$DEFAULT_GITIGNORE" .gitignore
elif [[ -f "$COMMIT_SCRIPT_FALLBACK" ]]; then
  cp "$COMMIT_SCRIPT_FALLBACK" .gitignore
else
  echo "# Auto-generated .gitignore" >.gitignore
fi

# 📄 Init files with full license and README
curl -s https://www.gnu.org/licenses/gpl-3.0.txt >LICENSE

cat >README.md <<EOF
# $PROJECT_NAME

Automation scripts and utilities for shell-based workflows.

> This project was scaffolded automatically using \`generate_project.sh\`.

## License

[GPLv3](LICENSE)
EOF

touch .env

# 📜 Optional commit script
if command -v "$COMMIT_SCRIPT_NAME" &>/dev/null; then
  echo "✅ Using global $COMMIT_SCRIPT_NAME"
elif [[ -f "$COMMIT_SCRIPT_NAME" ]]; then
  echo "✅ Using local $COMMIT_SCRIPT_NAME"
elif [[ -f "$COMMIT_SCRIPT_FALLBACK" ]]; then
  cp "$COMMIT_SCRIPT_FALLBACK" ./
  echo "✅ Copied fallback $COMMIT_SCRIPT_NAME"
else
  echo "⚠️ $COMMIT_SCRIPT_NAME not found"
fi

# 🧪 Run sanity_check
if command -v "$SANITY_CHECK_CMD" &>/dev/null; then
  echo "🧪 Running sanity_check..."
  find . -type f \( -name "*.sh" -o -name "*.py" -o -name "*.js" -o -name "*.tf" -o -name "Dockerfile" \) \
    -exec "$SANITY_CHECK_CMD" --fix --report {} +
else
  echo "⚠️ $SANITY_CHECK_CMD not found — skipping"
fi

# 🌀 Git + GitHub
git init

# 🪝 Git hook for sanity_check
HOOK_PATH=".git/hooks/pre-commit"
if command -v "$SANITY_CHECK_CMD" &>/dev/null; then
  echo "🪝 Installing pre-commit git hook..."
  cat >"$HOOK_PATH" <<'EOF'
#!/bin/bash
set -euo pipefail

# Only run sanity_check if files are staged
STAGED_FILES=$(git diff --cached --name-only --diff-filter=ACM | grep -E '\.sh$|\.py$|\.js$|\.tf$|Dockerfile$' || true)

if [[ -n "\$STAGED_FILES" ]]; then
  echo "🔍 Pre-commit: running sanity_check on staged files..."
  echo "\$STAGED_FILES" | xargs sanity_check --fix --quiet
fi
EOF
  chmod +x "$HOOK_PATH"
else
  echo "⚠️ sanity_check not available, skipping git hook setup"
fi

git add .
git commit -m "Initial commit for $PROJECT_NAME"
gh repo create "$PROJECT_NAME" --public --source=. --remote=origin --push
git branch -M main
git push -u origin main

echo -e "\n✅ Project '$PROJECT_NAME' scaffolded, sanity-checked, and pushed to GitHub!"
