CREATE MIGRATION m123g7cikfwawoirtb6cxdywwfyh3x4r6bcyqmrl3eoaod4g5ifqnq
    ONTO m16cque5xr6zlbwpuvvxwhvjbuztypf4n6yqxke6z4hqtwwool4zva
{
  CREATE GLOBAL default::current_user_id -> std::uuid;
  CREATE GLOBAL default::current_user := (SELECT
      default::User
  FILTER
      (.id = GLOBAL default::current_user_id)
  );
  ALTER TYPE default::Identity {
      CREATE ACCESS POLICY owner_can_do_everything
          ALLOW ALL USING (((GLOBAL default::current_user).id ?= .user.id));
      CREATE ACCESS POLICY anyone_can_create
          ALLOW INSERT ;
  };
  ALTER TYPE default::Song {
      CREATE ACCESS POLICY owner_can_do_everything
          ALLOW ALL USING (((GLOBAL default::current_user).id ?= .user.id));
  };
  ALTER TYPE default::User {
      CREATE ACCESS POLICY owner_can_do_everything
          ALLOW ALL USING (((GLOBAL default::current_user).id ?= .id));
      CREATE ACCESS POLICY anyone_can_read_or_create
          ALLOW SELECT, INSERT ;
  };
  CREATE REQUIRED GLOBAL default::max_songs_count := (30);
  ALTER TYPE default::Song {
      CREATE TRIGGER ensure_user_songs_count_not_exceeded
          AFTER UPDATE, INSERT 
          FOR EACH DO (std::assert((__new__.user.songs_count <= GLOBAL default::max_songs_count), message := 'Songs limit exceeded'));
  };
  CREATE GLOBAL default::is_admin -> std::bool;
  ALTER TYPE default::Song {
      CREATE ACCESS POLICY admin_can_do_everything
          ALLOW ALL USING ((GLOBAL default::is_admin ?= true));
      CREATE ACCESS POLICY anyone_can_read
          ALLOW SELECT ;
  };
};
