CREATE MIGRATION m1cf555gemqtjglvd5sthjsrnjrdecxkdeyrd3wpbkpvozjeovxyxq
    ONTO m1ta2vukbkhirlahnlekib6cdudqzlol6wu5aztvowsg5skarqmh5a
{
  ALTER TYPE default::Genre {
      DROP PROPERTY slug;
      DROP PROPERTY title;
  };
  ALTER TYPE default::Song {
      DROP LINK genre;
  };
  DROP TYPE default::Genre;
};
