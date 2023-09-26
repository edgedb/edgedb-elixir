CREATE MIGRATION m1qb4i57nhmluwtd7pbeornej7kthhw34aejzjwrdcr65fiekxe3nq
    ONTO m1bwaytmgkte3dpabashzohfm56w3yirzomvfbh5r7cbay5jytegaa
{
  CREATE SCALAR TYPE default::SongStatus EXTENDING enum<Stopped, Playing, Paused>;
  CREATE TYPE default::Song {
      CREATE LINK user -> default::User {
          ON TARGET DELETE  ALLOW;
      };
      CREATE REQUIRED PROPERTY artist -> std::str;
      CREATE REQUIRED PROPERTY title -> std::str;
      CREATE CONSTRAINT std::exclusive ON ((.user, .title, .artist));
      CREATE REQUIRED PROPERTY status -> default::SongStatus {
          SET default := (default::SongStatus.Stopped);
      };
      CREATE INDEX ON (.status);
      CREATE LINK genre -> default::Genre {
          ON TARGET DELETE  ALLOW;
      };
      CREATE PROPERTY album_artist -> std::str;
      CREATE PROPERTY attribution -> std::str;
      CREATE PROPERTY date_recorded -> cal::local_datetime;
      CREATE PROPERTY date_released -> cal::local_datetime;
      CREATE REQUIRED PROPERTY duration -> std::int64 {
          SET default := 0;
      };
      CREATE REQUIRED PROPERTY inserted_at -> cal::local_datetime {
          SET default := (cal::to_local_datetime(std::datetime_current(), 'UTC'));
      };
      CREATE REQUIRED PROPERTY mp3_filename -> std::str;
      CREATE REQUIRED PROPERTY mp3_filepath -> std::str;
      CREATE REQUIRED PROPERTY mp3_url -> std::str;
      CREATE PROPERTY paused_at -> std::datetime;
      CREATE PROPERTY played_at -> std::datetime;
      CREATE REQUIRED PROPERTY updated_at -> cal::local_datetime {
          SET default := (cal::to_local_datetime(std::datetime_current(), 'UTC'));
      };
  };
};
