CREATE MIGRATION m1bex2l6siwpxeifsgdqah5p2uh2shovtwuyd5fifvfofdafnkl6ja
    ONTO m1cf555gemqtjglvd5sthjsrnjrdecxkdeyrd3wpbkpvozjeovxyxq
{
  CREATE TYPE default::MP3 {
      CREATE REQUIRED PROPERTY filename: std::str;
      CREATE REQUIRED PROPERTY filepath: std::str;
      CREATE REQUIRED PROPERTY filesize: cfg::memory {
          SET default := (<cfg::memory>0);
      };
      CREATE REQUIRED PROPERTY url: std::str;
  };
  ALTER TYPE default::Song {
      CREATE REQUIRED LINK mp3: default::MP3 {
          ON SOURCE DELETE DELETE TARGET;
          SET REQUIRED USING (<default::MP3>(INSERT
              default::MP3
              {
                  url := default::Song.mp3_url,
                  filename := default::Song.mp3_filename,
                  filepath := default::Song.mp3_filepath,
                  filesize := <cfg::memory>default::Song.mp3_filesize
              }));
      };
  };
  ALTER TYPE default::Song {
      DROP PROPERTY mp3_filename;
      DROP PROPERTY mp3_filepath;
      DROP PROPERTY mp3_filesize;
      DROP PROPERTY mp3_url;
  };
};
