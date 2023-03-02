create table copy_mix_playlists
(
    source_id text,
    target_id text unique not null,
    user_id   uuid not null references users (id),
    last_mix  timestamptz,
    unique (source_id, user_id)
);

create index on copy_mix_playlists (source_id);
