# tzstamp

Emit the canonical auditable dual stamp —
`2026-03-30 15:43 UTC = 2026-03-31 00:43 JST` — from any common timestamp
input (zone-suffixed, ISO 8601, epoch), instead of doing timezone arithmetic
in your head. Zone-less input is refused by design. Ships as
`srepowers-core:tzstamp`. (`SKILL.md` is the agent-facing trigger doc; this
file is for humans.)

## Use cases

- Dual-stamp a UTC event time (CloudTrail, journald, any cloud API) against the local-time business artifact it maps to — the two halves often fall on different calendar days
- Build a chronologically sorted incident-timeline table to paste into a post-mortem
- Stamp alert silences and maintenance-window expiries so operators in either zone read the same deadline
- Replace "what time was that in UTC?" mental conversion wherever a wall-clock time outlives the session

## How-to

Ask — "what time was that in UTC", "dual-stamp this", "build an incident
timeline" — or invoke `srepowers-core:tzstamp`. Directly from the shell:

```bash
python3 plugins/srepowers-core/skills/tzstamp/scripts/tzstamp.py "2026-03-30 15:43 UTC"
# → 2026-03-30 15:43 UTC = 2026-03-31 00:43 JST
# bare input exits 2 — add the zone or pass --assume utc|jst
```

Pipe `timestamp | label` lines in with `--table` for an aligned
`| UTC | JST | Event |` table.

### Verify

Fixture: `evals/fixtures/tzstamp/` — run it via the
`srepowers-core:skill-test-runner` skill. The script also carries its own
suite: `python3 -B plugins/srepowers-core/skills/tzstamp/scripts/test_tzstamp.py`.

## Reference

| File | Purpose |
|------|---------|
| `scripts/tzstamp.py` | Dual-stamp + `--table` tool; `--assume utc\|jst` for zone-less input; pairs UTC with `Asia/Tokyo` (change both `LOCAL`/`LOCAL_LABEL` constants to re-zone) |
| `scripts/test_tzstamp.py` | Test suite, incl. the `TestZoneLabel` regression for the mislabeled-stamp bug |

---
Last Updated: 2026-09-14
