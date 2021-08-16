# setup edgedb_scram

CREATE SUPERUSER ROLE edgedb_scram;

ALTER ROLE edgedb_scram SET password := 'edgedb';

CONFIGURE INSTANCE INSERT Auth {
    user := 'edgedb_scram',
    method := (INSERT SCRAM),
    priority := 1
};


# setup edgedb_scram

CREATE SUPERUSER ROLE edgedb_trust;

CONFIGURE INSTANCE INSERT Auth {
    user := 'edgedb_trust',
    method := (INSERT Trust),
    priority := 2
};
