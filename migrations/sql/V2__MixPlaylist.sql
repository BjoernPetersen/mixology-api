create table mix_playlists
(
    id       text not null,
    user_id  uuid not null references users (id),
    name     text not null,
    last_mix timestamptz,
    unique (id, user_id)
);

create index on mix_playlists(id);
