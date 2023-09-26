CREATE MIGRATION m1zvprfqkveu4mb4kou74xgiar2yt5abpnu5ntsqhki7lbeinjznbq
    ONTO m13t5esb4neq5k7pwacj6izyxsvblyaf7e7x3hndvfutgbalz72qxa
{
  CREATE FUNCTION default::to_status(status: std::str) -> OPTIONAL default::SongStatus USING (WITH
      status := 
          std::str_title(status)
  SELECT
      (<default::SongStatus>status IF (status IN {'Stopped', 'Playing', 'Paused'}) ELSE <default::SongStatus>{})
  );
};
