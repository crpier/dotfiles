---
name: reviewable-work
description: Organize implementation into small human-reviewable parts. Use when planning multi-part changes, iterating on uncommitted work for human review, or addressing exported ChangeReview comments. Proactively suggest review boundaries and keep revision requests separate from approval.
---

# Reviewable work

A work part is a coherent change the user can meaningfully review on its own, including the tests needed to check it. It may span several agent turns and manual edits. A new prompt is not acceptance of the previous changes.

## Choose the part

Before substantial implementation:

1. Inspect the working tree and the request. Account for existing edits without assuming the agent authored them. Preserve the user's staging choices.
2. Identify the current part from the conversation. If none exists, propose a short scope and a checkable completion condition.
3. Keep necessary dependencies together. Service logic and a required schema change may belong together; unrelated logging cleanup usually does not.

When the request already defines a sensible part, state it briefly and proceed. Ask only when choosing the scope would materially change the work. Small fixes do not need a planning ceremony.

The usual review baseline is `HEAD`, with the part's changes left in the working tree. A dirty tree is normal. Do not require a clean tree, manufacture a checkpoint commit, or reset existing edits to begin.

## Implement and suggest review

Work within the agreed part, including its tests. Suggest a split if unrelated concerns emerge or the change becomes difficult to review as one piece. Propose boundaries based on behavior, not fixed file counts, line counts, or agent turns.

At a natural review boundary:

- Summarize the behavior changed and where to start reading.
- Report checks actually run, failures, and checks not run.
- Identify remaining work and suggest reviewing this part before expanding scope.

Keep this handoff short. Suggest a review when the part is coherent, or earlier when a consequential design decision needs the user's input. Do not ask for approval after every edit.

## Handle revisions

The user may fix code directly, comment on one hunk, or collect feedback across several files. Support all three without requiring a complete review first.

When receiving exported comments:

1. Read the current source before editing. Line numbers and quoted excerpts may describe an older version, especially when the export flags the location for checking.
2. Address each supplied concern within the current part. Preserve manual adjustments unless changing them is required by the feedback; explain any such conflict.
3. Run relevant checks. Report which concerns were addressed, which remain, and anything needing clarification.

A request for revisions continues the same part. Unmentioned code is not implicitly approved. If feedback requires broader work, explain why and propose the scope change rather than silently including it.

## Acceptance and commits

Leave changes uncommitted and preserve the staging arrangement unless the user explicitly requests a Git operation. Never infer permission to commit, stage everything, squash, or push from another turn, passing tests, or a completed feedback list.

The user owns file approval and comment resolution. Do not edit the review tool's stored comments or checkmarks to declare work accepted. Describe completed fixes and let the user verify them.

When explicitly asked to commit, inspect the current diff and confirm what belongs to that commit. Ask about ambiguous unrelated edits instead of sweeping them in. After acceptance, propose the next reviewable part if work remains.

## Editor independence

This agreement needs no editor connection. Receive feedback through the user's pasted export; do not assume access to their live Neovim state. The editor handles diff viewing, persistent comments, and review progress independently.

When asked how to operate the local review tool, consult `~/.config/nvim/docs/change-review.md` if available. Keep keymaps and storage details in that document rather than duplicating them here.
