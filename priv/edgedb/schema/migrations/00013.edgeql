CREATE MIGRATION m1it7pwkmkmpv26wjsb7meak75pa7pex2j6mya7yozolbmincbgcza
    ONTO m1z5zo6o4ommezfxgcgne2i5o5djt5wrso5qqatzc3rwont43wzyua
{
  ALTER TYPE default::User {
      DROP PROPERTY confirmed_at;
      ALTER PROPERTY email {
          CREATE CONSTRAINT std::max_len_value(160);
          CREATE CONSTRAINT std::regexp(r'^[^\s]+@[^\s]+$');
          CREATE REWRITE
              INSERT 
              USING (std::str_lower(__subject__.email));
          CREATE REWRITE
              UPDATE 
              USING (std::str_lower(__subject__.email));
      };
      ALTER PROPERTY name {
          SET REQUIRED USING (<std::str>.username);
      };
      DROP PROPERTY role;
      ALTER PROPERTY username {
          CREATE CONSTRAINT std::exclusive;
      };
  };
};
