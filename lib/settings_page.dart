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
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final doc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();
        
        if (doc.exists) {
          final data = doc.data()!;
          setState(() {
            _pushNotifications = data['settings']?['pushNotifications'] ?? true;
            _mealReminders = data['settings']?['mealReminders'] ?? true;
            _dataCollection = data['settings']?['dataCollection'] ?? true;
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _saveSettings() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .update({
          'settings': {
            'pushNotifications': _pushNotifications,
            'mealReminders': _mealReminders,
            'dataCollection': _dataCollection,
          },
          'updatedAt': FieldValue.serverTimestamp(),
        });

        if (mounted) {
          ErrorHandler.showSuccess(context, 'Ayarlar kaydedildi');
        }
      }
    } catch (e) {
      if (mounted) {
        ErrorHandler.showError(context, 'Ayarlar kaydedilirken hata oluştu');
      }
    }
  }

  Future<void> _clearHistory() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Geçmişi Temizle'),
        content: const Text('Tüm yemek geçmişiniz silinecek. Emin misiniz?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('İptal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Sil', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        final user = FirebaseAuth.instance.currentUser;
        if (user != null) {
          final batch = FirebaseFirestore.instance.batch();
          
          // Yemek geçmişini sil
          final historyDocs = await FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .collection('meal_history')
              .get();
          
          for (final doc in historyDocs.docs) {
            batch.delete(doc.reference);
          }
          
          await batch.commit();
          
          if (mounted) {
            ErrorHandler.showSuccess(context, 'Geçmiş temizlendi');
          }
        }
      } catch (e) {
        if (mounted) {
          ErrorHandler.showError(context, 'Geçmiş temizlenirken hata oluştu');
        }
      }
    }
  }

  Future<void> _deleteAccount() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hesabı Sil'),
        content: const Text(
          'Hesabınız kalıcı olarak silinecek ve tüm verileriniz kaybolacak. Bu işlem geri alınamaz. Emin misiniz?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('İptal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Sil', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        final user = FirebaseAuth.instance.currentUser;
        if (user != null) {
          // Kullanıcı verilerini sil
          await FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .delete();
          
          // Hesabı sil
          await user.delete();
          
          if (mounted) {
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (context) => const AuthPage()),
              (route) => false,
            );
          }
        }
      } catch (e) {
        if (mounted) {
          ErrorHandler.showError(context, 'Hesap silinirken hata oluştu');
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('⚙️ Ayarlar'),
        backgroundColor: Colors.grey.shade300,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Bildirim Ayarları
          _buildSectionCard(
            title: '🔔 Bildirim Ayarları',
            children: [
              SwitchListTile(
                title: const Text('Push Bildirimleri'),
                subtitle: const Text('Yeni özellikler ve güncellemeler'),
                value: _pushNotifications,
                onChanged: (value) {
                  setState(() {
                    _pushNotifications = value;
                  });
                  _saveSettings();
                },
              ),
              SwitchListTile(
                title: const Text('Yemek Hatırlatıcıları'),
                subtitle: const Text('Öğün zamanlarında hatırlatıcı'),
                value: _mealReminders,
                onChanged: (value) {
                  setState(() {
                    _mealReminders = value;
                  });
                  _saveSettings();
                },
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Gizlilik Ayarları
          _buildSectionCard(
            title: '🔒 Gizlilik',
            children: [
              SwitchListTile(
                title: const Text('Veri Toplama'),
                subtitle: const Text('Uygulama iyileştirme için veri kullanımı'),
                value: _dataCollection,
                onChanged: (value) {
                  setState(() {
                    _dataCollection = value;
                  });
                  _saveSettings();
                },
              ),
              ListTile(
                leading: const Icon(Icons.privacy_tip),
                title: const Text('Gizlilik Politikası'),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () {
                  // Gizlilik politikası sayfasına yönlendir
                  ErrorHandler.showInfo(context, 'Gizlilik politikası yakında eklenecek');
                },
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Veri Yönetimi
          _buildSectionCard(
            title: '📊 Veri Yönetimi',
            children: [
              ListTile(
                leading: const Icon(Icons.clear_all, color: Colors.orange),
                title: const Text('Geçmişi Temizle'),
                subtitle: const Text('Tüm yemek geçmişinizi silin'),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: _clearHistory,
              ),
              ListTile(
                leading: const Icon(Icons.download, color: Colors.blue),
                title: const Text('Verilerimi İndir'),
                subtitle: const Text('Tüm verilerinizi indirin'),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () {
                  ErrorHandler.showInfo(context, 'Veri indirme özelliği yakında eklenecek');
                },
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Hesap İşlemleri
          _buildSectionCard(
            title: '👤 Hesap',
            children: [
              ListTile(
                leading: const Icon(Icons.logout, color: Colors.blue),
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
                leading: const Icon(Icons.delete_forever, color: Colors.red),
                title: const Text('Hesabı Sil', style: TextStyle(color: Colors.red)),
                subtitle: const Text('Bu işlem geri alınamaz'),
                onTap: _deleteAccount,
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Uygulama Bilgileri
          _buildSectionCard(
            title: 'ℹ️ Uygulama',
            children: [
              ListTile(
                leading: const Icon(Icons.info),
                title: const Text('Sürüm'),
                subtitle: const Text('1.0.0'),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              ),
              ListTile(
                leading: const Icon(Icons.star),
                title: const Text('Uygulamayı Değerlendir'),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () {
                  ErrorHandler.showInfo(context, 'Değerlendirme sayfası yakında eklenecek');
                },
              ),
              ListTile(
                leading: const Icon(Icons.help),
                title: const Text('Yardım & Destek'),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () {
                  ErrorHandler.showInfo(context, 'Yardım sayfası yakında eklenecek');
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSectionCard({
    required String title,
    required List<Widget> children,
  }) {
    return Card(
      elevation: 2,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          ...children,
        ],
      ),
    );
  }
}
