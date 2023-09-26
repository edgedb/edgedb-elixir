CREATE MIGRATION m16cque5xr6zlbwpuvvxwhvjbuztypf4n6yqxke6z4hqtwwool4zva
    ONTO m12w3z4oofn5dke5mw3oirfpgbfyhi5lweuklpzb4xrybtxq3oqoeq
{
  ALTER TYPE default::Song {
      DROP PROPERTY album_artist;
      ALTER PROPERTY paused_at {
          CREATE REWRITE
              UPDATE 
              USING ((std::datetime_current() IF (__subject__.status = default::SongStatus.stopped) ELSE __old__.played_at));
      };
      ALTER PROPERTY played_at {
          CREATE REWRITE
              UPDATE 
              USING ((std::datetime_current() IF (__subject__.status = default::SongStatus.playing) ELSE __old__.played_at));
      };
  };
};
