CREATE MIGRATION m1ec7ytvgzhdpcmpjfdumfdypk56ceoiftstllef3fzr6k5bnfesta
    ONTO m1zvprfqkveu4mb4kou74xgiar2yt5abpnu5ntsqhki7lbeinjznbq
{
  ALTER TYPE default::Song {
      CREATE REQUIRED PROPERTY position -> std::int64 {
          SET default := 0;
      };
  };
};
