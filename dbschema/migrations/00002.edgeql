CREATE MIGRATION m12ld7edxlpf7d6mwlfb3wb37ukukskghkpvrbqiuknwg6bxesxiwq
    ONTO m1la5u4qi33nsrhorvl6u7zdiiuvrx6y647mhk3c7suj7ex5jx5ija
{
  CREATE ABSTRACT LINK default::crew {
      CREATE PROPERTY list_order -> std::int64;
  };
  CREATE ABSTRACT TYPE default::HasImage {
      CREATE REQUIRED PROPERTY image -> std::str;
      CREATE INDEX ON (.image);
  };
  ALTER TYPE default::Person {
      CREATE PROPERTY image -> std::str {
          SET REQUIRED USING ('<missing>');
      };
      EXTENDING default::HasImage LAST;
  };
  ALTER TYPE default::Movie {
      CREATE PROPERTY image -> std::str {
          SET REQUIRED USING ('<missing>');
      };
      EXTENDING default::HasImage LAST;
      ALTER LINK actors {
          EXTENDING default::crew LAST;
      };
  };
  ALTER TYPE default::Movie {
      CREATE MULTI LINK directors EXTENDING default::crew -> default::Person;
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
  ALTER TYPE default::Movie {
      CREATE PROPERTY description -> std::str;
  };
  ALTER TYPE default::Movie {
      ALTER PROPERTY image {
          RESET OPTIONALITY;
          DROP OWNED;
          RESET TYPE;
      };
  };
  ALTER TYPE default::Movie {
      ALTER PROPERTY year {
          SET REQUIRED USING (2000);
      };
      CREATE INDEX ON (.year);
      CREATE INDEX ON ((.title, .year));
      CREATE INDEX ON (.title);
      DROP LINK director;
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
  CREATE ABSTRACT LINK default::directors EXTENDING default::crew;
  ALTER TYPE default::Person {
      CREATE PROPERTY bio -> std::str;
  };
  ALTER TYPE default::Person {
      ALTER PROPERTY first_name {
          SET default := '';
      };
  };
  ALTER TYPE default::Person {
      CREATE REQUIRED PROPERTY middle_name -> std::str {
          SET default := '';
      };
  };
  ALTER TYPE default::Person {
      CREATE PROPERTY full_name := (((((.first_name ++ ' ') IF (.first_name != '') ELSE '') ++ ((.middle_name ++ ' ') IF (.middle_name != '') ELSE '')) ++ .last_name));
      ALTER PROPERTY image {
          DROP OWNED;
          RESET TYPE;
          RESET OPTIONALITY;
      };
  };
  CREATE SCALAR TYPE default::TicketNo EXTENDING std::sequence;
  CREATE TYPE default::Ticket {
      CREATE PROPERTY number -> default::TicketNo {
          CREATE CONSTRAINT std::exclusive;
      };
  };
  CREATE FINAL SCALAR TYPE default::Color EXTENDING enum<Red, Green, Blue>;
};
