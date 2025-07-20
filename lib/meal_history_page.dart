import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'services/error_handler.dart';

class MealHistoryPage extends StatefulWidget {
  const MealHistoryPage({super.key});

  @override
  State<MealHistoryPage> createState() => _MealHistoryPageState();
}

class _MealHistoryPageState extends State<MealHistoryPage> with SingleTickerProviderStateMixin {
  // --- YENİ RENK PALETİ ---
  final Color primaryColor = Colors.green.shade800;
  final Color secondaryColor = Colors.green.shade600;
  final Color backgroundColor = Colors.grey.shade100;
  final Color favoriteColor = Colors.pink.shade400;

  late TabController _tabController;
  bool _isLoading = true;
  List<Map<String, dynamic>> _mealHistory = [];
  List<Map<String, dynamic>> _favoriteMeals = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    // ... Bu fonksiyonun içeriği aynı kalıyor ...
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final historyQuery = await FirebaseFirestore.instance.collection('users').doc(user.uid).collection('meal_history').orderBy('timestamp', descending: true).limit(50).get();
        final favoritesQuery = await FirebaseFirestore.instance.collection('users').doc(user.uid).collection('favorite_meals').orderBy('addedAt', descending: true).get();

        if(mounted) {
          setState(() {
            _mealHistory = historyQuery.docs.map((doc) => {'id': doc.id, ...doc.data()}).toList();
            _favoriteMeals = favoritesQuery.docs.map((doc) => {'id': doc.id, ...doc.data()}).toList();
            _isLoading = false;
          });
        }
      } else {
        if(mounted) setState(() => _isLoading = false);
      }
    } catch (e) {
      if(mounted) {
        setState(() => _isLoading = false);
        ErrorHandler.showError(context, 'Veriler yüklenirken hata oluştu');
      }
    }
  }

  Future<void> _addToFavorites(Map<String, dynamic> meal) async {
    // ... Bu fonksiyonun içeriği aynı kalıyor ...
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await FirebaseFirestore.instance.collection('users').doc(user.uid).collection('favorite_meals').add({
          ...meal,
          'addedAt': FieldValue.serverTimestamp(),
        });
        if (mounted) {
          ErrorHandler.showSuccess(context, 'Favorilere eklendi!');
          _loadData();
        }
      }
    } catch (e) {
      if (mounted) ErrorHandler.showError(context, 'Favorilere eklenirken hata oluştu');
    }
  }

  Future<void> _removeFromFavorites(String docId) async {
    // ... Bu fonksiyonun içeriği aynı kalıyor ...
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await FirebaseFirestore.instance.collection('users').doc(user.uid).collection('favorite_meals').doc(docId).delete();
        if (mounted) {
          ErrorHandler.showSuccess(context, 'Favorilerden kaldırıldı');
          _loadData();
        }
      }
    } catch (e) {
      if (mounted) ErrorHandler.showError(context, 'Favorilerden kaldırılırken hata oluştu');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: const Text('Yemek Geçmişim'),
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(icon: Icon(Icons.history), text: 'Geçmiş'),
            Tab(icon: Icon(Icons.favorite), text: 'Favoriler'),
          ],
        ),
      ),
      body: _isLoading 
        ? Center(child: CircularProgressIndicator(color: primaryColor))
        : TabBarView(
            controller: _tabController,
            children: [
              _buildHistoryTab(),
              _buildFavoritesTab(),
            ],
          ),
    );
  }

  Widget _buildHistoryTab() {
    if (_mealHistory.isEmpty) {
      return _buildEmptyState(
        icon: Icons.history_edu_outlined,
        title: 'Henüz Yemek Geçmişin Yok',
        subtitle: 'AI\'dan yemek önerisi aldığında burada görünecek.',
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: _mealHistory.length,
      itemBuilder: (context, index) => _buildMealCard(_mealHistory[index], isHistory: true),
    );
  }

  Widget _buildFavoritesTab() {
    if (_favoriteMeals.isEmpty) {
      return _buildEmptyState(
        icon: Icons.favorite_border,
        title: 'Henüz Favori Yemeğin Yok',
        subtitle: 'Beğendiğin yemekleri geçmiş listesinden favorilere ekleyebilirsin.',
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: _favoriteMeals.length,
      itemBuilder: (context, index) => _buildMealCard(_favoriteMeals[index], isHistory: false),
    );
  }

  Widget _buildEmptyState({required IconData icon, required String title, required String subtitle}) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 64, color: Colors.grey.shade300),
            const SizedBox(height: 16),
            Text(title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black87)),
            const SizedBox(height: 8),
            Text(subtitle, style: TextStyle(fontSize: 16, color: Colors.grey.shade600), textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }

  Widget _buildMealCard(Map<String, dynamic> meal, {required bool isHistory}) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(meal['emoji'] ?? '🍽️', style: const TextStyle(fontSize: 24)),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        meal['name'] ?? 'Bilinmeyen Yemek',
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      if (meal['timestamp'] != null || meal['addedAt'] != null)
                        Text(
                          _formatDate(meal['timestamp'] ?? meal['addedAt']),
                          style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                        ),
                    ],
                  ),
                ),
                if (isHistory)
                  IconButton(
                    onPressed: () => _addToFavorites(meal),
                    icon: Icon(Icons.favorite_border, color: secondaryColor),
                    tooltip: 'Favorilere Ekle',
                  )
                else
                  IconButton(
                    onPressed: () => _removeFromFavorites(meal['id']),
                    icon: Icon(Icons.favorite, color: favoriteColor),
                    tooltip: 'Favorilerden Kaldır',
                  ),
              ],
            ),
            if (meal['calories'] != null) ...[
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _buildNutritionChip('Kalori', '${meal['calories']} kcal', Colors.purple.shade700),
                  if (meal['protein'] != null)
                    _buildNutritionChip('Protein', '${meal['protein']}g', Colors.blue.shade700),
                  if (meal['prep_time'] != null)
                    _buildNutritionChip('Süre', '${meal['prep_time']} dk', Colors.teal.shade700),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildNutritionChip(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        '$label: $value',
        style: TextStyle(fontSize: 12, color: color, fontWeight: FontWeight.w600),
      ),
    );
  }

  String _formatDate(dynamic timestamp) {
    if (timestamp == null) return '';
    final date = (timestamp as Timestamp).toDate();
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) return 'Bugün, ${TimeOfDay.fromDateTime(date).format(context)}';
    if (difference.inDays == 1) return 'Dün';
    if (difference.inDays < 7) return '${difference.inDays} gün önce';
    return '${date.day}/${date.month}/${date.year}';
  }
}

class MealHistoryService {
  static Future<void> saveMealToHistory(Map<String, dynamic> meal) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await FirebaseFirestore.instance.collection('users').doc(user.uid).collection('meal_history').add({
          ...meal,
          'timestamp': FieldValue.serverTimestamp(),
        });
      }
    } catch (e) {
      print('Error saving meal to history: $e');
    }
  }
}