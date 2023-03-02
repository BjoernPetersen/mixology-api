import 'package:injectable/injectable.dart';
import 'package:mixology_backend/application/use_cases/account/delete.dart';
import 'package:mixology_backend/application/use_cases/account/get.dart';
import 'package:mixology_backend/application/use_cases/auth_finish.dart';
import 'package:mixology_backend/application/use_cases/auth_refresh.dart';
import 'package:mixology_backend/application/use_cases/auth_start.dart';
import 'package:mixology_backend/application/use_cases/copy_mix_playlist/add.dart';
import 'package:mixology_backend/application/use_cases/copy_mix_playlist/delete.dart';
import 'package:mixology_backend/application/use_cases/copy_mix_playlist/list_for_user.dart';
import 'package:mixology_backend/application/use_cases/copy_mix_playlist/mix.dart';
import 'package:mixology_backend/application/use_cases/mix_playlist/add.dart';
import 'package:mixology_backend/application/use_cases/mix_playlist/delete.dart';
import 'package:mixology_backend/application/use_cases/mix_playlist/list_for_user.dart';
import 'package:mixology_backend/application/use_cases/mix_playlist/mix.dart';
import 'package:mixology_backend/application/use_cases/spotify/get_access_token.dart';

@injectable
class Application {
  final AuthStart startAuth;
  final AuthFinish finishAuth;
  final AuthRefresh refreshAuth;

  final DeleteAccount deleteAccount;
  final GetAccount getAccount;

  final GetAccessToken getAccessToken;

  final AddMixPlaylist addMixPlaylist;
  final DeleteMixPlaylist deleteMixPlaylist;
  final ListMixPlaylistsForUser listMixPlaylistsForUser;
  final MixPlaylists mixPlaylists;

  final AddCopyMixPlaylist addCopyMixPlaylist;
  final DeleteCopyMixPlaylist deleteCopyMixPlaylist;
  final ListCopyMixPlaylistsForUser listCopyMixPlaylistsForUser;
  final CopyMixPlaylists mixCopyPlaylists;

  Application(
    this.finishAuth,
    this.refreshAuth,
    this.startAuth,
    this.deleteAccount,
    this.getAccount,
    this.getAccessToken,
    this.addMixPlaylist,
    this.deleteMixPlaylist,
    this.listMixPlaylistsForUser,
    this.mixPlaylists,
    this.addCopyMixPlaylist,
    this.deleteCopyMixPlaylist,
    this.listCopyMixPlaylistsForUser,
    this.mixCopyPlaylists,
  );
}
