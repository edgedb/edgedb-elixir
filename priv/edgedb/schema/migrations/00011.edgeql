CREATE MIGRATION m1cyoreiep3r4h2dwl3pjujbjiyly67f55rbfqxnqkmdueffvxgcba
    ONTO m1qcv5nieywf4bygcrna7cf7ygkdarqelwig6xnjwpzdfkktdfwh3q
{
  ALTER TYPE default::Identity {
      CREATE PROPERTY inserted_at: cal::local_datetime {
          SET REQUIRED USING (<cal::local_datetime>.inserted_at_legacy);
      };
      CREATE PROPERTY updated_at: cal::local_datetime {
          SET REQUIRED USING (<cal::local_datetime>.updated_at_legacy);
      };
      EXTENDING default::Timestamped LAST;
  };
  ALTER TYPE default::Identity {
      ALTER PROPERTY inserted_at {
          RESET OPTIONALITY;
          DROP OWNED;
          RESET TYPE;
      };
      ALTER PROPERTY updated_at {
          RESET OPTIONALITY;
          DROP OWNED;
          RESET TYPE;
      };
  };
  ALTER TYPE default::Song {
      CREATE PROPERTY inserted_at: cal::local_datetime {
          SET REQUIRED USING (<cal::local_datetime>.inserted_at_legacy);
      };
      CREATE PROPERTY updated_at: cal::local_datetime {
          SET REQUIRED USING (<cal::local_datetime>.updated_at_legacy);
      };
      EXTENDING default::Timestamped LAST;
  };
  ALTER TYPE default::Song {
      ALTER PROPERTY inserted_at {
          RESET OPTIONALITY;
          DROP OWNED;
          RESET TYPE;
      };
      ALTER PROPERTY updated_at {
          RESET OPTIONALITY;
          DROP OWNED;
          RESET TYPE;
      };
  };
  ALTER TYPE default::User {
      CREATE PROPERTY inserted_at: cal::local_datetime {
          SET REQUIRED USING (<cal::local_datetime>.inserted_at_legacy);
      };
      CREATE PROPERTY updated_at: cal::local_datetime {
          SET REQUIRED USING (<cal::local_datetime>.updated_at_legacy);
      };
      EXTENDING default::Timestamped LAST;
  };
  ALTER TYPE default::User {
      ALTER PROPERTY inserted_at {
          RESET OPTIONALITY;
          DROP OWNED;
          RESET TYPE;
      };
      ALTER PROPERTY updated_at {
          RESET OPTIONALITY;
          DROP OWNED;
          RESET TYPE;
      };
  };
};
