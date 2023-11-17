import 'package:injectable/injectable.dart';
import 'package:meta/meta.dart';
import 'package:mixology_backend/application/ports/token_factory.dart';
import 'package:mixology_backend/application/repos/unit_of_work.dart';

@injectable
class AuthRefresh {
  final TokenFactory tokenFactory;
  final UnitOfWorkProvider uowProvider;

  AuthRefresh(
    this.tokenFactory,
    this.uowProvider,
  );

  Future<RefreshedTokenPair?> call({
    required String refreshToken,
  }) async {
    return await uowProvider.withUnitOfWork((uow) async {
      final tokenData = await tokenFactory.checkRefreshTokenValidity(
        refreshToken: refreshToken,
      );
      if (tokenData == null) {
        return null;
      }

      final userId = tokenData.userId;
      var spotifyId = tokenData.spotifyId;
      if (spotifyId == null) {
        final user = await uow.userRepo.findById(userId);
        if (user == null) {
          return null;
        }
        spotifyId = user.spotifyId;
      }

      final inThirtyDays = DateTime.now().toUtc().add(const Duration(days: 30));
      final String? newRefreshToken;
      if (tokenData.expiration.isBefore(inThirtyDays)) {
        newRefreshToken = await tokenFactory.generateRefreshToken(
          userId: userId,
          spotifyId: spotifyId,
        );
      } else {
        newRefreshToken = null;
      }

      return RefreshedTokenPair(
        accessToken: await tokenFactory.generateAccessToken(
          userId: userId,
          spotifyId: spotifyId,
        ),
        refreshToken: newRefreshToken,
      );
    });
  }
}

@immutable
class RefreshedTokenPair {
  final String accessToken;
  final String? refreshToken;

  RefreshedTokenPair({
    required this.accessToken,
    required this.refreshToken,
  });
}
