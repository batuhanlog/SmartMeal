import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'services/error_handler.dart';      // Bu dosyaların projenizde olduğundan emin olun
import 'services/google_sign_in_service.dart'; // Bu dosyaların projenizde olduğundan emin olun
import 'auth_page.dart';                      // Bu dosyaların projenizde olduğundan emin olun

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  // --- YENİLENMİŞ RENK PALETİ ---
  final Color primaryColor = Colors.green.shade800;
  final Color backgroundColor = const Color(0xFFF8F9FA); // Daha ferah bir arkaplan
  final Color cardColor = Colors.white;
  final Color destructiveColor = Colors.red.shade800;
  final Color primaryTextColor = const Color(0xFF212529);
  final Color secondaryTextColor = const Color(0xFF6C757D);

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
    // ... Bu fonksiyonun içeriği aynı kalıyor ...
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
          });
        }
      }
    } catch (e) {
      debugPrint("Ayarlar yüklenemedi: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _saveSettings() async {
    // ... Bu fonksiyonun içeriği aynı kalıyor ...
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
          'settings': {
            'pushNotifications': _pushNotifications,
            'mealReminders': _mealReminders,
            'dataCollection': _dataCollection,
          },
        }, SetOptions(merge: true)); // update yerine merge'lü set kullanmak daha güvenli
        if (mounted) ErrorHandler.showSuccess(context, 'Ayarlar kaydedildi');
      }
    } catch (e) {
      if (mounted) ErrorHandler.showError(context, 'Ayarlar kaydedilirken hata oluştu');
    }
  }

  Future<void> _clearHistory() async {
    // ... Bu fonksiyonun içeriği aynı kalıyor ...
    final confirm = await _showConfirmationDialog(
      title: 'Geçmişi Temizle',
      content: 'Tüm yemek geçmişiniz kalıcı olarak silinecek. Bu işlem geri alınamaz. Emin misiniz?',
    );
    if (confirm == true) {
      // Silme işlemini burada gerçekleştirin
      if (mounted) ErrorHandler.showSuccess(context, "Geçmiş başarıyla temizlendi.");
    }
  }

  Future<void> _deleteAccount() async {
    // ... Bu fonksiyonun içeriği aynı kalıyor ...
    final confirm = await _showConfirmationDialog(
      title: 'Hesabı Sil',
      content: 'Hesabınız ve tüm verileriniz kalıcı olarak silinecek. Bu işlem geri alınamaz. Emin misiniz?',
    );
    if (confirm == true) {
      // Hesap silme işlemini burada gerçekleştirin
    }
  }
  
  Future<void> _signOut() async {
    await GoogleSignInService.signOut();
    if (mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const AuthPage()),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: Text('Ayarlar', style: TextStyle(color: primaryTextColor)),
        backgroundColor: backgroundColor,
        elevation: 0,
        iconTheme: IconThemeData(color: primaryTextColor),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: primaryColor))
          : ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                _buildSectionHeader('BİLDİRİMLER'),
                _buildSettingsGroup(
                  children: [
                    _buildSwitchTile(
                      title: 'Anlık Bildirimler',
                      subtitle: 'Yeni özellikler ve güncellemeler',
                      value: _pushNotifications,
                      onChanged: (value) {
                        setState(() => _pushNotifications = value);
                        _saveSettings();
                      },
                    ),
                    _buildDivider(),
                    _buildSwitchTile(
                      title: 'Yemek Hatırlatıcıları',
                      subtitle: 'Öğün zamanlarında hatırlatma',
                      value: _mealReminders,
                      onChanged: (value) {
                        setState(() => _mealReminders = value);
                        _saveSettings();
                      },
                    ),
                  ],
                ),
                _buildSectionHeader('GİZLİLİK VE VERİ'),
                _buildSettingsGroup(
                  children: [
                    _buildSwitchTile(
                      title: 'Veri Toplama ve Analiz',
                      subtitle: 'Uygulamayı iyileştirmemize yardımcı olun',
                      value: _dataCollection,
                      onChanged: (value) {
                        setState(() => _dataCollection = value);
                        _saveSettings();
                      },
                    ),
                    _buildDivider(),
                    _buildSettingsTile(
                      icon: Icons.description_outlined,
                      iconBackgroundColor: Colors.grey.shade400,
                      title: 'Gizlilik Politikası',
                      onTap: () => ErrorHandler.showInfo(context, 'Gizlilik politikası yakında eklenecek'),
                    ),
                     _buildDivider(),
                    _buildSettingsTile(
                      icon: Icons.delete_sweep_outlined,
                      iconBackgroundColor: Colors.orange.shade600,
                      title: 'Geçmişi Temizle',
                      onTap: _clearHistory,
                    ),
                  ],
                ),
                _buildSectionHeader('HESAP'),
                _buildSettingsGroup(
                  children: [
                    _buildSettingsTile(
                      icon: Icons.logout,
                      iconBackgroundColor: Colors.blueGrey.shade400,
                      title: 'Çıkış Yap',
                      onTap: _signOut,
                    ),
                    _buildDivider(),
                    _buildSettingsTile(
                      icon: Icons.delete_forever,
                      iconBackgroundColor: destructiveColor,
                      title: 'Hesabı Sil',
                      titleColor: destructiveColor,
                      onTap: _deleteAccount,
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Center(
                  child: Text(
                    'Uygulama Versiyonu 1.0.0',
                    style: TextStyle(color: secondaryTextColor, fontSize: 12),
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
    );
  }

  // --- YENİ, DAHA ŞIK VE MODÜLER WIDGET'LAR ---

  /// Ayar grupları için (örn: BİLDİRİMLER) bir başlık oluşturur.
  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(top: 24.0, bottom: 8.0, left: 16.0),
      child: Text(
        title,
        style: TextStyle(
          color: secondaryTextColor,
          fontWeight: FontWeight.bold,
          fontSize: 13,
        ),
      ),
    );
  }

  /// Ayar satırlarını saran beyaz, yuvarlak köşeli kutuyu oluşturur.
  Widget _buildSettingsGroup({required List<Widget> children}) {
    return Card(
      elevation: 0,
      color: cardColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(children: children),
    );
  }

  /// Ayar satırları arasına konulacak standart ayırıcı.
  Widget _buildDivider() => const Divider(height: 1, indent: 68, endIndent: 16);

  /// Standart bir ayar satırı oluşturur (örn: Gizlilik Politikası).
  Widget _buildSettingsTile({
    required IconData icon,
    required Color iconBackgroundColor,
    required String title,
    Color? titleColor,
    VoidCallback? onTap,
  }) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: iconBackgroundColor,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: Colors.white, size: 20),
      ),
      title: Text(title, style: TextStyle(fontWeight: FontWeight.w500, color: titleColor ?? primaryTextColor)),
      trailing: onTap != null ? Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey.shade400) : null,
      onTap: onTap,
    );
  }

  /// Açma/kapama anahtarı olan bir ayar satırı oluşturur.
  Widget _buildSwitchTile({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return SwitchListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      title: Text(title, style: TextStyle(fontWeight: FontWeight.w500, color: primaryTextColor)),
      subtitle: Text(subtitle, style: TextStyle(color: secondaryTextColor, fontSize: 13)),
      value: value,
      onChanged: onChanged,
      activeColor: primaryColor,
    );
  }

  /// Onay gerektiren işlemler için standart bir diyalog kutusu gösterir.
  Future<bool?> _showConfirmationDialog({required String title, required String content}) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(title),
        content: Text(content),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('İptal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('Onayla', style: TextStyle(color: destructiveColor, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}