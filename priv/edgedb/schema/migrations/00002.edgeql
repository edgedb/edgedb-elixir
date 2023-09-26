CREATE MIGRATION m1bwaytmgkte3dpabashzohfm56w3yirzomvfbh5r7cbay5jytegaa
    ONTO m1ujqlj37zkefvbigraftt72bbdxu2q6mcun4xg7hwkeyuuxtgxhrq
{
  CREATE TYPE default::Genre {
      CREATE REQUIRED PROPERTY slug -> std::str {
          CREATE CONSTRAINT std::exclusive;
      };
      CREATE REQUIRED PROPERTY title -> std::str {
          CREATE CONSTRAINT std::exclusive;
      };
  };
};
