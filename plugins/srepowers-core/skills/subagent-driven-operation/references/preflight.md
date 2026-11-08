# The Pre-flight Scan

Part of `srepowers-core:subagent-driven-operation`. Run it once, before
dispatching Task 1.

Scan the plan once for conflicts, writing down what you checked as you
check it:

- tasks that contradict each other or the plan's Global Constraints
- anything the plan explicitly mandates that the review rubric would treat
  as a defect (a verification that checks nothing, a task with no rollback)

The scan's output is a table, not a verdict. One row for every pair of
tasks that share a host, a resource, a repo path, or an interface: the two
tasks, what one produces against what the other consumes, and what you
found. One row for every task: whether its own text agrees with itself —
the verification it specifies against the change it specifies, the
resources it creates against the resources it later touches, the rollback
it declares against the change it makes. "The scan is clean" without those
rows is not a scan you ran.

Write the table to the ledger. Rule on everything you find before execution
begins — each finding against the plan text that mandates it — and record
each ruling beside its row. The spec is the binding authority, the plan is
its argument. A finding that trips a stop class (a missing rollback, an
undeclared blast radius, an unapproved mutating step) is not yours to rule
on: batch those and present them to the operator before Task 1. If the
scan is clean, proceed without comment. The task review loop remains the
net for conflicts that only emerge during execution.
