CREATE MIGRATION m1hd7litg4ylc632kuyv3xqipk6bvjgcrbeoujgvoccts65yholkda
    ONTO m147bo4znisjhp7ymyunkfc66a3hqctob7lq5jp2xy2m4gh5vkzzya
{
  CREATE SCALAR TYPE default::inet EXTENDING std::bytes;
  ALTER TYPE default::Song {
      CREATE PROPERTY server_ip -> default::inet;
  };
};
