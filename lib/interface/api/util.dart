import 'package:sane_uuid/uuid.dart';
import 'package:shelf/shelf.dart';

export 'package:sane_uuid/uuid.dart';

export 'exceptions.dart';

typedef Json = Map<String, dynamic>;
typedef FromJson<T> = T Function(Json);
typedef ToJson<T> = Json Function(T);

class Principal {
  final Uuid userId;

  Principal({
    required this.userId,
  });
}

extension AuthenticationData on Request {
  Principal get principal => context['principal'] as Principal;
}
