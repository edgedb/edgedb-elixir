CREATE MIGRATION m1oedxfngt5vozzopffjedf7c7iarwvpdhlja662rcprw2cbk6y65q
    ONTO m1s4rwuphzakukj3i6wqbwi534ctcmaulpn4a4wfclpejyowtxkloq
{
  CREATE EXTENSION pgvector VERSION '0.5';
  CREATE MODULE v3 IF NOT EXISTS;
  CREATE SCALAR TYPE v3::ExVector EXTENDING ext::pgvector::vector<1602>;
};
