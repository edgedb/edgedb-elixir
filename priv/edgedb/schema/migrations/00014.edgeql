CREATE MIGRATION m1okgh4wtvnuxdcf7b65cbx6okhb3twpxdkppoc6lv5zotvhcn5ika
    ONTO m1it7pwkmkmpv26wjsb7meak75pa7pex2j6mya7yozolbmincbgcza
{
  ALTER TYPE default::Identity {
      ALTER PROPERTY provider_email {
          SET TYPE default::cistr;
          CREATE REWRITE
              INSERT 
              USING (std::str_lower(__subject__.provider_email));
          CREATE REWRITE
              UPDATE 
              USING (std::str_lower(__subject__.provider_email));
      };
  };
};
