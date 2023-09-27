update Song
  filter .id = <uuid>$song_id
  set {
    status := SongStatus.paused
  }