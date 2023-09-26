CREATE MIGRATION m1qcv5nieywf4bygcrna7cf7ygkdarqelwig6xnjwpzdfkktdfwh3q
    ONTO m1ec7ytvgzhdpcmpjfdumfdypk56ceoiftstllef3fzr6k5bnfesta
{
  ALTER TYPE default::Identity {
      ALTER PROPERTY inserted_at {
          RENAME TO inserted_at_legacy;
      };
  };
  ALTER TYPE default::Identity {
      ALTER PROPERTY updated_at {
          RENAME TO updated_at_legacy;
      };
  };
  ALTER TYPE default::Song {
      ALTER PROPERTY inserted_at {
          RENAME TO inserted_at_legacy;
      };
  };
  ALTER TYPE default::Song {
      ALTER PROPERTY updated_at {
          RENAME TO updated_at_legacy;
      };
  };
  CREATE ABSTRACT TYPE default::Timestamped {
      CREATE REQUIRED PROPERTY inserted_at: cal::local_datetime {
          SET readonly := true;
          CREATE REWRITE
              INSERT 
              USING (cal::to_local_datetime(std::datetime_current(), 'UTC'));
      };
      CREATE REQUIRED PROPERTY updated_at: cal::local_datetime {
          CREATE REWRITE
              INSERT 
              USING (cal::to_local_datetime(std::datetime_current(), 'UTC'));
          CREATE REWRITE
              UPDATE 
              USING (cal::to_local_datetime(std::datetime_current(), 'UTC'));
      };
  };
  ALTER TYPE default::User {
      ALTER PROPERTY inserted_at {
          RENAME TO inserted_at_legacy;
      };
  };
  ALTER TYPE default::User {
      ALTER PROPERTY updated_at {
          RENAME TO updated_at_legacy;
      };
  };
};
