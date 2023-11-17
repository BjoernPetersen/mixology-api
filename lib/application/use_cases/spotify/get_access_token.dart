import 'package:injectable/injectable.dart';
import 'package:mixology_backend/application/ports/spotify_api.dart';
import 'package:mixology_backend/application/repos/unit_of_work.dart';
import 'package:sane_uuid/uuid.dart';
import 'package:spotify_api/spotify_api.dart';

@injectable
class GetAccessToken {
  final UnitOfWorkProvider uowProvider;
  final SpotifyApiProvider apiProvider;

  GetAccessToken(
    this.uowProvider,
    this.apiProvider,
  );

  Future<TokenInfo> call(Uuid userId) async {
    return await uowProvider.withUnitOfWork((uow) async {
      final user = await uow.userRepo.findById(userId);
      if (user == null) {
        throw ArgumentError.value(userId, 'userId', 'user does not exist');
      }

      final api = apiProvider.provideForRefreshToken(
        user.spotifyRefreshToken,
      );

      final accessToken = await api.rawAccessToken;
      return TokenInfo(
        value: accessToken,
        expiration: DateTime.now().toUtc().add(Duration(minutes: 10)),
      );
    });
  }
}
