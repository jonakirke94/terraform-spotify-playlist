terraform {
  required_providers {
    spotify = {
      version = "~> 0.2.6"
      source  = "conradludgate/spotify"
    }
  }
}

provider "spotify" {
  api_key = var.spotify_api_key
}

locals {
  songs = [
    "https://open.spotify.com/track/0qttxLLyAshPduVf6LRGKk?si=84439a83686344e6" # Sometimes I Rhyme Slow
    , "https://open.spotify.com/track/0PV1TFUMTBrDETzW6KQulB"                   # 93 'Til Infinity
    , "https://open.spotify.com/track/5ByAIlEEnxYdvpnezg7HTX"                   # Juicy 2005 - Remaster
  ]
}

data "spotify_track" "tracks" {
  for_each = toset(local.songs)
  url      = each.key
}

# Throw some Nas in there
data "spotify_search_track" "by_artist" {
  artist   = "Nas"
  limit    = 3
  album    = "Illmatic XX"
  explicit = true
}

# Shuffle the playlist
resource "random_shuffle" "tracks" {
  input = concat(
    [
      for track in data.spotify_track.tracks : track.id
    ],
    data.spotify_search_track.by_artist.tracks.*.id
  )

  keepers = {
    # Shuffle the playlist everytime terraform is evaluated
    "id" : uuid()
  }
}

resource "random_pet" "playlist_name" {
  prefix = "tf"
}


resource "spotify_playlist" "playlist" {
  name        = random_pet.playlist_name.id
  description = "This playlist was created by Terraform"
  public      = true

  tracks = random_shuffle.tracks.result
}
