alter table mix_playlists
    drop constraint mix_playlists_user_id_fkey;

alter table mix_playlists
    add constraint mix_playlists_user_id_fkey foreign key (user_id) references users (id) on delete cascade;
