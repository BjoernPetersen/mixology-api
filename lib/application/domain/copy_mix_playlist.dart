import 'package:sane_uuid/uuid.dart';

class CopyMixPlaylist {
  /// null means liked/saved songs.
  final String? sourceId;
  final String targetId;
  final Uuid userId;
  DateTime? lastMix;

  CopyMixPlaylist({
    required this.sourceId,
    required this.targetId,
    required this.userId,
    required this.lastMix,
  });
}
