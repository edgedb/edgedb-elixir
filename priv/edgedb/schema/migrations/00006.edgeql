CREATE MIGRATION m1ibh7njtapjtc6qlcv2aw6gxrebw5zwvagpx6mlxplmq7nwpzo36a
    ONTO m1hd7litg4ylc632kuyv3xqipk6bvjgcrbeoujgvoccts65yholkda
{
  ALTER TYPE default::User {
      CREATE PROPERTY songs_count := (std::count(.<user[IS default::Song]));
  };
};
