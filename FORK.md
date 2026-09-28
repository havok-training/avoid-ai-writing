# About this fork

This is a fork of [conorbronsdon/avoid-ai-writing](https://github.com/conorbronsdon/avoid-ai-writing), not an independent project.

## Why this fork exists

Upstream's Claude Code plugin (`plugins/avoid-ai-writing`) ships only the canonical `avoid-ai-writing` Skill. The six companion Skills — `avoid-ai-writing-router`, `ai-writing-detector`, `false-positive-reviewer`, `file-edit-in-place`, `preservation-verifier`, and `voice-preserving-rewriter` — live in root `skills/` and only reach the ChatGPT/Codex package (`.codex-plugin/`).

I wanted the full set available in Claude Code, so this fork extends `scripts/sync-plugin-skill.sh` to mirror those six Skills into the plugin's `skills/` directory alongside the canonical one. Root `skills/` stays the source of truth; nothing in the plugin tree is hand-edited, and the existing CI drift check (`.github/workflows/plugin-skill-sync.yml`) still fails if a generated copy falls out of sync.

## Install

```
claude plugin marketplace add havok-training/avoid-ai-writing
claude plugin install avoid-ai-writing@conorbronsdon-skills
```

## Staying current with upstream

```
gh repo sync havok-training/avoid-ai-writing
bash scripts/sync-plugin-skill.sh && bash scripts/sync-cursor-rules.sh
git add -A && git commit
```

## Status

Not affiliated with or endorsed by the upstream author. No pull request is open against upstream for this change. MIT licensed — see `LICENSE`.
