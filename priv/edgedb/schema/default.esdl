module default {
  required global max_songs_count := 30;

  global is_admin: bool;

  global current_user_id: uuid;
  global current_user := (
    select User filter .id = global current_user_id
  );

  # cast insensitive string
  scalar type cistr extending str;

  abstract type Timestamped {
    required inserted_at: cal::local_datetime {
      readonly := true;
      rewrite insert using (cal::to_local_datetime(datetime_current(), 'UTC'))
    }

    required updated_at: cal::local_datetime {
      rewrite insert, update using (cal::to_local_datetime(datetime_current(), 'UTC'))
    }
  }

  type User extending Timestamped {
    required name: str;
    required username: str {
      constraint exclusive;
    }

    required email: cistr {
      constraint regexp(r'^[^\s]+@[^\s]+$');
      constraint max_len_value(160);

      rewrite insert, update using (str_lower(__subject__.email));
    }

    profile_tagline: str;

    avatar_url: str;
    external_homepage_url: str;

    property songs_count := count(.<user[is Song]);

    active_profile_user: User {
      on target delete allow;
    }

    access policy owner_can_do_everything
      allow all
      using (global current_user.id ?= .id);

    access policy anyone_can_read_or_create
      allow select, insert;

    index on (.email);
    index on (.username);
  }

  type Identity extending Timestamped {
    required provider: str;
    required provider_id: str;
    required provider_token: str;
    required provider_login: str;

    required provider_email: cistr {
      rewrite insert, update using (str_lower(__subject__.provider_email))
    }

    required provider_meta: json {
      default := <json>"{}";
    }

    required user: User {
      on target delete delete source;
    }

    access policy owner_can_do_everything
      allow all
      using (global current_user.id ?= .user.id);

    access policy anyone_can_create
      allow insert;

    index on (.provider);
    constraint exclusive on ((.user, .provider));
  }

  scalar type SongStatus extending enum<stopped, playing, paused>;
  scalar type inet extending bytes;

  type MP3 {
    required url: str;
    required filename: str;
    required filepath: str;

    required filesize: cfg::memory {
      default := <cfg::memory>0
    }
  }

  type Song extending Timestamped {
    required title: str;
    required artist: str;

    attribution: str;

    server_ip: inet;

    required duration: duration {
      default := <duration>'0 seconds';
    }

    required position: int64 {
      default := 0;
    }

    required status: SongStatus {
      default := SongStatus.stopped;
    }

    date_recorded: cal::local_datetime;
    date_released: cal::local_datetime;

    played_at: datetime {
      rewrite update using (
        datetime_current()
        if __subject__.status = SongStatus.playing
        else __old__.played_at
      )
    }

    paused_at: datetime {
      rewrite update using (
        datetime_current()
        if __subject__.status = SongStatus.stopped
        else __old__.played_at
      )
    }

    required mp3: MP3 {
      on source delete delete target;
    }

    user: User {
      # allow to keep songs until the cleaner deletes it with the real file
      on target delete allow;
    }

    access policy owner_can_do_everything
      allow all
      using (global current_user.id ?= .user.id);

    access policy admin_can_do_everything
      allow all
      using (global is_admin ?= true);

    access policy anyone_can_read
      allow select;

    trigger ensure_user_songs_count_not_exceeded after insert, update for each do (
      assert(
        __new__.user.songs_count <= global max_songs_count,
        message := "Songs limit exceeded",
      )
    );

    index on (.status);
    constraint exclusive on ((.user, .title, .artist));
  }
}
