CREATE MIGRATION m1z5zo6o4ommezfxgcgne2i5o5djt5wrso5qqatzc3rwont43wzyua
    ONTO m1cyoreiep3r4h2dwl3pjujbjiyly67f55rbfqxnqkmdueffvxgcba
{
  ALTER TYPE default::Identity {
      DROP PROPERTY inserted_at_legacy;
      DROP PROPERTY updated_at_legacy;
  };
  ALTER TYPE default::Song {
      DROP PROPERTY inserted_at_legacy;
      DROP PROPERTY updated_at_legacy;
  };
  ALTER TYPE default::User {
      DROP PROPERTY inserted_at_legacy;
      DROP PROPERTY updated_at_legacy;
  };
};
