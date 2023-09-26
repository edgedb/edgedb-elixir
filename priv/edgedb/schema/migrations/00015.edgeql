CREATE MIGRATION m1ta2vukbkhirlahnlekib6cdudqzlol6wu5aztvowsg5skarqmh5a
    ONTO m1okgh4wtvnuxdcf7b65cbx6okhb3twpxdkppoc6lv5zotvhcn5ika
{
  DROP FUNCTION default::to_status(status: std::str);
  ALTER TYPE default::Song {
      DROP INDEX ON (.status);
      DROP PROPERTY status;
  };
  ALTER SCALAR TYPE default::SongStatus EXTENDING enum<stopped, playing, paused>;
  ALTER TYPE default::Song {
      CREATE REQUIRED PROPERTY status: default::SongStatus {
          SET default := (default::SongStatus.stopped);
      };
      CREATE INDEX ON (.status);
  };
};
