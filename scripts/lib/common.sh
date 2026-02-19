#!/usr/bin/env bash
# Common shell functions for CI workflows
# DO NOT execute this file directly - source it from other scripts

set -euo pipefail

# Guard against direct execution
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  echo "Error: This script should be sourced, not executed directly"
  echo "Usage: source ${BASH_SOURCE[0]}"
  exit 1
fi

# Check for OpenCode fatal errors in output file
# Args:
#   $1: output_file - path to file containing command output
#   $2: context - description of operation context for error messages
# Returns:
#   0 if no fatal errors found
#   1 if fatal errors detected
check_opencode_fatal_errors() {
  local output_file="$1"
  local context="$2"
  if [ -f "$output_file" ]; then
    if grep -qi "ProviderModelNotFoundError\|ModelNotFoundError\|model not found\|provider.*not found" "$output_file"; then
      echo "OpenCode fatal error detected during $context:"
      grep -i "ProviderModelNotFoundError\|ModelNotFoundError\|model not found\|provider.*not found\|providerID\|modelID" "$output_file" | head -10
      echo ""
      echo "Hint: Run 'opencode models' on the runner to see available models."
      return 1
    fi
    if grep -qi "AuthenticationError\|API key.*invalid\|Unauthorized" "$output_file"; then
      echo "OpenCode authentication error detected during $context:"
      grep -i "AuthenticationError\|API key.*invalid\|Unauthorized" "$output_file" | head -5
      return 1
    fi
  fi
  return 0
}

# Ensure required dependencies are installed
# Checks: jq, opencode, gh
# Returns:
#   0 if all dependencies present
#   1 if any dependency missing
ensure_dependencies() {
  local missing=()
  
  if ! command -v jq &>/dev/null; then
    missing+=("jq")
  fi
  
  if ! command -v opencode &>/dev/null; then
    missing+=("opencode")
  fi
  
  if ! command -v gh &>/dev/null; then
    missing+=("gh")
  fi
  
  if [ ${#missing[@]} -gt 0 ]; then
    echo "Missing required dependencies: ${missing[*]}"
    return 1
  fi
  
  return 0
}

# Install GitHub CLI if not present
# Uses apt package manager (Ubuntu/Debian)
# Returns:
#   0 on success
#   1 on failure
install_gh_cli() {
  if ! command -v gh &>/dev/null; then
    echo "Installing gh CLI..."
    type -p curl >/dev/null || (sudo apt update && sudo apt install curl -y)
    curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | sudo dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg
    sudo chmod go+r /usr/share/keyrings/githubcli-archive-keyring.gpg
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | sudo tee /etc/apt/sources.list.d/github-cli.list > /dev/null
    sudo apt update
    sudo apt install gh -y
    echo "gh CLI installed"
  else
    echo "gh CLI already installed"
  fi
}

# Safety check for forbidden path modifications
# Args:
#   $1: auto_revert - "true" to auto-revert violations, "false" to only report
# Returns:
#   0 if no violations or all reverted
#   1 if violations found and auto_revert=false
safety_check() {
  local auto_revert="${1:-false}"
  local FORBIDDEN_PATTERNS=(".github/" "config/" "scripts/" "deploy.sh" ".env" "docker-compose" "Dockerfile")
  
  # Collect all changed files: tracked modifications + untracked new files
  local CHANGED_FILES
  CHANGED_FILES=$(git diff --name-only HEAD; git ls-files --others --exclude-standard)
  
  if [ -z "$CHANGED_FILES" ]; then
    echo "No changes detected"
    return 0
  fi
  
  local VIOLATIONS_FOUND=false
  for pattern in "${FORBIDDEN_PATTERNS[@]}"; do
    local MATCHED
    MATCHED=$(echo "$CHANGED_FILES" | grep "$pattern" || true)
    if [ -n "$MATCHED" ]; then
      echo "WARNING: Forbidden path detected: $pattern"
      echo "$MATCHED"
      
      if [ "$auto_revert" = "true" ]; then
        # Auto-revert tracked files
        echo "$MATCHED" | while read -r f; do
          if [ -f "$f" ]; then
            git checkout HEAD -- "$f" 2>/dev/null && echo "   Reverted: $f" || true
            if git ls-files --others --exclude-standard | grep -q "^${f}$"; then
              rm -f "$f" && echo "   Removed untracked: $f"
            fi
          fi
        done
      fi
      
      VIOLATIONS_FOUND=true
    fi
  done
  
  if [ "$VIOLATIONS_FOUND" = true ]; then
    if [ "$auto_revert" = "true" ]; then
      echo "WARNING: Forbidden path changes were auto-reverted. Continuing."
      return 0
    else
      echo "Forbidden path violations detected"
      return 1
    fi
  fi
  
  echo "Safety check passed"
  return 0
}

# Export variable to GitHub Actions environment
# Handles multi-line values safely
# Args:
#   $1: var_name - environment variable name
#   $2: var_value - environment variable value (can be multi-line)
export_to_github_env() {
  local var_name="$1"
  local var_value="$2"
  
  if [ -z "${GITHUB_ENV:-}" ]; then
    echo "WARNING: GITHUB_ENV not set, skipping export of $var_name"
    return 0
  fi
  
  # Use heredoc delimiter for multi-line safety
  {
    echo "${var_name}<<EOF_${var_name}"
    echo "$var_value"
    echo "EOF_${var_name}"
  } >> "$GITHUB_ENV"
}

# Render a template file by replacing {{VAR}} placeholders with environment variable values
# Args:
#   $1: template_file - path to template file with {{VAR}} placeholders
# Returns:
#   Rendered template content to stdout
# Example:
#   export ISSUE_NUMBER=123
#   export TITLE="Fix bug"
#   render_template ".github/scripts/templates/agent-prompt.md"
render_template() {
  local template_file="$1"
  
  if [ ! -f "$template_file" ]; then
    echo "Error: Template file not found: $template_file" >&2
    return 1
  fi
  
  local content
  content=$(cat "$template_file")
  
  # Replace {{VAR}} with environment variable values
  # Use perl for reliable multi-line replacement
  echo "$content" | perl -pe 's/\{\{(\w+)\}\}/defined $ENV{$1} ? $ENV{$1} : "{{$1}}"/ge'
}

