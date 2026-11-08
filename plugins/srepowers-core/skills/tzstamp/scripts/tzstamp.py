#!/usr/bin/env python3
"""tzstamp — dual UTC/local timestamp helper.

House rule: never write a bare timestamp. This tool emits the canonical
auditable form `2026-03-30 15:43 UTC = 2026-03-31 00:43 JST` from any
common input (zone-suffixed, ISO 8601 with Z/offset, epoch s/ms), and
refuses bare timestamps unless told what to assume.

To pair UTC with a different zone, change BOTH constants below together —
LOCAL selects the arithmetic, LOCAL_LABEL is what gets printed. They are
separate because a label is a house convention ("JST"), not derivable from
an IANA key ("Asia/Tokyo"); keeping them apart is what lets the printed
label stay honest. Changing only one produces correctly-converted times
under the wrong name, which is the exact failure this tool exists to
prevent.
"""

import argparse
import re
import sys
from datetime import datetime, timezone
from zoneinfo import ZoneInfo

UTC = timezone.utc
LOCAL = ZoneInfo("Asia/Tokyo")
LOCAL_LABEL = "JST"


def _zones():
    """Zone lookup, read at call time so the configured zone stays overridable."""
    return {"UTC": UTC, LOCAL_LABEL.upper(): LOCAL}


def parse_ts(s, assume=None):
    """Parse one timestamp string.

    Returns (aware datetime, had_seconds). Raises ValueError on bare
    (zone-less) or date-only input — writing those is the exact mistake
    this tool exists to prevent.
    """
    s = s.strip()
    if re.fullmatch(r"\d{13}", s):
        return datetime.fromtimestamp(int(s) / 1000, tz=UTC), True
    if re.fullmatch(r"\d{10}", s):
        return datetime.fromtimestamp(int(s), tz=UTC), True

    zone = None
    m = re.fullmatch(rf"(.+?)\s*(UTC|{re.escape(LOCAL_LABEL)})", s, re.IGNORECASE)
    if m:
        s, zone = m.group(1), _zones()[m.group(2).upper()]
    if s.endswith("z"):  # fromisoformat accepts only uppercase Z
        s = s[:-1] + "Z"

    try:
        dt = datetime.fromisoformat(s)
    except ValueError:
        raise ValueError(f"unrecognized timestamp {s!r}") from None

    if not re.search(r"\d{1,2}:\d{2}", s):
        raise ValueError(f"date-only value {s!r} — a time of day is required")

    had_seconds = bool(re.search(r"\d{1,2}:\d{2}:\d{2}", s))
    if dt.tzinfo is None:
        zone = zone or (_zones()[assume.upper()] if assume else None)
        if zone is None:
            raise ValueError(
                f"bare timestamp {s!r} — append UTC/{LOCAL_LABEL}/Z/offset to the "
                f"value, or pass --assume utc|{LOCAL_LABEL.lower()}"
            )
        dt = dt.replace(tzinfo=zone)
    elif zone is not None and m is not None and (
            dt.utcoffset() != dt.replace(tzinfo=zone).utcoffset()):
        # e.g. "…+09:00 UTC": the offset and the suffix disagree. Silently
        # preferring one is how a stamp ends up labeled with a zone it is not in.
        #
        # Resolve the zone's offset AT THE PARSED INSTANT, never at runtime.
        # `datetime.now(zone)` would compare a January stamp against September's
        # offset, refusing every valid winter stamp for a DST zone half the year
        # — a gate that cannot pass, which is the failure mode this whole tool
        # is built around.
        raise ValueError(
            f"contradictory zone in {s!r}: the value carries an explicit offset "
            f"that disagrees with its {m.group(2).upper()} suffix — drop one"
        )
    return dt, had_seconds


def dual(dt, with_seconds=False):
    """Format an aware datetime as 'YYYY-MM-DD HH:MM[:SS] UTC = ... <LOCAL_LABEL>'."""
    fmt = "%Y-%m-%d %H:%M:%S" if with_seconds else "%Y-%m-%d %H:%M"
    return (f"{dt.astimezone(UTC).strftime(fmt)} UTC = "
            f"{dt.astimezone(LOCAL).strftime(fmt)} {LOCAL_LABEL}")


def timeline(rows, assume=None):
    """rows: [(timestamp_str, label)] → chronologically sorted, aligned markdown table."""
    if not rows:
        # A header-only table reads as a complete, valid result. Say there were
        # no rows instead — an empty timeline is an input problem, not a timeline.
        return "(no rows — nothing to tabulate)"
    parsed = [(parse_ts(ts, assume), label) for ts, label in rows]
    with_seconds = any(secs for (_, secs), _ in parsed)
    fmt = "%Y-%m-%d %H:%M:%S" if with_seconds else "%Y-%m-%d %H:%M"
    body = [
        (dt.astimezone(UTC).strftime(fmt), dt.astimezone(LOCAL).strftime(fmt), label)
        for (dt, _), label in sorted(parsed, key=lambda p: p[0][0])
    ]
    cells = [("UTC", LOCAL_LABEL, "Event"), *body]
    widths = [max(len(row[i]) for row in cells) for i in range(3)]
    lines = ["| " + " | ".join(c.ljust(w) for c, w in zip(row, widths)) + " |" for row in cells]
    lines.insert(1, "|" + "|".join("-" * (w + 2) for w in widths) + "|")
    return "\n".join(lines)


def main(argv=None):
    p = argparse.ArgumentParser(
        description=f"Emit dual UTC/{LOCAL_LABEL} stamps. "
                    "Args: timestamps, 'now', or none (= now)."
    )
    p.add_argument("timestamps", nargs="*", help="e.g. '2026-03-30 15:43 UTC', '2026-03-30T15:43:21Z', epoch s/ms")
    p.add_argument("--assume", choices=["utc", LOCAL_LABEL.lower()],
                   help="zone to assume for bare timestamps")
    p.add_argument("--table", action="store_true",
                   help="read 'timestamp | label' lines from stdin, emit a markdown timeline table")
    args = p.parse_args(argv)

    try:
        if args.table:
            rows = []
            for line in sys.stdin:
                line = line.strip()
                if not line:
                    continue
                ts, _, label = line.partition("\t" if "\t" in line else "|")
                rows.append((ts.strip(), label.strip()))
            print(timeline(rows, args.assume))
        else:
            for ts in args.timestamps or ["now"]:
                if ts == "now":
                    print(dual(datetime.now(UTC), with_seconds=True))
                else:
                    print(dual(*parse_ts(ts, args.assume)))
    except ValueError as e:
        print(f"error: {e}", file=sys.stderr)
        return 2
    return 0


if __name__ == "__main__":
    sys.exit(main())
