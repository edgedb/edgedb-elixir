CREATE MIGRATION m1ujqlj37zkefvbigraftt72bbdxu2q6mcun4xg7hwkeyuuxtgxhrq
    ONTO initial
{
  CREATE SCALAR TYPE default::cistr EXTENDING std::str;
  CREATE TYPE default::User {
      CREATE REQUIRED PROPERTY username -> std::str;
      CREATE INDEX ON (.username);
      CREATE REQUIRED PROPERTY email -> default::cistr;
      CREATE INDEX ON (.email);
      CREATE LINK active_profile_user -> default::User {
          ON TARGET DELETE  ALLOW;
      };
      CREATE PROPERTY confirmed_at -> cal::local_datetime;
      CREATE REQUIRED PROPERTY inserted_at -> cal::local_datetime {
          SET default := (cal::to_local_datetime(std::datetime_current(), 'UTC'));
      };
      CREATE PROPERTY name -> std::str;
      CREATE PROPERTY profile_tagline -> std::str;
      CREATE REQUIRED PROPERTY role -> std::str {
          SET default := ("subscriber");
      };
      CREATE REQUIRED PROPERTY updated_at -> cal::local_datetime {
          SET default := (cal::to_local_datetime(std::datetime_current(), 'UTC'));
      };
  };
  CREATE TYPE default::Identity {
      CREATE REQUIRED LINK user -> default::User {
          ON TARGET DELETE  DELETE SOURCE;
      };
      CREATE REQUIRED PROPERTY provider -> std::str;
      CREATE CONSTRAINT std::exclusive ON ((.user, .provider));
      CREATE INDEX ON (.provider);
      CREATE REQUIRED PROPERTY inserted_at -> cal::local_datetime {
          SET default := (cal::to_local_datetime(std::datetime_current(), 'UTC'));
      };
      CREATE REQUIRED PROPERTY provider_email -> std::str;
      CREATE REQUIRED PROPERTY provider_id -> std::str;
      CREATE REQUIRED PROPERTY provider_login -> std::str;
      CREATE REQUIRED PROPERTY provider_meta -> std::json {
          SET default := (<std::json>'{}');
      };
      CREATE REQUIRED PROPERTY provider_token -> std::str;
      CREATE REQUIRED PROPERTY updated_at -> cal::local_datetime {
          SET default := (cal::to_local_datetime(std::datetime_current(), 'UTC'));
      };
  };
};
