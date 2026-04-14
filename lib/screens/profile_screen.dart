import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../utils/helpers.dart';
import '../services/auth_service.dart';
import '../services/sync_service.dart';
import '../services/hive_service.dart';
import '../models/user_profile.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late UserProfile _user;
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _bloodController = TextEditingController();
  final _allergyController = TextEditingController();
  final _contactController = TextEditingController();

  bool _isSyncing = false;
  bool _isEditing = false;

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  void _loadUser() {
    _user = HiveService.getUser();
    _nameController.text = _user.name;
    _phoneController.text = _user.phone;
    _bloodController.text = _user.bloodGroup;
    _allergyController.text = _user.allergies;
    _contactController.text = _user.emergencyContact;
  }

  Future<void> _saveChanges() async {
    final updatedUser = _user.copyWith(
      name: _nameController.text.trim(),
      phone: _phoneController.text.trim(),
      bloodGroup: _bloodController.text.trim(),
      allergies: _allergyController.text.trim(),
      emergencyContact: _contactController.text.trim(),
    );
    await HiveService.saveUser(updatedUser);
    setState(() {
      _user = updatedUser;
      _isEditing = false;
    });
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile saved successfully! 💾'), backgroundColor: Color(0xFF60DAC4)),
      );
    }
  }

  Future<void> _openUrl(String url) async {
    final uri = Uri.parse(url);
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      debugPrint('Error launching URL: $e');
    }
  }

  Future<void> _handleSync() async {
    setState(() => _isSyncing = true);
    try {
      if (AuthService.currentUser == null) {
        await AuthService.signInWithGoogle();
      }
      await SyncService.syncLegacyLogs();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Migration successful! 🎉'), backgroundColor: Color(0xFF60DAC4)),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Sync Failed: $e'), backgroundColor: Colors.redAccent),
        );
      }
    } finally {
      if (mounted) setState(() => _isSyncing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF10141A),
      appBar: buildAppBar('My Safety Profile'),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 10, 20, 40),
        child: Column(
          children: [
            _buildUserHeader(),
            const SizedBox(height: 24),
            _buildSection(
              title: 'Personal Safety Details',
              icon: Icons.health_and_safety_rounded,
              child: _buildProfileForm(),
            ),
            const SizedBox(height: 20),
            _buildSection(
              title: 'Cloud Data & Account',
              icon: Icons.cloud_sync_rounded,
              child: _buildCloudSyncCard(),
            ),
            const SizedBox(height: 24),
            _buildDeveloperFooter(),
          ],
        ),
      ),
    );
  }

  Widget _buildUserHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1C2026), Color(0xFF262A31)],
          begin: Alignment.topLeft, end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.07)),
      ),
      child: Column(
        children: [
          GestureDetector(
            onTap: () => setState(() => _isEditing = !_isEditing),
            child: Container(
              width: 100, height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF31353C),
                border: Border.all(color: const Color(0xFFFF5352), width: 3),
                boxShadow: [BoxShadow(color: const Color(0xFFFF5352).withOpacity(0.2), blurRadius: 15)],
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  const Icon(Icons.person_outline_rounded, size: 50, color: Color(0xFFFFB3AE)),
                  Positioned(
                    bottom: 0, right: 0,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: Color(0xFFFF5352),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(_isEditing ? Icons.close_rounded : Icons.edit_rounded, size: 14, color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          ValueListenableBuilder<String>(
            valueListenable: HiveService.userNameNotifier,
            builder: (context, name, _) {
              return Text(
                name.isNotEmpty ? name : 'Unknown Guardian',
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: 0.5),
              );
            },
          ),
          const SizedBox(height: 4),
          Text(_user.phone.isEmpty ? 'Tap Edit to add Phone' : _user.phone,
              style: const TextStyle(color: Color(0xFFA0CAFF), fontSize: 14)),
        ],
      ),
    );
  }

  Widget _buildProfileForm() {
    return Column(
      children: [
        _buildTextField('Full Name', _nameController, Icons.person, !_isEditing),
        _buildTextField('Emergency Phone', _phoneController, Icons.phone, !_isEditing),
        Row(
          children: [
            Expanded(child: _buildTextField('Blood Group', _bloodController, Icons.bloodtype, !_isEditing)),
            const SizedBox(width: 12),
            Expanded(child: _buildTextField('Primary Contact', _contactController, Icons.emergency_share, !_isEditing)),
          ],
        ),
        _buildTextField('Allergies / Medical Notes', _allergyController, Icons.medical_information, !_isEditing, maxLines: 2),
        if (_isEditing) ...[
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 54,
            child: ElevatedButton.icon(
              onPressed: _saveChanges,
              icon: const Icon(Icons.save_rounded),
              label: const Text('SAVE CHANGES', style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.2)),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildTextField(String label, TextEditingController controller, IconData icon, bool readOnly, {int maxLines = 1}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: controller,
        readOnly: readOnly,
        maxLines: maxLines,
        style: const TextStyle(color: Colors.white, fontSize: 14),
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, size: 18, color: const Color(0xFFFF5352)),
          filled: true,
          fillColor: readOnly ? Colors.white.withOpacity(0.02) : const Color(0xFF262A31),
        ),
      ),
    );
  }

  Widget _buildCloudSyncCard() {
    return StreamBuilder(
      stream: AuthService.authStateChanges,
      builder: (context, snapshot) {
        final user = snapshot.data;
        final bool isAuthenticated = user != null;

        return ValueListenableBuilder(
          valueListenable: HiveService.settings.listenable(),
          builder: (context, Box box, _) {
            final bool hasSynced = box.get('has_synced', defaultValue: false);

            // ── SIGNED OUT STATE ──
            if (!isAuthenticated) {
              return Column(
                children: [
                  _syncStatus(Icons.cloud_off_rounded, 'Not Signed In', 'Sign in with Google to sync your data.', Colors.white24),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () => AuthService.signInWithGoogle(),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1C2026),
                        side: const BorderSide(color: Colors.white12),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      icon: const Icon(Icons.g_mobiledata_rounded, size: 28),
                      label: const Text('SIGN IN WITH GOOGLE'),
                    ),
                  ),
                ],
              );
            }

            // ── SIGNED IN STATE ──
            return Column(
              children: [
                // Show signed-in user info
                Row(
                  children: [
                    const Icon(Icons.account_circle_rounded, color: Color(0xFF60DAC4), size: 28),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(user.displayName ?? user.email ?? 'Signed In',
                              style: const TextStyle(color: Color(0xFF60DAC4), fontWeight: FontWeight.bold, fontSize: 14)),
                          Text(user.email ?? 'Google Account',
                              style: const TextStyle(color: Colors.white38, fontSize: 11)),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Sync status
                if (hasSynced)
                  _syncStatus(Icons.check_circle_rounded, 'Data Migration Complete', 'All legacy messages are locally synced.', const Color(0xFF60DAC4))
                else ...[
                  _syncStatus(Icons.cloud_download_rounded, 'Ready to Sync', 'Import legacy data from Firestore.', const Color(0xFFA0CAFF)),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF60DAC4),
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      onPressed: _isSyncing ? null : _handleSync,
                      icon: _isSyncing
                          ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                          : const Icon(Icons.download_rounded),
                      label: Text(_isSyncing ? 'SYNCING...' : 'IMPORT OLD DATA'),
                    ),
                  ),
                ],

                const SizedBox(height: 12),
                const Divider(color: Colors.white10),
                const SizedBox(height: 4),

                // ── SIGN OUT BUTTON ── Always visible when signed in
                SizedBox(
                  width: double.infinity,
                  child: TextButton.icon(
                    onPressed: () async {
                      await AuthService.signOut();
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Signed out successfully'), backgroundColor: Colors.white24),
                        );
                      }
                    },
                    icon: const Icon(Icons.logout_rounded, size: 18, color: Color(0xFFFF5352)),
                    label: const Text('SIGN OUT', style: TextStyle(color: Color(0xFFFF5352), fontWeight: FontWeight.bold, fontSize: 13)),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _syncStatus(IconData icon, String title, String sub, Color color) {
    return Row(
      children: [
        Icon(icon, color: color, size: 28),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 14)),
              Text(sub, style: const TextStyle(color: Colors.white38, fontSize: 11)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSection({required String title, required IconData icon, required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1C2026),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: const Color(0xFFFF5352)),
              const SizedBox(width: 8),
              Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.white70)),
            ],
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }

  Widget _buildDeveloperFooter() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFFFF5352).withOpacity(0.05),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFFF5352).withOpacity(0.1)),
      ),
      child: Column(
        children: [
          const Text('ABOUT THE DEVELOPER',
              style: TextStyle(fontWeight: FontWeight.w900, color: Color(0xFFFF5352), fontSize: 12, letterSpacing: 2)),
          const SizedBox(height: 16),
          const CircleAvatar(
            radius: 30,
            backgroundColor: Color(0xFF1C2026),
            child: Icon(Icons.code_rounded, color: Color(0xFFFFB3AE)),
          ),
          const SizedBox(height: 12),
          const Text('Himendra',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.white)),
          const SizedBox(height: 4),
          const Text('Mobile App Developer & Safety Engineer',
              style: TextStyle(color: Colors.white38, fontSize: 12)),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 16, horizontal: 20),
            child: Text(
              'Focused on building tech that matters. Guard-X is a passion project designed to bridge the gap between emergency services and smart tech.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white54, fontSize: 13, height: 1.5),
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _socialBtn(Icons.code_rounded, 'GitHub', () => _openUrl('https://github.com/Himendra-stack')),
              const SizedBox(width: 12),
              _socialBtn(Icons.work_rounded, 'LinkedIn', () => _openUrl('https://linkedin.com/in/himendra-y-777h/')),
            ],
          ),
          const SizedBox(height: 16),
          const Text('v1.0.0 • Built with Flutter & Hive',
              style: TextStyle(color: Colors.white10, fontSize: 10)),
        ],
      ),
    );
  }

  Widget _socialBtn(IconData icon, String label, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: const Color(0xFF10141A),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white10),
        ),
        child: Row(
          children: [
            Icon(icon, size: 16, color: const Color(0xFFA0CAFF)),
            const SizedBox(width: 8),
            Text(label, style: const TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}