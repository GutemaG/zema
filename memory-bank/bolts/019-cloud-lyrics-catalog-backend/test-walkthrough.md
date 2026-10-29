---
stage: test
bolt: 019-cloud-lyrics-catalog-backend
created: 2026-10-29T06:23:13Z
---

## Test Report: cloud-lyrics-catalog-backend (bolt 2 of 4)

### Summary

- **Tests**: 76/76 pgTAP checks pass (28 schema, 31 read rules, 17 reports) after a fresh `db reset`.
- **Planted bugs**: 8 of 9 caught.
  - **Read rules**:
    - drafts made readable (4 checks failed)
    - write grants left in place (7 failed)
  - **Reports**:
    - the limit raised to 6
    - the raw install ID stored
    - draft songs made reportable
    - any recording accepted
    - PUBLIC allowed to execute
    - the 24-hour window removed
- **Survivor, which turned out to be an equivalent change**:
  - **What was removed**: the "song is approved" check in the `sync_timings` policy.
  - **Why it changes nothing**: the policy finds the timing's recording through `recordings`, which has RLS of its own and already hides recordings of unapproved songs.
  - **Decision**: the explicit check stays as a second safeguard; no test can tell the two apart.
- **API**: checked in the implement stage. Reads return only approved songs; reports 1–5 return 200 and the 6th returns 429; a draft song returns 400; reports aren't readable.

### Test Files

- [x] `001_catalog_schema.test.sql`: now checks that every policy is read-only.
- [x] `002_read_policies.test.sql` (31):
  - each table as `anon` and `authenticated`
  - 11 writes refused
  - status changes taking effect at once
  - policy counts
- [x] `003_submit_report.test.sql` (17):
  - stored, trimmed, hashed (never raw), blank note stored as null
  - 5 kinds of bad input refused
  - the 6th report refused with `PT429`; another install unaffected; old reports expire
  - only `anon` and `authenticated` may execute it

### Acceptance Criteria

**Story 002: Row Level Security**
- ✅ `anon` reads only approved songs and their parts
- ✅ `anon` reads no reports, contributions or roles
- ✅ `anon` writes nothing on any table
- ✅ Each rule has a pgTAP test that runs as `anon`

**Story 003: report function**
- ✅ An anonymous report is stored through `submit_report`
- ✅ The 6th report in 24 hours is refused with a recognisable code (`PT429`, HTTP 429)
- ✅ A bad reason (enum), a long note, or an unknown or unapproved song is refused
- ✅ The rate limit and validation are tested
