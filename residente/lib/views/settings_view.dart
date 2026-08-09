import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../l10n/app_localizations.dart';
import '../theme/app_theme.dart';
import '../viewmodels/settings_viewmodel.dart';

class SettingsView extends StatefulWidget {
  const SettingsView({super.key});

  @override
  State<SettingsView> createState() => _SettingsViewState();
}

class _SettingsViewState extends State<SettingsView> {
  String _username = 'Iván';

  void _showEditUsernameDialog(BuildContext context) {
    final usernameController = TextEditingController(text: _username);
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color textColor = Theme.of(context).textTheme.bodyLarge?.color ?? Colors.white;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Theme.of(context).colorScheme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          AppLocalizations.t(context, 'edit_username_title'),
          style: TextStyle(color: textColor, fontWeight: FontWeight.bold),
        ),
        content: TextField(
          controller: usernameController,
          style: TextStyle(color: textColor),
          decoration: InputDecoration(
            hintText: AppLocalizations.t(context, 'edit_username_hint'),
            hintStyle: TextStyle(color: isDark ? AppTheme.textGrey : Colors.black45),
            enabledBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: isDark ? AppTheme.textGrey : Colors.black26),
            ),
            focusedBorder: const UnderlineInputBorder(
              borderSide: BorderSide(color: AppTheme.primaryOrange, width: 2),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              AppLocalizations.t(context, 'cancel'),
              style: TextStyle(color: isDark ? AppTheme.textGrey : Colors.black54),
            ),
          ),
          TextButton(
            onPressed: () {
              final newName = usernameController.text.trim();
              if (newName.isNotEmpty) {
                setState(() => _username = newName);
                context.read<SettingsViewModel>().updateUserName(newName);
              }
              Navigator.pop(context);
            },
            child: Text(
              AppLocalizations.t(context, 'save'),
              style: const TextStyle(color: AppTheme.primaryOrange, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8, top: 16),
      child: Text(
        title.toUpperCase(),
        style: const TextStyle(
          color: AppTheme.primaryOrange,
          fontWeight: FontWeight.bold,
          fontSize: 12,
          letterSpacing: 1.1,
        ),
      ),
    );
  }

  Widget _buildCardGroup(List<Widget> children, BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppTheme.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? Colors.white10 : Colors.black12,
        ),
      ),
      child: Column(children: children),
    );
  }

  @override
  Widget build(BuildContext context) {
    final settingsViewModel = context.watch<SettingsViewModel>();
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color textColor = Theme.of(context).textTheme.bodyLarge?.color ?? Colors.white;

    final String selectedLanguage = settingsViewModel.currentLocale.languageCode == 'en' ? 'English' : 'Español';

    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.t(context, 'settings_title')),
        centerTitle: true,
      ),
      body: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 500),
          child: ListView(
            padding: const EdgeInsets.all(16.0),
            children: [
              _buildSectionHeader(AppLocalizations.t(context, 'section_account')),
              _buildCardGroup([
                ListTile(
                  leading: const Icon(Icons.person_outline, color: AppTheme.primaryOrange),
                  title: Text(
                    AppLocalizations.t(context, 'display_name'),
                    style: TextStyle(color: textColor, fontWeight: FontWeight.w500),
                  ),
                  subtitle: Text(_username, style: const TextStyle(color: AppTheme.textGrey)),
                  trailing: const Icon(Icons.chevron_right, color: AppTheme.textGrey),
                  onTap: () => _showEditUsernameDialog(context),
                ),
              ], context),

              _buildSectionHeader(AppLocalizations.t(context, 'section_appearance')),
              _buildCardGroup([
                SwitchListTile(
                  secondary: const Icon(Icons.dark_mode_outlined, color: AppTheme.primaryOrange),
                  title: Text(
                    AppLocalizations.t(context, 'dark_mode'),
                    style: TextStyle(color: textColor, fontWeight: FontWeight.w500),
                  ),
                  subtitle: Text(
                    AppLocalizations.t(context, isDark ? 'dark_mode_on' : 'dark_mode_off'),
                    style: const TextStyle(color: AppTheme.textGrey),
                  ),
                  value: isDark,
                  activeThumbColor: AppTheme.primaryOrange,
                  onChanged: (value) {
                    context.read<SettingsViewModel>().toggleTheme(value);
                  },
                ),
                const Divider(height: 1, indent: 56),
                ListTile(
                  leading: const Icon(Icons.language, color: AppTheme.primaryOrange),
                  title: Text(
                    AppLocalizations.t(context, 'language'),
                    style: TextStyle(color: textColor, fontWeight: FontWeight.w500),
                  ),
                  subtitle: Text(selectedLanguage, style: const TextStyle(color: AppTheme.textGrey)),
                  trailing: DropdownButton<String>(
                    value: selectedLanguage,
                    underline: const SizedBox(),
                    dropdownColor: isDark ? AppTheme.surfaceDark : Colors.white,
                    style: TextStyle(color: textColor),
                    items: ['Español', 'English'].map((String value) {
                      return DropdownMenuItem<String>(
                        value: value,
                        child: Text(value),
                      );
                    }).toList(),
                    onChanged: (newValue) {
                      if (newValue != null) {
                        final String code = newValue == 'English' ? 'en' : 'es';
                        context.read<SettingsViewModel>().changeLanguage(code);
                      }
                    },
                  ),
                ),
              ], context),

              _buildSectionHeader(AppLocalizations.t(context, 'section_info')),
              _buildCardGroup([
                ListTile(
                  leading: const Icon(Icons.info_outline, color: AppTheme.primaryOrange),
                  title: Text(
                    AppLocalizations.t(context, 'app_version'),
                    style: TextStyle(color: textColor, fontWeight: FontWeight.w500),
                  ),
                  trailing: const Text('v1.0.0', style: TextStyle(color: AppTheme.textGrey, fontWeight: FontWeight.bold)),
                ),
                const Divider(height: 1, indent: 56),
                ListTile(
                  leading: const Icon(Icons.shield_outlined, color: AppTheme.primaryOrange),
                  title: Text(
                    AppLocalizations.t(context, 'privacy_policy'),
                    style: TextStyle(color: textColor, fontWeight: FontWeight.w500),
                  ),
                  trailing: const Icon(Icons.chevron_right, color: AppTheme.textGrey),
                  onTap: () {},
                ),
              ], context),
            ],
          ),
        ),
      ),
    );
  }
}
