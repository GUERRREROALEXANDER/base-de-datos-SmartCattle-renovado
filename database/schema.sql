-- SmartCattle: PostgreSQL schema (safe to run several times).
--
-- Table and column names are English, matching the REST API, so no service has
-- to translate between the two. Every timestamp is stored in UTC (timestamptz).

CREATE TABLE IF NOT EXISTS cameras (
    id          BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    name        TEXT        NOT NULL UNIQUE,
    source      TEXT        NOT NULL DEFAULT '0',  -- USB index, video path or RTSP URL
    location    TEXT,
    active      BOOLEAN     NOT NULL DEFAULT TRUE,
    created_at  TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Rectangular safe zone, coordinates normalised between 0 and 1 (as SAFE_ZONE was).
CREATE TABLE IF NOT EXISTS zones (
    id          BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    camera_id   BIGINT      NOT NULL REFERENCES cameras(id) ON DELETE CASCADE,
    name        TEXT        NOT NULL,
    x_min       REAL        NOT NULL CHECK (x_min BETWEEN 0 AND 1),
    y_min       REAL        NOT NULL CHECK (y_min BETWEEN 0 AND 1),
    x_max       REAL        NOT NULL CHECK (x_max BETWEEN 0 AND 1),
    y_max       REAL        NOT NULL CHECK (y_max BETWEEN 0 AND 1),
    active      BOOLEAN     NOT NULL DEFAULT TRUE,
    created_at  TIMESTAMPTZ NOT NULL DEFAULT now(),
    UNIQUE (camera_id, name),
    CHECK (x_min < x_max AND y_min < y_max)
);

-- People who use the system. Registration stores who they are and whether they
-- own the farm or work on it.
CREATE TABLE IF NOT EXISTS users (
    id             BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    -- Lower-cased before it is stored, so one address cannot register twice
    -- under different capitalisation.
    email          TEXT        NOT NULL UNIQUE CHECK (email = lower(email)),
    -- NEVER the password itself: a bcrypt hash, which cannot be reversed. A
    -- leaked table must not hand over the accounts it describes.
    password_hash  TEXT        NOT NULL,
    full_name      TEXT        NOT NULL,
    -- 'owner' owns the farm, 'worker' works on it. The column records the role;
    -- what each role is allowed to do is not enforced here yet.
    role           TEXT        NOT NULL DEFAULT 'worker'
                   CHECK (role IN ('owner', 'worker')),
    -- Access is withdrawn by clearing this flag, not by deleting the row: an
    -- account that is gone cannot be told apart from one that never existed.
    is_active      BOOLEAN     NOT NULL DEFAULT TRUE,
    created_at     TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at     TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS users_role_idx ON users (role);

-- Animal registry. Individual identification by the AI is a future phase.
--
-- The primary key is the ear tag, not a database number: the tag is the real
-- identity of the animal, the one physically on its ear and the one the farm
-- staff use. A second numeric identifier would mean translating between the two
-- on every query.
--
-- There is no breed, sex or birth date: SmartCattle tracks cattle for security
-- -- where an animal is and whether it left its zone -- and does not manage the
-- herd commercially. Those are zootechnical and valuation data, and they do not
-- help locate an animal.
CREATE TABLE IF NOT EXISTS animals (
    tag             TEXT        PRIMARY KEY,       -- ear tag, name or code
    status          TEXT        NOT NULL DEFAULT 'active'
                    CHECK (status IN ('active', 'inactive', 'lost')),
    camera_id       BIGINT      REFERENCES cameras(id) ON DELETE SET NULL,
    zone_id         BIGINT      REFERENCES zones(id)   ON DELETE SET NULL,
    name            TEXT,       -- so staff recognise which animal an alert is about
    last_detection  TIMESTAMPTZ,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at      TIMESTAMPTZ NOT NULL DEFAULT now()
);
-- Animals are deactivated, never deleted, so "the active herd" is the common
-- query. Without this index it scans the table.
CREATE INDEX IF NOT EXISTS animals_status_idx ON animals (status);

