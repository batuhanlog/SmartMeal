import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'services/error_handler.dart';
import 'services/google_sign_in_service.dart';
import 'auth_page.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  // --- YENİ RENK PALETİ ---
  final Color primaryColor = Colors.green.shade800;
  final Color backgroundColor = Colors.grey.shade100;
  final Color destructiveColor = Colors.red.shade700;

  bool _pushNotifications = true;
  bool _mealReminders = true;
  bool _dataCollection = true;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    // ... (Bu fonksiyonun içeriği aynı kalıyor) ...
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
        if (mounted && doc.exists) {
          final data = doc.data()!;
          setState(() {
            _pushNotifications = data['settings']?['pushNotifications'] ?? true;
            _mealReminders = data['settings']?['mealReminders'] ?? true;
            _dataCollection = data['settings']?['dataCollection'] ?? true;
            _isLoading = false;
          });
        } else if (mounted) {
          setState(() => _isLoading = false);
        }
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _saveSettings() async {
    // ... (Bu fonksiyonun içeriği aynı kalıyor) ...
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
          'settings': {
            'pushNotifications': _pushNotifications,
            'mealReminders': _mealReminders,
            'dataCollection': _dataCollection,
          },
          'updatedAt': FieldValue.serverTimestamp(),
        });
        if (mounted) ErrorHandler.showSuccess(context, 'Ayarlar kaydedildi');
      }
    } catch (e) {
      if (mounted) ErrorHandler.showError(context, 'Ayarlar kaydedilirken hata oluştu');
    }
  }

  Future<void> _clearHistory() async {
    // ... (Bu fonksiyonun içeriği aynı kalıyor) ...
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Geçmişi Temizle'),
        content: const Text('Tüm yemek geçmişiniz silinecek. Emin misiniz?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('İptal')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('Sil', style: TextStyle(color: destructiveColor)),
          ),
        ],
      ),
    );
    if (confirm == true) {
      // ... (silme mantığı aynı)
    }
  }

  Future<void> _deleteAccount() async {
    // ... (Bu fonksiyonun içeriği aynı kalıyor) ...
     final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hesabı Sil'),
        content: const Text('Hesabınız kalıcı olarak silinecek. Bu işlem geri alınamaz. Emin misiniz?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('İptal')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('Sil', style: TextStyle(color: destructiveColor)),
          ),
        ],
      ),
    );
    if (confirm == true) {
      // ... (hesap silme mantığı aynı)
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        body: Center(child: CircularProgressIndicator(color: primaryColor)),
      );
    }

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: const Text('Ayarlar'),
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildSectionCard(
            icon: Icons.notifications_active,
            title: 'Bildirim Ayarları',
            children: [
              SwitchListTile(
                title: const Text('Anlık Bildirimler'),
                subtitle: const Text('Yeni özellikler ve güncellemeler hakkında'),
                value: _pushNotifications,
                onChanged: (value) {
                  setState(() => _pushNotifications = value);
                  _saveSettings();
                },
                activeColor: primaryColor,
              ),
              SwitchListTile(
                title: const Text('Yemek Hatırlatıcıları'),
                subtitle: const Text('Öğün zamanlarında hatırlatma'),
                value: _mealReminders,
                onChanged: (value) {
                  setState(() => _mealReminders = value);
                  _saveSettings();
                },
                activeColor: primaryColor,
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildSectionCard(
            icon: Icons.privacy_tip,
            title: 'Gizlilik',
            children: [
              SwitchListTile(
                title: const Text('Veri Toplama ve Analiz'),
                subtitle: const Text('Uygulamayı iyileştirmemize yardımcı olun'),
                value: _dataCollection,
                onChanged: (value) {
                  setState(() => _dataCollection = value);
                  _saveSettings();
                },
                activeColor: primaryColor,
              ),
              ListTile(
                leading: const Icon(Icons.description_outlined),
                title: const Text('Gizlilik Politikası'),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () => ErrorHandler.showInfo(context, 'Gizlilik politikası yakında eklenecek'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildSectionCard(
            icon: Icons.storage,
            title: 'Veri Yönetimi',
            children: [
              ListTile(
                leading: const Icon(Icons.delete_sweep_outlined),
                title: const Text('Geçmişi Temizle'),
                subtitle: const Text('Tüm yemek geçmişinizi silin'),
                onTap: _clearHistory,
              ),
              ListTile(
                leading: const Icon(Icons.download_for_offline_outlined),
                title: const Text('Verilerimi İndir'),
                subtitle: const Text('Tüm verilerinizi bir dosya olarak indirin'),
                onTap: () => ErrorHandler.showInfo(context, 'Veri indirme özelliği yakında eklenecek'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildSectionCard(
            icon: Icons.account_circle,
            title: 'Hesap',
            children: [
              ListTile(
                leading: const Icon(Icons.logout),
                title: const Text('Çıkış Yap'),
                onTap: () async {
                  await GoogleSignInService.signOut();
                  if (mounted) {
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(builder: (context) => const AuthPage()),
                      (route) => false,
                    );
                  }
                },
              ),
              ListTile(
                leading: Icon(Icons.delete_forever, color: destructiveColor),
                title: Text('Hesabı Sil', style: TextStyle(color: destructiveColor)),
                onTap: _deleteAccount,
              ),
            ],
          ),
        ],
      ),
    );
  }

  // --- YENİLENMİŞ KART TASARIMI ---
  Widget _buildSectionCard({
    required IconData icon,
    required String title,
    required List<Widget> children,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Row(
              children: [
                Icon(icon, color: primaryColor),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, indent: 16, endIndent: 16),
          ...children.map((child) {
            if (child is ListTile || child is SwitchListTile) {
              return child;
            }
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: child,
            );
          }),
        ],
      ),
    );
  }
}