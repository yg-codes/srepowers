# Batching Small Same-Shape Work

Part of `srepowers-core:subagent-driven-operation`.

**Batch small same-shape work.** When the plan lists several tasks that are
each a small, independent change of the same kind — the same one-line edit,
the same annotation added across manifests, the same read-only probe
repeated per host — do not dispatch one subagent per task. Compose ONE
dispatch brief listing every target and its change, send the whole batch to
a single subagent, and review its diff as one unit. Reserve
one-dispatch-per-task for work that needs its own judgment, its own
verification, or its own review surface.

Two limits specific to infrastructure. A batch is delegable only when its
members are genuinely independent: hosts sharing a quorum, a VIP, or a
service pairing are sequential in your own thread, never batched to one
subagent (nor split across parallel ones). And the same command across N
hosts with no per-host judgment is not subagent work at all — that is
`parallel-ssh`, which costs no context.
