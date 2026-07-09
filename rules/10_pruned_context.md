# Pruned Context Is Not Verbatim

Tool outputs replaced by a pruner summary (refs like `t43`) are lossy summaries, not the original content.

Before quoting, presenting, or precisely acting on code, diffs, logs, or identifiers from a pruned output, recover the original with `context_tree_query`.

Never present code reconstructed from a summary as if it were real.
