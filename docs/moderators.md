# Moderators

Moderators review what users contribute (new songs, corrections, recordings and
timings) before anyone else can see it. Until the admin website (intent 008) exists,
they review in the app, from Profile or the Contribute tab.

## Granting and removing the role

The role is changed only on the server. Nothing in the app can grant it. The person
must have signed in to Zema at least once, so their account exists.

```sh
backend/scripts/moderator.sh grant  someone@example.com
backend/scripts/moderator.sh revoke someone@example.com
```

- **Local backend**: run the script as shown. It uses the local Supabase database in
  Docker (`supabase_db_zema`).
- **Another database** (for example a hosted project later):
  - Export its connection string first: `export DATABASE_URL=...`. Then run the
    script. It needs `psql` installed.
  - The connection string contains the database password. Keep it in your shell or a
    password manager, never in a file in the repo.

The script prints whether the role was granted, revoked or already set. It reports
`unknown_email` when no account has that email. Emails are matched without regard to
case.

## What a moderator can do

- See the review queue: pending contributions from other users, oldest first. A
  moderator never sees their own contributions there and can't review them.
- **Approve**: the contribution is published in the catalog at once, and phones pick it
  up on their next catalog refresh.
- **Request changes** (a comment is required): the contributor can edit it and send it
  again.
- **Reject** (a reason is required).

If two moderators open the same contribution, only the first decision counts. The
second is told it was already reviewed.

The `admin` role (for the owner) can do everything a moderator can.
