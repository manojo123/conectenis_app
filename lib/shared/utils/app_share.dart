import 'package:conectenis_app/core/config/env.dart';
import 'package:share_plus/share_plus.dart';

abstract final class AppShare {
  static Future<void> inviteFriends() async {
    final url = Env.appShareUrl;
    await Share.share(
      'Estou usando o ConecTenis para encontrar parceiros de tênis na minha região. Baixe também!\n$url',
      subject: 'ConecTenis - Sua Conexão no Tênis',
    );
  }
}
