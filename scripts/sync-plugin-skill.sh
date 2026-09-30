#!/usr/bin/env bash
# Regenerate plugin copies from canonical repository sources.
# Root SKILL.md, references/patterns.md, detector resources, scripts/, and examples/ are
# sources of truth.
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
src="$repo_root/SKILL.md"
node "$repo_root/scripts/flatten-skill.js"
claude_dest="$repo_root/plugins/avoid-ai-writing/skills/avoid-ai-writing/SKILL.md"
openai_dest="$repo_root/skills/avoid-ai-writing/SKILL.md"
patterns_src="$repo_root/detector/patterns.js"
validate_src="$repo_root/detector/validate.js"
categories_src="$repo_root/detector/CATEGORIES.md"
check_style_src="$repo_root/scripts/check-style.js"
markdown_prose_src="$repo_root/scripts/markdown-prose.js"
normalize_quotes_src="$repo_root/scripts/normalize-quotes.js"
examples_src="$repo_root/examples"
canonical_skill_root="$repo_root/skills/avoid-ai-writing"
canonical_detector_dest="$canonical_skill_root/detector"
canonical_scripts_dest="$canonical_skill_root/scripts"
canonical_examples_dest="$canonical_skill_root/examples"
detector_patterns_dest="$repo_root/skills/ai-writing-detector/scripts/patterns.js"
verifier_patterns_dest="$repo_root/skills/preservation-verifier/scripts/patterns.js"
verifier_validate_dest="$repo_root/skills/preservation-verifier/scripts/validate.js"

for required in "$src" "$patterns_src" "$validate_src" "$categories_src" "$check_style_src" "$markdown_prose_src" "$normalize_quotes_src"; do
  if [ ! -f "$required" ]; then
    echo "missing canonical source: $required" >&2
    exit 1
  fi
done
if [ ! -d "$examples_src" ]; then
  echo "missing canonical source directory: $examples_src" >&2
  exit 1
fi

mkdir -p \
  "$(dirname "$claude_dest")" \
  "$(dirname "$openai_dest")" \
  "$canonical_detector_dest" \
  "$canonical_scripts_dest" \
  "$(dirname "$detector_patterns_dest")" \
  "$(dirname "$verifier_patterns_dest")" \
  "$(dirname "$verifier_validate_dest")"

cp "$src" "$claude_dest"
for skill_root in "$(dirname "$claude_dest")" "$canonical_skill_root"; do
  mkdir -p "$skill_root/references" "$skill_root/detector" "$skill_root/scripts"
  cp "$repo_root/references/patterns.md" "$skill_root/references/patterns.md"
  cp "$patterns_src" "$validate_src" "$categories_src" "$skill_root/detector/"
  cp "$check_style_src" "$markdown_prose_src" "$normalize_quotes_src" "$skill_root/scripts/"
  # Fixed destination is inside the selected bundled skill directory.
  rm -rf "$skill_root/examples"
  cp -R "$examples_src" "$skill_root/examples"
done
# The OpenAI plugin portal rejects a `metadata` key in SKILL.md frontmatter
# ("Skill interface settings must use agents/openai.yaml"); that block carries
# agentskills.io/OpenClaw fields, so the OpenAI copy omits it and every other
# byte stays identical. The transform lives in validate-openai-plugin.py so the
# sync and the drift check cannot diverge.
python_bin="$(command -v python3 || command -v python)"
"$python_bin" "$repo_root/scripts/validate-openai-plugin.py" --strip-frontmatter-metadata "$src" > "$openai_dest"
cp "$patterns_src" "$detector_patterns_dest"
cp "$patterns_src" "$verifier_patterns_dest"
cp "$validate_src" "$verifier_validate_dest"

# Mirror the remaining public Skills into the Claude plugin so Claude Code
# installs get the full set, not just the canonical avoid-ai-writing Skill.
# Root skills/<name>/ stays the source of truth; agents/openai.yaml is
# ChatGPT/Codex-only interface metadata and is dropped from the plugin copy.
claude_skills_root="$repo_root/plugins/avoid-ai-writing/skills"
for sub in avoid-ai-writing-router ai-writing-detector false-positive-reviewer \
           file-edit-in-place preservation-verifier voice-preserving-rewriter; do
  rm -rf "$claude_skills_root/$sub"
  cp -R "$repo_root/skills/$sub" "$claude_skills_root/$sub"
  rm -rf "$claude_skills_root/$sub/agents"
done

# Fork-only: vendored third-party German adaptation (see vendor/avoid-ai-writing-de/SOURCE).
de_src="$repo_root/vendor/avoid-ai-writing-de"
if [ ! -f "$de_src/SKILL.md" ] || [ ! -f "$de_src/LICENSE" ]; then
  echo "missing vendored source: $de_src" >&2
  exit 1
fi
rm -rf "$claude_skills_root/avoid-ai-writing-de"
mkdir -p "$claude_skills_root/avoid-ai-writing-de"
cp "$de_src/SKILL.md" "$de_src/LICENSE" "$claude_skills_root/avoid-ai-writing-de/"

skill_version="$(sed -n '/^---[[:space:]]*$/,/^---[[:space:]]*$/ s/^version:[[:space:]]*//p' "$src" | head -n1 | tr -d '\r')"
if [ -z "$skill_version" ]; then
  echo "could not parse 'version:' from SKILL.md frontmatter" >&2
  exit 1
fi

read_manifest_version() {
  "$python_bin" - "$1" <<'PY'
import json
import sys

path = sys.argv[1]
try:
    with open(path, encoding="utf-8") as f:
        data = json.load(f)
except FileNotFoundError:
    print(f"Missing plugin manifest: {path}", file=sys.stderr)
    sys.exit(1)
except json.JSONDecodeError as e:
    print(f"Invalid JSON in plugin manifest: {path}: {e}", file=sys.stderr)
    sys.exit(1)

version = data.get("version")
if not isinstance(version, str) or not version:
    print(f'Invalid or missing "version" in plugin manifest: {path}', file=sys.stderr)
    sys.exit(1)
print(version)
PY
}

claude_version="$(read_manifest_version "$repo_root/plugins/avoid-ai-writing/.claude-plugin/plugin.json")"
openai_version="$(read_manifest_version "$repo_root/.codex-plugin/plugin.json")"

if [ "$skill_version" != "$claude_version" ]; then
  echo "version mismatch: SKILL.md=$skill_version Claude plugin=$claude_version" >&2
  exit 1
fi
if [ "$skill_version" != "$openai_version" ]; then
  echo "version mismatch: SKILL.md=$skill_version OpenAI plugin=$openai_version" >&2
  exit 1
fi

echo "synced: canonical Skill + bundled commands/examples + detector + preservation resources + 6 mirrored sub-Skills + vendored German Skill + plugin versions ($skill_version)"
