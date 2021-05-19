CREATE MIGRATION m1la5u4qi33nsrhorvl6u7zdiiuvrx6y647mhk3c7suj7ex5jx5ija
    ONTO initial
{
  CREATE TYPE default::Person {
      CREATE REQUIRED PROPERTY first_name -> std::str;
      CREATE REQUIRED PROPERTY last_name -> std::str;
  };
  CREATE TYPE default::Movie {
      CREATE MULTI LINK actors -> default::Person;
      CREATE REQUIRED LINK director -> default::Person;
      CREATE REQUIRED PROPERTY title -> std::str;
      CREATE PROPERTY year -> std::int64;
  };
};
