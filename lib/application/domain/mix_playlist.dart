import 'package:sane_uuid/uuid.dart';

class MixPlaylist {
  final String id;
  final Uuid userId;
  String name;
  DateTime? lastMix;

  MixPlaylist({
    required this.id,
    required this.userId,
    required this.name,
    required this.lastMix,
  });
}
