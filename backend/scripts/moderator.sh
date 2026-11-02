#!/usr/bin/env bash
# Grants or removes the moderator role (intent 006, bolt 040).
#
#   backend/scripts/moderator.sh grant  someone@example.com
#   backend/scripts/moderator.sh revoke someone@example.com
#
# With no DATABASE_URL it uses the local Supabase database (Docker container
# supabase_db_zema). For another database, export DATABASE_URL first; it needs
# psql installed. Never write that URL into a file in the repo.
set -euo pipefail

usage() {
  echo "usage: $0 grant|revoke <email>" >&2
  exit 2
}

[[ $# -eq 2 ]] || usage
case "$1" in
  grant) enabled=true ;;
  revoke) enabled=false ;;
  *) usage ;;
esac
email="$2"
if [[ ! "$email" =~ ^[^[:space:]@]+@[^[:space:]@]+\.[^[:space:]@]+$ ]]; then
  echo "Not an email address: $email" >&2
  exit 2
fi

# The email is passed as a psql variable, never pasted into the SQL.
sql="select public.set_moderator(:'email', :'enabled'::boolean);"
args=(-X -q -t -A -v ON_ERROR_STOP=1 -v "email=$email" -v "enabled=$enabled")

if [[ -n "${DATABASE_URL:-}" ]]; then
  result=$(psql "$DATABASE_URL" "${args[@]}" <<<"$sql")
else
  result=$(docker exec -i supabase_db_zema psql -U postgres "${args[@]}" <<<"$sql")
fi

case "$result" in
  granted) echo "$email is now a moderator." ;;
  revoked) echo "$email is no longer a moderator." ;;
  unchanged) echo "No change: $email already had that role setting." ;;
  *) echo "$result" ;;
esac
