import 'dart:convert';
import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../providers/auth_provider.dart';
import 'profile_screen.dart';
import 'login_screen.dart';

class SettingsScreen extends StatefulWidget {
  final AuthProvider authProvider;
  final bool isTamil;
  final Function(bool) onLanguageChanged;

  const SettingsScreen({
    super.key,
    required this.authProvider,
    required this.isTamil,
    required this.onLanguageChanged,
  });

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _isLoading = true;
  Map<String, dynamic>? _settings;

  String _t(String en, String ta) => widget.isTamil ? ta : en;

  @override
  void initState() {
    super.initState();
    _fetchSettings();
  }

  Future<void> _fetchSettings() async {
    final res = await ApiService.getSettings();
    if (mounted) {
      setState(() {
        _isLoading = false;
        if (res['success'] == true) {
          _settings = res['data'];
        }
      });
    }
  }

  Future<void> _updateNotification(String key, bool value) async {
    if (_settings == null || _settings!['notificationPreferences'] == null) return;
    
    // Optimistic UI update
    setState(() {
      _settings!['notificationPreferences'][key] = value;
    });

    final res = await ApiService.updateSettings({
      'notificationPreferences': _settings!['notificationPreferences']
    });

    if (res['success'] != true && mounted) {
      // Revert on failure
      setState(() {
        _settings!['notificationPreferences'][key] = !value;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_t('Failed to update settings', 'அமைப்புகளைப் புதுப்பிக்க முடியவில்லை'))),
      );
    }
  }

  Future<void> _changeLanguage(bool isTamil) async {
    widget.onLanguageChanged(isTamil);
    await ApiService.updateSettings({'languagePreference': isTamil ? 'ta' : 'en'});
  }

  void _showChangePasswordDialog() {
    final curPassController = TextEditingController();
    final newPassController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(_t('Change Password', 'கடவுச்சொல்லை மாற்றவும்')),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: curPassController,
                obscureText: true,
                decoration: InputDecoration(labelText: _t('Current Password', 'தற்போதைய கடவுச்சொல்')),
                validator: (v) => v!.isEmpty ? _t('Required', 'தேவை') : null,
              ),
              TextFormField(
                controller: newPassController,
                obscureText: true,
                decoration: InputDecoration(labelText: _t('New Password', 'புதிய கடவுச்சொல்')),
                validator: (v) => v!.length < 6 ? _t('Minimum 6 characters', 'குறைந்தபட்சம் 6 எழுத்துக்கள்') : null,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(_t('Cancel', 'ரத்து செய்')),
          ),
          ElevatedButton(
            onPressed: () async {
              if (formKey.currentState!.validate()) {
                Navigator.pop(ctx);
                final res = await ApiService.changePassword(curPassController.text, newPassController.text);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(res['message'] ?? (res['success'] ? 'Success' : 'Failed'))),
                  );
                }
              }
            },
            child: Text(_t('Save Changes', 'மாற்றங்களைச் சேமிக்கவும்')),
          )
        ],
      ),
    );
  }

  Future<void> _handleDataExport() async {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(_t('Preparing data export...', 'தரவு ஏற்றுமதி தயாராகிறது...'))),
    );
    final res = await ApiService.exportData();
    if (res['success'] == true) {
      if (mounted) {
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: Text(_t('Export Ready', 'ஏற்றுமதி தயார்')),
            content: SingleChildScrollView(
              child: Text(json.encode(res['data'])),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('OK'))
            ],
          ),
        );
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_t('Failed to export data', 'தரவை ஏற்றுமதி செய்ய முடியவில்லை'))),
        );
      }
    }
  }

  Future<void> _handleAccountDeletion() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(_t('Delete Account', 'கணக்கை நீக்கவும்'), style: const TextStyle(color: Colors.red)),
        content: Text(_t(
          'Deleting your account will permanently remove your profile, applications, saved scholarships, and data. This cannot be undone.',
          'உங்கள் கணக்கை நீக்குவது உங்கள் சுயவிவரம், விண்ணப்பங்கள் மற்றும் தரவை நிரந்தரமாக அகற்றும். இதை செயல்தவிர்க்க முடியாது.'
        )),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(_t('Cancel', 'ரத்து செய்'))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(_t('DELETE MY ACCOUNT', 'எனது கணக்கை நீக்கவும்')),
          )
        ],
      ),
    );

    if (confirm == true) {
      final res = await ApiService.deleteAccount();
      if (res['success'] == true) {
        await widget.authProvider.logout();
        if (mounted) {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (_) => LoginScreen(authProvider: widget.authProvider)),
            (route) => false,
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(res['message'] ?? 'Failed to delete account')),
          );
        }
      }
    }
  }

  void _handleLogout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(_t('Log Out', 'வெளியேறு')),
        content: Text(_t('Are you sure you want to log out?', 'நீங்கள் நிச்சயமாக வெளியேற விரும்புகிறீர்களா?')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(_t('Cancel', 'ரத்து செய்'))),
          ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: Text(_t('Log Out', 'வெளியேறு'))),
        ],
      ),
    );

    if (confirm == true) {
      await widget.authProvider.logout();
      if (mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => LoginScreen(authProvider: widget.authProvider)),
          (route) => false,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: Text(_t('Settings', 'அமைப்புகள்'))),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final notifs = _settings?['notificationPreferences'] ?? {};

    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: Text(_t('Settings', 'அமைப்புகள்')),
        backgroundColor: Colors.blue.shade900,
        foregroundColor: Colors.white,
      ),
      body: ListView(
        children: [
          // ACCOUNT
          _buildSectionHeader(_t('ACCOUNT', 'கணக்கு')),
          ListTile(
            leading: const Icon(Icons.person),
            title: Text(_t('Edit Profile', 'சுயவிவரத்தை திருத்து')),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => ProfileScreen(authProvider: widget.authProvider)),
            ),
          ),
          const Divider(),

          // LANGUAGE
          _buildSectionHeader(_t('LANGUAGE', 'மொழி')),
          SwitchListTile(
            secondary: const Icon(Icons.language),
            title: const Text('தமிழ்'),
            value: widget.isTamil,
            onChanged: _changeLanguage,
          ),
          const Divider(),

          // NOTIFICATIONS
          _buildSectionHeader(_t('NOTIFICATIONS', 'அறிவிப்புகள்')),
          _buildNotifSwitch('scholarshipUpdates', _t('Scholarship Updates', 'உதவித்தொகை புதுப்பிப்புகள்'), notifs),
          _buildNotifSwitch('newScholarshipAlerts', _t('New Scholarship Alerts', 'புதிய உதவித்தொகை விழிப்பூட்டல்கள்'), notifs),
          _buildNotifSwitch('deadlineReminders', _t('Deadline Reminders', 'காலக்கெடு நினைவூட்டல்கள்'), notifs),
          const Divider(),

          // SECURITY
          _buildSectionHeader(_t('SECURITY', 'பாதுகாப்பு')),
          ListTile(
            leading: const Icon(Icons.lock),
            title: Text(_t('Change Password', 'கடவுச்சொல்லை மாற்றவும்')),
            onTap: _showChangePasswordDialog,
          ),
          ListTile(
            leading: const Icon(Icons.logout),
            title: Text(_t('Log Out', 'வெளியேறு')),
            onTap: _handleLogout,
          ),
          const Divider(),

          // DATA & PRIVACY
          _buildSectionHeader(_t('DATA MANAGEMENT', 'தரவு மேலாண்மை')),
          ListTile(
            leading: const Icon(Icons.download),
            title: Text(_t('Download My Data', 'எனது தரவைப் பதிவிறக்கவும்')),
            onTap: _handleDataExport,
          ),
          const Divider(),

          // ABOUT
          _buildSectionHeader(_t('ABOUT', 'பற்றி')),
          ListTile(
            leading: const Icon(Icons.info_outline),
            title: Text(_t('Version', 'பதிப்பு')),
            trailing: const Text('1.0.0'),
          ),
          ListTile(
            leading: const Icon(Icons.policy),
            title: Text(_t('Privacy Policy', 'தனியுரிமைக் கொள்கை')),
            onTap: () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Privacy Policy URL here'))),
          ),
          const SizedBox(height: 16),

          // DANGER ZONE
          Container(
            color: Colors.red.shade50,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSectionHeader(_t('DANGER ZONE', 'ஆபத்து பகுதி'), color: Colors.red),
                ListTile(
                  leading: const Icon(Icons.delete_forever, color: Colors.red),
                  title: Text(_t('Delete Account', 'கணக்கை நீக்கவும்'), style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                  onTap: _handleAccountDeletion,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, {Color color = Colors.grey}) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
      child: Text(
        title,
        style: TextStyle(fontWeight: FontWeight.bold, color: color, fontSize: 12),
      ),
    );
  }

  Widget _buildNotifSwitch(String key, String title, Map<String, dynamic> notifs) {
    return SwitchListTile(
      title: Text(title),
      value: notifs[key] ?? true,
      onChanged: (val) => _updateNotification(key, val),
    );
  }
}
