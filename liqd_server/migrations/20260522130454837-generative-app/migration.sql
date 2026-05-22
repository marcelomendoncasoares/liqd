BEGIN;

--
-- ACTION CREATE TABLE
--
CREATE TABLE "user_app" (
    "id" bigserial PRIMARY KEY,
    "authUserId" uuid NOT NULL,
    "title" text NOT NULL,
    "surfaceState" json NOT NULL,
    "createdAt" timestamp without time zone NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" timestamp without time zone NOT NULL DEFAULT CURRENT_TIMESTAMP
);

--
-- ACTION CREATE TABLE
--
CREATE TABLE "user_widget" (
    "id" bigserial PRIMARY KEY,
    "authUserId" uuid NOT NULL,
    "name" text NOT NULL,
    "description" text NOT NULL,
    "dataSchema" json,
    "stacJson" json NOT NULL,
    "isSeed" boolean NOT NULL DEFAULT false,
    "createdAt" timestamp without time zone NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- Indexes
CREATE UNIQUE INDEX "user_widget_name_idx" ON "user_widget" USING btree ("authUserId", "name");


--
-- MIGRATION VERSION FOR liqd
--
INSERT INTO "serverpod_migrations" ("module", "version", "timestamp")
    VALUES ('liqd', '20260522130454837-generative-app', now())
    ON CONFLICT ("module")
    DO UPDATE SET "version" = '20260522130454837-generative-app', "timestamp" = now();

--
-- MIGRATION VERSION FOR serverpod
--
INSERT INTO "serverpod_migrations" ("module", "version", "timestamp")
    VALUES ('serverpod', '20260416151914983-insights-perf', now())
    ON CONFLICT ("module")
    DO UPDATE SET "version" = '20260416151914983-insights-perf', "timestamp" = now();

--
-- MIGRATION VERSION FOR serverpod_auth_idp
--
INSERT INTO "serverpod_migrations" ("module", "version", "timestamp")
    VALUES ('serverpod_auth_idp', '20260417182309198', now())
    ON CONFLICT ("module")
    DO UPDATE SET "version" = '20260417182309198', "timestamp" = now();

--
-- MIGRATION VERSION FOR serverpod_auth_core
--
INSERT INTO "serverpod_migrations" ("module", "version", "timestamp")
    VALUES ('serverpod_auth_core', '20260417182253191', now())
    ON CONFLICT ("module")
    DO UPDATE SET "version" = '20260417182253191', "timestamp" = now();


COMMIT;
