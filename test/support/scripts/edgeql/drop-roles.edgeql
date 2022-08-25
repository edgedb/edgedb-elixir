# reset edgedb_scram

drop role edgedb_scram;

configure INSTANCE
reset Auth
filter Auth.user = 'edgedb_scram';


# reset edgedb_trust

drop role edgedb_trust;

configure INSTANCE
reset Auth
filter Auth.user = 'edgedb_trust';
