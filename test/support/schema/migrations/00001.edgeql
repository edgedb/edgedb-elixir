CREATE MIGRATION m1c65s2cgnjqbm4zvuyv6saeqpi5c446bceydxxr35zmjbf2ndymsq
    ONTO initial
{
  CREATE MODULE v1 IF NOT EXISTS;
  CREATE ABSTRACT LINK v1::crew {
      CREATE PROPERTY list_order: std::int64;
  };
  CREATE TYPE v1::Person {
      CREATE REQUIRED PROPERTY first_name: std::str;
      CREATE REQUIRED PROPERTY last_name: std::str;
      CREATE REQUIRED PROPERTY middle_name: std::str;
  };
  CREATE TYPE v1::Movie {
      CREATE MULTI LINK actors: v1::Person {
          EXTENDING v1::crew;
      };
      CREATE MULTI LINK directors: v1::Person {
          EXTENDING v1::crew;
      };
      CREATE PROPERTY description: std::str;
      CREATE REQUIRED PROPERTY title: std::str;
      CREATE REQUIRED PROPERTY year: std::int64;
  };
  CREATE SCALAR TYPE v1::TicketNo EXTENDING std::sequence;
  CREATE TYPE v1::Ticket {
      CREATE PROPERTY number: v1::TicketNo {
          CREATE CONSTRAINT std::exclusive;
      };
  };
  CREATE TYPE v1::User {
      CREATE REQUIRED PROPERTY name: std::str;
  };
  CREATE SCALAR TYPE v1::Color EXTENDING enum<Red, Green, Blue>;
  CREATE SCALAR TYPE v1::short_str EXTENDING std::str {
      CREATE CONSTRAINT std::max_len_value(5);
  };
};
