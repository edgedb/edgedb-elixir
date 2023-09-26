CREATE MIGRATION m12w3z4oofn5dke5mw3oirfpgbfyhi5lweuklpzb4xrybtxq3oqoeq
    ONTO m1bex2l6siwpxeifsgdqah5p2uh2shovtwuyd5fifvfofdafnkl6ja
{
  ALTER TYPE default::Song {
      ALTER PROPERTY duration {
          SET default := (<std::duration>'0 seconds');
          SET TYPE std::duration USING (<std::duration>(std::to_str(.duration) ++ ' seconds'));
      };
  };
};
