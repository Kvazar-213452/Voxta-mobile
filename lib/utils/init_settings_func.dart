import '../models/storage_settings.dart';
import '../app_colors.dart';
import '../models/interface/settings.dart';

void initSettingsTheme() async {
  Settings? settings1 = await SettingsDB.getSettings();

  if (settings1 != null) {
    if (settings1.darkMode) {
      AppColors.changeTheme("dark");
    } else {
      AppColors.changeTheme("white");
    }
  }
}
