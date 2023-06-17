CREATE MIGRATION m16wualxmsuqqryhwrn6kgd6upwxge3cwruitgz63wbe5mynxxieva
    ONTO m1ryrngpym75cc5zcmkrfebkg6dcmyflzu7727vnjhmy2zl4q3tjda
{
  CREATE EXTENSION pgvector VERSION '0.4';
  CREATE SCALAR TYPE default::ExVector EXTENDING ext::pgvector::vector<1602>;
};
