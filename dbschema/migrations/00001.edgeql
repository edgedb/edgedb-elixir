CREATE MIGRATION m1rahkluhmslej6r43e7hazzj6wc6vpr6besi2cb7a4iqjdgtjoxia
    ONTO initial
{
  CREATE ABSTRACT LINK default::crew {
      CREATE PROPERTY list_order -> std::int64;
  };
  CREATE ABSTRACT TYPE default::HasImage {
      CREATE REQUIRED PROPERTY image -> std::str;
      CREATE INDEX ON (.image);
  };
  CREATE TYPE default::Movie EXTENDING default::HasImage {
      CREATE PROPERTY description -> std::str;
      CREATE REQUIRED PROPERTY title -> std::str;
      CREATE REQUIRED PROPERTY year -> std::int64;
      CREATE INDEX ON (.year);
      CREATE INDEX ON ((.title, .year));
      CREATE INDEX ON (.title);
  };
  CREATE TYPE default::User EXTENDING default::HasImage {
      CREATE REQUIRED PROPERTY name -> std::str;
  };
  CREATE TYPE default::Review {
      CREATE REQUIRED LINK movie -> default::Movie;
      CREATE REQUIRED PROPERTY rating -> std::int64 {
          CREATE CONSTRAINT std::max_value(5);
          CREATE CONSTRAINT std::min_value(0);
      };
      CREATE REQUIRED LINK author -> default::User;
      CREATE REQUIRED PROPERTY body -> std::str;
      CREATE REQUIRED PROPERTY creation_time -> std::datetime {
          SET default := (std::datetime_current());
      };
      CREATE REQUIRED PROPERTY flag -> std::bool {
          SET default := false;
      };
  };
  ALTER TYPE default::Movie {
      CREATE PROPERTY avg_rating := (math::mean(.<movie[IS default::Review].rating));
  };
  CREATE ALIAS default::MovieAlias := (
      default::Movie {
          reviews := .<movie[IS default::Review]
      }
  );
  CREATE ALIAS default::ReviewAlias := (
      default::Review {
          author_name := .author.name,
          movie_title := .movie.title
      }
  );
  CREATE ABSTRACT LINK default::actors EXTENDING default::crew;
  CREATE TYPE default::Person EXTENDING default::HasImage {
      CREATE PROPERTY bio -> std::str;
      CREATE REQUIRED PROPERTY first_name -> std::str {
          SET default := '';
      };
      CREATE REQUIRED PROPERTY last_name -> std::str;
      CREATE REQUIRED PROPERTY middle_name -> std::str {
          SET default := '';
      };
      CREATE PROPERTY full_name := (((((.first_name ++ ' ') IF (.first_name != '') ELSE '') ++ ((.middle_name ++ ' ') IF (.middle_name != '') ELSE '')) ++ .last_name));
  };
  ALTER TYPE default::Movie {
      CREATE MULTI LINK actors EXTENDING default::crew -> default::Person;
      CREATE MULTI LINK directors EXTENDING default::crew -> default::Person;
  };
  CREATE ABSTRACT LINK default::directors EXTENDING default::crew;
  CREATE SCALAR TYPE default::TicketNo EXTENDING std::sequence;
  CREATE TYPE default::Ticket {
      CREATE PROPERTY number -> default::TicketNo {
          CREATE CONSTRAINT std::exclusive;
      };
  };
  CREATE FINAL SCALAR TYPE default::Color EXTENDING enum<Red, Green, Blue>;
  CREATE SCALAR TYPE default::short_str EXTENDING std::str {
      CREATE CONSTRAINT std::max_len_value(5);
  };
};
