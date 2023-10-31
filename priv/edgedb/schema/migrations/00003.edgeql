CREATE MIGRATION m17xqasqccfam62oqoyltgemn7mrdws33vik4bodj67kcmwfa3mq6q
    ONTO m1s4rwuphzakukj3i6wqbwi534ctcmaulpn4a4wfclpejyowtxkloq
{
  CREATE EXTENSION pgvector VERSION '0.4';
  CREATE MODULE v3 IF NOT EXISTS;
  CREATE SCALAR TYPE v3::ExVector EXTENDING ext::pgvector::vector<1602>;
};
