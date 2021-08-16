# reset edgedb_scram

DROP ROLE edgedb_scram;

CONFIGURE INSTANCE
RESET Auth
FILTER Auth.user = 'edgedb_scram';


# reset edgedb_trust

DROP ROLE edgedb_trust;

CONFIGURE INSTANCE
RESET Auth
FILTER Auth.user = 'edgedb_trust';
