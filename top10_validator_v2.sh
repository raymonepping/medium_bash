#!/usr/bin/env bash
# top10_validator.sh: Check a script against our Bash Top 10 (Color + Markdown)

set -euo pipefail

# --- Functions for color ---
color_reset="\033[0m"
color_red="\033[31m"
color_yellow="\033[33m"
color_green="\033[32m"
color_bold="\033[1m"

CROSS="❌"
WARN="🟠"
CHECK="✅"

# --- Top10 rule definitions ---
declare -a RULES
declare -a STATUS
declare -a MARKS

RULES[10]="Shebang: Portable interpreter (#!/usr/bin/env bash)"
RULES[9]="Help flag/usage info present"
RULES[8]="Uses Bash [[ ... ]] tests"
RULES[7]="Uses local in functions"
RULES[6]="ShellCheck disables found, review context"
RULES[5]="Variables are quoted"
RULES[4]="File listing: Uses find/globs, avoids ls"
RULES[3]="Strict error handling: set -euo pipefail"
RULES[2]="Nonzero exit codes for error"
RULES[1]="Uses awk for structured data, sed only for simple replacements"

# --- Usage/help ---
if [[ $# -lt 1 || "${1:-}" =~ ^(-h|--help)$ ]]; then
  echo "Usage: $0 <script.sh> [--md|--markdown]"
  echo "Checks a Bash script against our Top 10 scripting best practices."
  echo "With --md or --markdown, writes results to scriptname_top10.md."
  exit 0
fi

SCRIPT="$1"
MD_OUT=false
[[ "${2:-}" =~ (--md|--markdown) ]] && MD_OUT=true

if [[ ! -f "$SCRIPT" ]]; then
  echo -e "${color_red}Error: File '$SCRIPT' does not exist.${color_reset}" >&2
  exit 1
fi

# --- Scan rules ---
# 10: Shebang
if head -n1 "$SCRIPT" | grep -qE '^#!'; then
  if head -n1 "$SCRIPT" | grep -q '/usr/bin/env bash'; then
    STATUS[10]="${color_green}${CHECK} best${color_reset}"
    MARKS[10]=":white_check_mark: best"
  else
    STATUS[10]="${color_yellow}${WARN} better${color_reset}"
    MARKS[10]=":large_orange_circle: better"
  fi
else
  STATUS[10]="${color_red}${CROSS} bad${color_reset}"
  MARKS[10]=":x: bad"
fi

# 9: Help flag or usage
if grep -q -E '(-h|--help)' "$SCRIPT"; then
  STATUS[9]="${color_green}${CHECK} best${color_reset}"
  MARKS[9]=":white_check_mark: best"
elif grep -q -i 'usage' "$SCRIPT"; then
  STATUS[9]="${color_yellow}${WARN} better${color_reset}"
  MARKS[9]=":large_orange_circle: better"
else
  STATUS[9]="${color_red}${CROSS} bad${color_reset}"
  MARKS[9]=":x: bad"
fi

# 8: [[ ... ]] test usage
if grep -q '\[\[' "$SCRIPT"; then
  STATUS[8]="${color_green}${CHECK} best${color_reset}"
  MARKS[8]=":white_check_mark: best"
elif grep -q '\[ ' "$SCRIPT"; then
  STATUS[8]="${color_yellow}${WARN} better${color_reset}"
  MARKS[8]=":large_orange_circle: better"
else
  STATUS[8]="${color_red}${CROSS} bad${color_reset}"
  MARKS[8]=":x: bad"
fi

# 7: local in functions
if grep -q 'local ' "$SCRIPT"; then
  STATUS[7]="${color_green}${CHECK} best${color_reset}"
  MARKS[7]=":white_check_mark: best"
elif grep -q '()' "$SCRIPT"; then
  STATUS[7]="${color_yellow}${WARN} better${color_reset}"
  MARKS[7]=":large_orange_circle: better"
else
  STATUS[7]="${color_red}${CROSS} bad${color_reset}"
  MARKS[7]=":x: bad"
fi

# 6: ShellCheck disables
if grep -q 'shellcheck disable' "$SCRIPT"; then
  STATUS[6]="${color_yellow}${WARN} better${color_reset}"
  MARKS[6]=":large_orange_circle: better"
elif grep -q 'shellcheck' "$SCRIPT"; then
  STATUS[6]="${color_green}${CHECK} best${color_reset}"
  MARKS[6]=":white_check_mark: best"
else
  STATUS[6]="${color_red}${CROSS} bad${color_reset}"
  MARKS[6]=":x: bad"
fi

# 5: Quoting variables
if grep -qE '\"\$[a-zA-Z0-9_]+\"' "$SCRIPT"; then
  STATUS[5]="${color_green}${CHECK} best${color_reset}"
  MARKS[5]=":white_check_mark: best"
elif grep -qE '\$[a-zA-Z0-9_]+\b' "$SCRIPT"; then
  STATUS[5]="${color_yellow}${WARN} better${color_reset}"
  MARKS[5]=":large_orange_circle: better"
else
  STATUS[5]="${color_red}${CROSS} bad${color_reset}"
  MARKS[5]=":x: bad"
fi

# 4: ls/file loops (improved: avoid false positives in comments/help/strings/variable names)
if grep -E '^[^#"\047]*\bls\b[[:space:]]' "$SCRIPT" >/dev/null; then
  STATUS[4]="${color_red}${CROSS} bad${color_reset}"
  MARKS[4]=":x: bad"
elif grep -q 'find ' "$SCRIPT" || grep -qE '\*\.[a-zA-Z0-9]+' "$SCRIPT"; then
  STATUS[4]="${color_green}${CHECK} best${color_reset}"
  MARKS[4]=":white_check_mark: best"
else
  STATUS[4]="${color_yellow}${WARN} better${color_reset}"
  MARKS[4]=":large_orange_circle: better"
fi

# 3: set -euo pipefail
if grep -q 'set -euo pipefail' "$SCRIPT"; then
  STATUS[3]="${color_green}${CHECK} best${color_reset}"
  MARKS[3]=":white_check_mark: best"
elif grep -q 'set -e' "$SCRIPT"; then
  STATUS[3]="${color_yellow}${WARN} better${color_reset}"
  MARKS[3]=":large_orange_circle: better"
else
  STATUS[3]="${color_red}${CROSS} bad${color_reset}"
  MARKS[3]=":x: bad"
fi

# 2: Exit codes
if grep -q 'exit 1' "$SCRIPT"; then
  STATUS[2]="${color_green}${CHECK} best${color_reset}"
  MARKS[2]=":white_check_mark: best"
elif grep -q 'exit 0' "$SCRIPT"; then
  STATUS[2]="${color_yellow}${WARN} better${color_reset}"
  MARKS[2]=":large_orange_circle: better"
else
  STATUS[2]="${color_red}${CROSS} bad${color_reset}"
  MARKS[2]=":x: bad"
fi

# 1: awk vs sed/grep
if grep -q 'awk ' "$SCRIPT"; then
  STATUS[1]="${color_green}${CHECK} best${color_reset}"
  MARKS[1]=":white_check_mark: best"
elif grep -q 'sed ' "$SCRIPT"; then
  STATUS[1]="${color_yellow}${WARN} better${color_reset}"
  MARKS[1]=":large_orange_circle: better"
else
  STATUS[1]="${color_red}${CROSS} bad${color_reset}"
  MARKS[1]=":x: bad"
fi

# --- Output ---
if $MD_OUT; then
  MD_FILE="${SCRIPT%.*}_top10.md"
  {
    echo "# Top 10 Bash Best Practices Check: \`${SCRIPT}\`"
    echo
    echo "| # | Status | Rule |"
    echo "|---|--------|------|"
    for ((i = 10; i >= 1; i--)); do
      echo "| $i | ${MARKS[$i]} | ${RULES[$i]} |"
    done
    echo
    echo "_This report was auto-generated by \`top10_validator.sh\`._"
  } >"$MD_FILE"
  echo "Markdown written to $MD_FILE"
else
  echo -e "${color_bold}Top 10 Bash Best Practices Check: $SCRIPT${color_reset}"
  for ((i = 10; i >= 1; i--)); do
    printf "%2d %b %s\n" "$i" "${STATUS[$i]}" "${RULES[$i]}"
  done
  echo "----"
  echo -e "${color_bold}Summary:${color_reset} This is a heuristic scan. Review the output for improvement hints!"
fi
