CREATE MIGRATION m13t5esb4neq5k7pwacj6izyxsvblyaf7e7x3hndvfutgbalz72qxa
    ONTO m1ibh7njtapjtc6qlcv2aw6gxrebw5zwvagpx6mlxplmq7nwpzo36a
{
  ALTER TYPE default::Song {
      CREATE REQUIRED PROPERTY mp3_filesize -> std::int64 {
          SET default := 0;
      };
  };
};
