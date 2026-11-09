import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../models/education_level.dart';
import '../services/preferences_service.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _urlController = TextEditingController();
  final _keyController = TextEditingController();
  bool _showSaved = false;
  bool _obscureKey = true;
  bool _isTesting = false;

  @override
  void initState() {
    super.initState();
    _loadConfig();
  }

  Future<void> _loadConfig() async {
    final url = await PreferencesService.getSupabaseUrl();
    final key = await PreferencesService.getSupabaseAnonKey();
    if (mounted) {
      setState(() {
        _urlController.text = url;
        _keyController.text = key;
      });
    }
  }

  @override
  void dispose() {
    _urlController.dispose();
    _keyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AppProvider>(
      builder: (context, provider, _) {
        return Scaffold(
          backgroundColor: AppTheme.backgroundLightBlue,
          appBar: AppBar(
            backgroundColor: Colors.white,
            surfaceTintColor: Colors.transparent,
            title: Text(
              provider.tr('settings'),
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: AppTheme.textPrimary,
              ),
            ),
          ),
          body: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              // Language Section
              _buildSectionTitle(provider.tr('language'), Icons.language_rounded),
              const SizedBox(height: 12),
              _buildLanguageSelector(provider),
              const SizedBox(height: 28),

              // Education Level Section
              _buildSectionTitle(
                  provider.tr('educationLevel'), Icons.school_rounded),
              const SizedBox(height: 12),
              _buildEducationLevelSelector(provider),
              const SizedBox(height: 28),

              // Voice Support Info
              _buildSectionTitle(
                  provider.tr('voiceInput'), Icons.mic_rounded),
              const SizedBox(height: 12),
              _buildVoiceSupportInfo(provider),
              const SizedBox(height: 28),

              // Backend Configuration
              _buildSectionTitle(
                  provider.tr('backendConfig'), Icons.cloud_rounded),
              const SizedBox(height: 12),
              _buildBackendConfig(provider),
              const SizedBox(height: 32),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSectionTitle(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 22, color: AppTheme.primaryBlue),
        const SizedBox(width: 10),
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: AppTheme.textPrimary,
          ),
        ),
      ],
    );
  }

  Widget _buildLanguageSelector(AppProvider provider) {
    return Card(
      child: Column(
        children: [
          _buildLanguageTile(
            provider: provider,
            code: 'en',
            name: 'English',
            nativeName: 'English',
            flag: '🇬🇧',
          ),
          const Divider(height: 1),
          _buildLanguageTile(
            provider: provider,
            code: 'ur',
            name: 'Urdu',
            nativeName: 'اردو',
            flag: '🇵🇰',
          ),
          const Divider(height: 1),
          _buildLanguageTile(
            provider: provider,
            code: 'ps',
            name: 'Pashto',
            nativeName: 'پښتو',
            flag: '🇦🇫',
          ),
        ],
      ),
    );
  }

  Widget _buildLanguageTile({
    required AppProvider provider,
    required String code,
    required String name,
    required String nativeName,
    required String flag,
  }) {
    final isSelected = provider.languageCode == code;
    return ListTile(
      leading: Text(flag, style: const TextStyle(fontSize: 24)),
      title: Text(
        nativeName,
        style: TextStyle(
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
          color: AppTheme.textPrimary,
        ),
      ),
      subtitle: name != nativeName
          ? Text(name, style: const TextStyle(fontSize: 13))
          : null,
      trailing: isSelected
          ? const Icon(Icons.check_circle_rounded,
              color: AppTheme.primaryBlue, size: 24)
          : null,
      onTap: () => provider.setLanguage(code),
      tileColor: isSelected ? AppTheme.primaryBlue.withOpacity(0.04) : null,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    );
  }

  Widget _buildEducationLevelSelector(AppProvider provider) {
    return Card(
      child: Column(
        children: EducationLevelData.levels.asMap().entries.map((entry) {
          final level = entry.value;
          final isSelected = provider.educationLevelId == level.id;
          final isLast =
              entry.key == EducationLevelData.levels.length - 1;

          return Column(
            children: [
              ListTile(
                leading: Radio<String>(
                  value: level.id,
                  groupValue: provider.educationLevelId,
                  onChanged: (value) {
                    if (value != null) provider.setEducationLevel(value);
                  },
                ),
                title: Text(
                  level.getName(provider.languageCode),
                  style: TextStyle(
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                    fontSize: 15,
                  ),
                ),
                onTap: () => provider.setEducationLevel(level.id),
                tileColor:
                    isSelected ? AppTheme.primaryBlue.withOpacity(0.04) : null,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              if (!isLast) const Divider(height: 1),
            ],
          );
        }).toList(),
      ),
    );
  }

  Widget _buildVoiceSupportInfo(AppProvider provider) {
    final ttsSupport = provider.ttsLanguageSupport;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildVoiceRow('English', 'en', ttsSupport),
            const SizedBox(height: 10),
            _buildVoiceRow('اردو (Urdu)', 'ur', ttsSupport),
            const SizedBox(height: 10),
            _buildVoiceRow('پښتو (Pashto)', 'ps', ttsSupport),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.backgroundLightBlue,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.info_outline_rounded,
                      size: 18, color: AppTheme.textSecondary),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      provider.languageCode == 'ur'
                          ? 'آواز کی دستیابی آپ کے آلے اور نصب شدہ زبان پیک پر منحصر ہے۔'
                          : provider.languageCode == 'ps'
                              ? 'د غږ شتون ستاسو وسیله او نصب شوي ژبې پیکونو پورې اړه لري.'
                              : 'Voice availability depends on your device and installed language packs.',
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppTheme.textSecondary,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVoiceRow(
      String name, String code, Map<String, bool> ttsSupport) {
    final supported = ttsSupport[code] ?? false;
    return Row(
      children: [
        Icon(
          supported ? Icons.check_circle_outline : Icons.cancel_outlined,
          size: 20,
          color: supported ? AppTheme.successColor : AppTheme.textHint,
        ),
        const SizedBox(width: 10),
        Text(
          name,
          style: const TextStyle(fontSize: 15),
        ),
        const Spacer(),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: supported
                ? AppTheme.successColor.withOpacity(0.1)
                : AppTheme.textHint.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            supported ? 'Available' : 'Not Available',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: supported ? AppTheme.successColor : AppTheme.textHint,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBackendConfig(AppProvider provider) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Status indicator
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: provider.isBackendConfigured
                    ? AppTheme.successColor.withOpacity(0.08)
                    : AppTheme.warningColor.withOpacity(0.08),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  Icon(
                    provider.isBackendConfigured
                        ? Icons.cloud_done_rounded
                        : Icons.cloud_off_rounded,
                    size: 20,
                    color: provider.isBackendConfigured
                        ? AppTheme.primaryBlue
                        : AppTheme.warningColor,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          provider.isBackendConfigured
                              ? 'Credentials Configured'
                              : provider.tr('demoMode'),
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: provider.isBackendConfigured
                                ? AppTheme.primaryBlue
                                : AppTheme.warningColor,
                          ),
                        ),
                        if (provider.isBackendConfigured)
                          const Text(
                            "Tap 'Test Backend Connection' below to verify 'gemini-chat' function",
                            style: TextStyle(
                              fontSize: 11,
                              color: AppTheme.textSecondary,
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Supabase URL
            Text(
              provider.tr('supabaseUrl'),
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _urlController,
              decoration: InputDecoration(
                hintText: 'https://your-project.supabase.co',
                prefixIcon:
                    const Icon(Icons.link_rounded, size: 20),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              keyboardType: TextInputType.url,
              style: const TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 16),

            // Supabase Anon Key
            Text(
              provider.tr('supabaseAnonKey'),
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _keyController,
              decoration: InputDecoration(
                hintText: 'eyJhbGciOiJIUzI...',
                prefixIcon: const Icon(Icons.key_rounded, size: 20),
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscureKey
                        ? Icons.visibility_off_rounded
                        : Icons.visibility_rounded,
                    size: 20,
                  ),
                  onPressed: () =>
                      setState(() => _obscureKey = !_obscureKey),
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              obscureText: _obscureKey,
              style: const TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 16),

            // Save button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () async {
                  final url = _urlController.text.trim();
                  final key = _keyController.text.trim();

                  if (url.isEmpty || key.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: const Text(
                            'Please enter both Supabase URL and Anon Key'),
                        backgroundColor: AppTheme.errorColor,
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    );
                    return;
                  }

                  await provider.configureBackend(url, key);
                  setState(() => _showSaved = true);

                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(provider.tr('saved')),
                        backgroundColor: AppTheme.successColor,
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    );
                  }

                  Future.delayed(const Duration(seconds: 2), () {
                    if (mounted) setState(() => _showSaved = false);
                  });
                },
                icon: Icon(_showSaved ? Icons.check : Icons.save_rounded),
                label: Text(
                  _showSaved ? provider.tr('saved') : provider.tr('save'),
                ),
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _isTesting
                    ? null
                    : () async {
                        setState(() => _isTesting = true);
                        final result = await ApiService.testConnection();
                        if (mounted) {
                          setState(() => _isTesting = false);
                          showDialog(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: Row(
                                children: [
                                  Icon(
                                    result['success'] == true
                                        ? Icons.check_circle_rounded
                                        : Icons.error_outline_rounded,
                                    color: result['success'] == true
                                        ? AppTheme.successColor
                                        : AppTheme.errorColor,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    result['success'] == true
                                        ? 'Connection Success'
                                        : 'Connection Check',
                                    style: const TextStyle(fontSize: 18),
                                  ),
                                ],
                              ),
                              content: Text(result['message'] as String),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(context),
                                  child: const Text('OK'),
                                ),
                              ],
                            ),
                          );
                        }
                      },
                icon: _isTesting
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.wifi_tethering_rounded),
                label: Text(
                    _isTesting ? 'Testing...' : 'Test Backend Connection'),
              ),
            ),
            const SizedBox(height: 16),

            // Help text
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.backgroundLightBlue,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.help_outline_rounded,
                          size: 18, color: AppTheme.primaryBlue),
                      SizedBox(width: 8),
                      Text(
                        'How to configure:',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.primaryBlue,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 8),
                  Text(
                    '1. Create a Supabase project at supabase.com\n'
                    '2. Deploy the Edge Function (see SETUP.md)\n'
                    '3. Copy your Project URL and anon key\n'
                    '4. Paste them above and save',
                    style: TextStyle(
                      fontSize: 13,
                      color: AppTheme.textSecondary,
                      height: 1.6,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
