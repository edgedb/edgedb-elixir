# setup edgedb_scram

create superuser role edgedb_scram {
    set password := 'edgedb_scram_password'
};

configure instance insert Auth {
    user := 'edgedb_scram',
    method := (insert SCRAM),
    priority := 2
};


# setup edgedb_scram

create superuser role edgedb_trust;

configure instance insert Auth {
    user := 'edgedb_trust',
    method := (insert Trust),
    priority := 3
};
