-- HTH Pack Contract: v1
--   control: lovable-5.1
--   guide:   https://howtoharden.com/guides/lovable/#51-enforce-row-level-security-on-every-table-before-go-live
--   profile: L1
--   mode:    read-only
--   requires: a Lovable Cloud project; run in its More -> Cloud -> SQL editor
-- =============================================================================
-- HTH Lovable Control 5.1: Enforce Row-Level Security on Every Table Before Go-Live
-- Profile Level: L1 (Crawl) | Plan: all plans with Lovable Cloud
-- Frameworks: NIST 800-53 AC-3/AC-6 | CIS Controls v8 3.3, 16.1
-- Where it runs: the project's SQL editor, the vendor-native query surface over the
--   managed Postgres behind every Lovable Cloud project:
--   https://docs.lovable.dev/features/database (Run SQL queries; RLS policies)
-- What it reads: PostgreSQL system catalogs only — pg_class.relrowsecurity, relkind
--   (https://www.postgresql.org/docs/current/catalog-pg-class.html) and the
--   pg_policies view (https://www.postgresql.org/docs/current/view-pg-policies.html).
--   SELECT only; nothing here changes the database.
--
-- Two checks, each an independent query. Any row returned is a finding; zero rows is
-- the passing result. A table with RLS ON and no policies is NOT reported: Postgres
-- then applies a default-deny policy ("no rows are visible or can be modified").
-- Scope is the `public` schema, which the app's client-side API exposes; extend the
-- schema list if your project exposes others. Fix findings by asking Lovable in chat
-- (the RLS policies view is read-only), then re-run.
-- =============================================================================

-- HTH Guide Excerpt: begin db-rls-disabled-tables
-- Tables (ordinary and partitioned) in the exposed schema with row-level security OFF:
-- every row is readable and writable by any client the API lets through.
SELECT n.nspname AS schema_name,
       c.relname AS table_name
FROM pg_catalog.pg_class AS c
JOIN pg_catalog.pg_namespace AS n ON n.oid = c.relnamespace
WHERE c.relkind IN ('r', 'p')
  AND n.nspname = 'public'
  AND NOT c.relrowsecurity
ORDER BY n.nspname, c.relname;
-- HTH Guide Excerpt: end db-rls-disabled-tables

-- HTH Guide Excerpt: begin db-rls-open-policies
-- Permissive policies that let anonymous callers (role anon, or PUBLIC = every role)
-- through unconditionally: USING (true) or WITH CHECK (true). Intentionally public
-- read-only data is a legitimate exception — document it; anything writable is not.
SELECT schemaname,
       tablename,
       policyname,
       cmd,
       roles,
       qual,
       with_check
FROM pg_catalog.pg_policies
WHERE schemaname = 'public'
  AND permissive = 'PERMISSIVE'
  AND roles && ARRAY['anon', 'public']::name[]
  AND (qual = 'true' OR with_check = 'true')
ORDER BY schemaname, tablename, policyname;
-- HTH Guide Excerpt: end db-rls-open-policies
