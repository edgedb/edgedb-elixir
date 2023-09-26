select Song {
  *,
  mp3: {
    *
  },
  user: {
    id,
  }
}
filter
  .user.id = <uuid>$user_id
    and
  .status in {SongStatus.playing, SongStatus.paused}
limit 1
