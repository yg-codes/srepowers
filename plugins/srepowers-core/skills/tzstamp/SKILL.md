---
name: tzstamp
description: Use when writing any timestamp into an incident timeline, post-mortem, runbook, report, ticket, or status update — converting between UTC and a local zone, dual-stamping a UTC event time (CloudTrail, GuardDuty, S3, journald, most cloud APIs) against local-time business artifacts, or whenever tempted to write a bare timestamp or convert zones mentally. Also use for "what time was that in UTC", "build an incident timeline", "dual-stamp this".
---

# tzstamp

Emits the canonical auditable dual stamp — `2026-03-30 15:43 UTC = 2026-03-31 00:43 JST` —
from any common timestamp input. Replaces mental timezone arithmetic and
throwaway `python -c` one-liners, which are the error class the "never write a
bare timestamp" rule exists to prevent.

**Announce at start:** "I'm using the tzstamp skill to dual-stamp these times."

## Why this is a gate, not a convenience

An incident timeline is read later, by someone reconstructing what happened.
A bare `15:43` is unresolvable: the reader cannot tell whether the logging
system, the ticket, or the operator's shell produced it. Worse, a UTC event and
a local-time business artifact routinely fall on **different calendar days** —
so an off-by-one-day error survives review because both halves look plausible
in isolation.

The rule this skill enforces: **every timestamp in a durable artifact carries
both zones, or it is not a timestamp.**

## Usage

```bash
python3 scripts/tzstamp.py "2026-03-30 15:43 UTC"       # → dual stamp
python3 scripts/tzstamp.py "2026-03-30T15:43:21Z"       # ISO, keeps seconds
python3 scripts/tzstamp.py 1774885380                   # epoch s (or ms) — same instant
python3 scripts/tzstamp.py now                          # current time (also: no args)
python3 scripts/tzstamp.py --assume utc "2026-03-30 15:43"   # bare input needs --assume
```

Run its tests with `python3 -B scripts/test_tzstamp.py`.

Timeline table — chronologically sorted, columns aligned. Feed
`timestamp | label` lines on stdin:

```bash
printf '%s\n' '2026-03-30T14:00:00Z | alert fired' '2026-03-31 09:10 JST | operator ack' \
  | python3 scripts/tzstamp.py --table
```

Produces:

```text
| UTC                 | JST                 | Event         |
|---------------------|---------------------|---------------|
| 2026-03-30 14:00:00 | 2026-03-30 23:00:00 | alert fired   |
| 2026-03-31 00:10:00 | 2026-03-31 09:10:00 | operator ack  |
```

Paste that straight into a post-mortem or incident record.

## Behavior notes

- **Bare (zone-less) or date-only input exits 2 with an error, by design.** Add
  UTC/JST/Z/offset to the value, or pass `--assume utc|jst`. Guessing a zone is
  the bug; refusing is the feature.
- Seconds appear in the output only if the input had them (epoch and `now`
  always do).
- Zones are explicit via `zoneinfo`, never the host's local timezone — so the
  output does not change based on where the command ran. This matters on a
  fleet: the same script on a UTC server and a JST workstation must agree.

## Configuring the local zone

The script pairs UTC with `Asia/Tokyo`, labeled `JST`. To pair with a different
zone, change **both** constants at the top of `scripts/tzstamp.py` together:

```python
LOCAL       = ZoneInfo("Asia/Tokyo")   # → ZoneInfo("Europe/Berlin")
LOCAL_LABEL = "JST"                    # → "CET"
```

They are deliberately separate: a label is a house convention, not something
derivable from an IANA key (`Asia/Tokyo` does not spell "JST"). Everything
downstream — the dual stamp, the `--table` header, the accepted input suffix,
`--assume`, and the error messages — reads `LOCAL_LABEL`, so both halves stay
consistent once you change them.

**Change only one and you get correctly-converted times under the wrong name**
— Berlin time printed as `JST`. That is the mislabeled-stamp bug this skill
exists to prevent, so it is covered by a regression test
(`scripts/test_tzstamp.py::TestZoneLabel`).

## Common mistakes

- **Converting in your head "just this once."** Run the tool. The off-by-one-day
  bugs all came from "just this once."
- **Pasting only one half of the output** into a local-audience document — keep
  both halves so the conversion stays auditable.
- **Letting a date rollover pass silently.** When the two halves of a stamp fall
  on different calendar days, say so explicitly next to the stamp (e.g. "note:
  March 31 in JST"). A local-time reader will otherwise file the event under the
  wrong day.
- **Stamping only the incident, not the evidence.** A log excerpt quoted in a
  report carries its own timestamp; dual-stamp that too, or the reader cannot
  align it with the timeline.

## Where this helps

Useful wherever a wall-clock time outlives the session that wrote it:
`srepowers-core:post-mortem-writer` timelines,
`srepowers-core:incident-commander` status updates,
`srepowers-core:evidence-first-reporting` observations, and
`srepowers-core:sre-runbook` steps.

**This skill does not override those skills' own formats.** `post-mortem-writer`
specifies a single-zone `## Timeline (All Times UTC)` table, and that heading is
its convention to set — a UTC-only timeline whose header says so is unambiguous
and satisfies the rule this skill actually enforces (no *unlabeled* timestamp).
Reach for `tzstamp` there when the incident spans a local-time business artifact
and readers need both zones; its `--table` output is `| UTC | JST | Event |`, so
adapt the columns rather than dropping the consuming skill's own (e.g. `Source`).

Alert silences and maintenance windows carry a wall-clock expiry — dual-stamp
those too, so an operator in either zone reads the same deadline.
