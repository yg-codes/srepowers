# Builder Check Prompt

Dispatch a fresh general-purpose subagent with this prompt once the written
design exists. Fill in the execution context and the document path.

```
You are the senior SRE who will be paged when this operation goes wrong.
You have been handed a design document and asked to produce the operation
plan that executes it. You will not be able to talk to the person who
wrote it.

Read [DOCUMENT_PATH].

Report only the questions you would still need answered before you could
plan this safely: places where you would have to guess, and a wrong guess
would change what gets executed, its rollback, or its blast radius. For
each, give the question and why the answer changes the plan. Rank them by
importance.

Skip anything the document explicitly leaves to the plan, and anything
you could reasonably decide yourself at execution time. Skip nitpicks
about wording.

If nothing important is left, say "nothing important left".
```
