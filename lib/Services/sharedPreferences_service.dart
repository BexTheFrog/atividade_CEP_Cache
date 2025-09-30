import 'package:shared_preferences/shared_preferences.dart';

class SharedPreferencesService {
  static final Future<SharedPreferences> _preferences =
      SharedPreferences.getInstance();

  static Future<void> setStringLocalStorage(String dados, String chave) async {
    SharedPreferences preferences = await _preferences;
    preferences.setString(chave, dados);
  }

  static Future<String?> getStringLocalStorage(String chave) async {
    SharedPreferences preferences = await _preferences;
    return preferences.getString(chave);
  }
}
