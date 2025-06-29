\set pguser `echo "$POSTGRES_USER"`

\c _supabase
create schema if not exists n8n;
alter schema n8n owner to :pguser;
\c postgres
