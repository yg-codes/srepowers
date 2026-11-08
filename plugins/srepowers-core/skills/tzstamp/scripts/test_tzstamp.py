"""Tests for tzstamp.py — run: PYTHONDONTWRITEBYTECODE=1 python3 -B test_tzstamp.py"""

import io
import sys
import unittest
from contextlib import redirect_stdout
from pathlib import Path

sys.path.insert(0, str(Path(__file__).parent))
import tzstamp
from tzstamp import dual, main, parse_ts, timeline


class TestParsing(unittest.TestCase):
    def test_utc_suffix(self):
        self.assertEqual("2026-03-30 15:43 UTC = 2026-03-31 00:43 JST",
                         dual(*parse_ts("2026-03-30 15:43 UTC")))

    def test_iso_z_keeps_seconds(self):
        self.assertEqual("2026-03-30 15:43:21 UTC = 2026-03-31 00:43:21 JST",
                         dual(*parse_ts("2026-03-30T15:43:21Z")))

    def test_epoch_seconds(self):
        dt, had = parse_ts("1774885380")
        self.assertTrue(had)
        self.assertIn("UTC =", dual(dt, had))

    def test_bare_timestamp_refused(self):
        with self.assertRaises(ValueError):
            parse_ts("2026-03-30 15:43")

    def test_date_only_refused(self):
        with self.assertRaises(ValueError):
            parse_ts("2026-03-30 UTC")

    def test_assume_allows_bare(self):
        self.assertEqual("2026-03-30 15:43 UTC = 2026-03-31 00:43 JST",
                         dual(*parse_ts("2026-03-30 15:43", assume="utc")))


class TestZoneLabel(unittest.TestCase):
    """M5: the printed label must follow the configured zone, not a literal.

    Documentation told users to change the zone constant and promised the
    label would follow. It did not — Berlin times were emitted labeled JST,
    the exact mislabeled-timestamp class this tool exists to prevent.
    """

    def test_label_matches_configured_zone(self):
        self.assertIn(tzstamp.LOCAL_LABEL, dual(*parse_ts("2026-03-30 15:43 UTC")))

    def test_changing_zone_changes_label(self):
        orig_zone, orig_label = tzstamp.LOCAL, tzstamp.LOCAL_LABEL
        try:
            from zoneinfo import ZoneInfo
            tzstamp.LOCAL = ZoneInfo("Europe/Berlin")
            tzstamp.LOCAL_LABEL = "CET"
            out = dual(*parse_ts("2026-03-30 15:43 UTC"))
            self.assertIn("CET", out)
            self.assertNotIn("JST", out)
            self.assertIn("17:43", out)  # Berlin is UTC+2 on this date
        finally:
            tzstamp.LOCAL, tzstamp.LOCAL_LABEL = orig_zone, orig_label

    def test_table_header_follows_label(self):
        rows = [("2026-03-30T14:00:00Z", "alert")]
        self.assertIn(tzstamp.LOCAL_LABEL, timeline(rows))


class TestContradictoryInput(unittest.TestCase):
    """m4: an explicit zone suffix that disagrees with an offset is ambiguous."""

    def test_offset_plus_conflicting_suffix_refused(self):
        with self.assertRaises(ValueError):
            parse_ts("2026-03-30T15:43:00+09:00 UTC")

    def test_offset_with_agreeing_suffix_ok(self):
        # +00:00 and UTC agree — no ambiguity to refuse
        dt, _ = parse_ts("2026-03-30T15:43:00+00:00 UTC")
        self.assertEqual(15, dt.astimezone(tzstamp.UTC).hour)

    def test_plain_offset_still_works(self):
        dt, _ = parse_ts("2026-03-30T15:43:00+09:00")
        self.assertEqual(6, dt.astimezone(tzstamp.UTC).hour)


class TestDSTAwareness(unittest.TestCase):
    """The agreement check must use the offset at the PARSED instant.

    Comparing against `datetime.now(zone)` refuses every valid winter stamp
    while the machine is in summer (and vice versa) for any DST zone — a gate
    that cannot pass for half the year. The shipped Tokyo config has no DST and
    never trips it, but the documented reconfiguration path uses Berlin.
    """

    def setUp(self):
        from zoneinfo import ZoneInfo
        self._saved = (tzstamp.LOCAL, tzstamp.LOCAL_LABEL)
        tzstamp.LOCAL = ZoneInfo("Europe/Berlin")
        tzstamp.LOCAL_LABEL = "CET"

    def tearDown(self):
        tzstamp.LOCAL, tzstamp.LOCAL_LABEL = self._saved

    def test_winter_stamp_accepted(self):
        # Berlin is +01:00 in January regardless of when this test runs
        dt, _ = parse_ts("2026-01-15T15:43:00+01:00 CET")
        self.assertEqual(14, dt.astimezone(tzstamp.UTC).hour)

    def test_summer_stamp_accepted(self):
        # Berlin is +02:00 in July
        dt, _ = parse_ts("2026-07-15T15:43:00+02:00 CET")
        self.assertEqual(13, dt.astimezone(tzstamp.UTC).hour)

    def test_genuine_mismatch_still_refused(self):
        # +09:00 is not Berlin at any time of year — this must still error
        with self.assertRaises(ValueError):
            parse_ts("2026-01-15T15:43:00+09:00 CET")

    def test_winter_offset_on_a_summer_date_refused(self):
        # +01:00 is Berlin's winter offset; in July the zone is +02:00
        with self.assertRaises(ValueError):
            parse_ts("2026-07-15T15:43:00+01:00 CET")


class TestTableEdgeCases(unittest.TestCase):
    """m4: an empty table must not render as a valid, complete result."""

    def test_empty_rows_is_not_a_table(self):
        out = timeline([])
        self.assertNotIn("|--", out)
        self.assertIn("no rows", out.lower())


class TestCLI(unittest.TestCase):
    def test_bare_input_exits_2(self):
        self.assertEqual(2, main(["2026-03-30 15:43"]))

    def test_valid_input_exits_0(self):
        buf = io.StringIO()
        with redirect_stdout(buf):
            rc = main(["2026-03-30 15:43 UTC"])
        self.assertEqual(0, rc)
        self.assertIn("UTC =", buf.getvalue())


if __name__ == "__main__":
    unittest.main()
