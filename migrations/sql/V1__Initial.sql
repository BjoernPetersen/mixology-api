create table users
(
    id                    uuid unique not null,
    spotify_id            text unique not null,
    name                  text        not null,
    spotify_refresh_token text        not null
);
