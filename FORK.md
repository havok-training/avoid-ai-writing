# About this fork

This is a fork of [conorbronsdon/avoid-ai-writing](https://github.com/conorbronsdon/avoid-ai-writing), not an independent project.

## Why this fork exists

Upstream's Claude Code plugin (`plugins/avoid-ai-writing`) ships only the canonical `avoid-ai-writing` Skill. The six companion Skills — `avoid-ai-writing-router`, `ai-writing-detector`, `false-positive-reviewer`, `file-edit-in-place`, `preservation-verifier`, and `voice-preserving-rewriter` — live in root `skills/` and only reach the ChatGPT/Codex package (`.codex-plugin/`).

I wanted the full set available in Claude Code, so this fork extends `scripts/sync-plugin-skill.sh` to mirror those six Skills into the plugin's `skills/` directory alongside the canonical one. Root `skills/` stays the source of truth; nothing in the plugin tree is hand-edited, and the existing CI drift check (`.github/workflows/plugin-skill-sync.yml`) still fails if a generated copy falls out of sync.

## German adaptation

The plugin also bundles `avoid-ai-writing-de`, a German-language adaptation by [Jürgen Kraus](https://github.com/jurigis) ([avoid-ai-writing-multilingual](https://github.com/jurigis/avoid-ai-writing-multilingual), MIT). It is grounded in German-language research, not translated from English, and is prompt-only: the bundled detector is English-calibrated, so German text gets no numeric score. Invoke it as `/avoid-ai-writing:avoid-ai-writing-de`.

- The source is vendored byte-identical in `vendor/avoid-ai-writing-de/` (with its licence and a `SOURCE` file pinning the commit). `scripts/sync-plugin-skill.sh` copies it into the plugin.
- The router's connection validator rejects skills that are not in its graph, so `validate_connections.py` carries a one-line `STANDALONE_SKILLS` set. Upstream syncs can conflict there. Keep that line when resolving.
- To refresh, copy the new `SKILL-DE.md` over `vendor/avoid-ai-writing-de/SKILL.md`, update the commit in `SOURCE`, and run the sync script.

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
