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
  // --- TEMA RENKLERİ ---
  final Color primaryColor = Colors.green.shade800;
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
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final Map<String, dynamic> favoriteData = Map.from(meal);
        favoriteData.remove('id');
        favoriteData.remove('timestamp');
        favoriteData['addedAt'] = FieldValue.serverTimestamp();

        await FirebaseFirestore.instance.collection('users').doc(user.uid).collection('favorite_meals').add(favoriteData);
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
        title: const Text('Yemeklerim', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: backgroundColor,
        foregroundColor: Colors.black87,
        elevation: 0,
        centerTitle: true,
      ),
      body: _isLoading 
        ? Center(child: CircularProgressIndicator(color: primaryColor))
        : Column(
            children: [
              _buildTabBar(),
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildHistoryTab(),
                    _buildFavoritesTab(),
                  ],
                ),
              ),
            ],
          ),
    );
  }

  Widget _buildTabBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(color: Colors.grey.shade200, borderRadius: BorderRadius.circular(12)),
        child: TabBar(
          controller: _tabController,
          indicator: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 5)]
          ),
          labelColor: primaryColor,
          unselectedLabelColor: Colors.grey.shade600,
          tabs: const [
            Tab(child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.history_rounded), SizedBox(width: 8), Text('Geçmiş')])),
            Tab(child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.favorite_rounded), SizedBox(width: 8), Text('Favoriler')])),
          ],
        ),
      ),
    );
  }

  Widget _buildHistoryTab() {
    if (_mealHistory.isEmpty) {
      return _buildEmptyState(
        icon: Icons.history_edu_outlined,
        title: 'Henüz Yemek Geçmişin Yok',
        subtitle: 'Yapay zekadan yemek önerisi aldığında veya bir yemek analizi kaydettiğinde burada görünecek.',
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _mealHistory.length,
      itemBuilder: (context, index) => _buildMealCard(_mealHistory[index]),
    );
  }

  Widget _buildFavoritesTab() {
    if (_favoriteMeals.isEmpty) {
      return _buildEmptyState(
        icon: Icons.favorite_border_rounded,
        title: 'Henüz Favori Yemeğin Yok',
        subtitle: 'Beğendiğin yemekleri geçmiş listesinden kalbe dokunarak favorilere ekleyebilirsin.',
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _favoriteMeals.length,
      itemBuilder: (context, index) => _buildMealCard(_favoriteMeals[index]),
    );
  }

  Widget _buildEmptyState({required IconData icon, required String title, required String subtitle}) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(shape: BoxShape.circle, color: primaryColor.withOpacity(0.05)),
              child: Icon(icon, size: 48, color: primaryColor.withOpacity(0.6)),
            ),
            const SizedBox(height: 24),
            Text(title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black87)),
            const SizedBox(height: 8),
            Text(subtitle, style: TextStyle(fontSize: 16, color: Colors.grey.shade600), textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }

  Widget _buildMealCard(Map<String, dynamic> meal) {
    final favoriteMatch = _favoriteMeals.where((fav) => fav['name'] == meal['name']);
    final isFavorite = favoriteMatch.isNotEmpty;
    final favoriteId = isFavorite ? favoriteMatch.first['id'] : null;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)]),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(shape: BoxShape.circle, color: backgroundColor),
                child: Text(meal['emoji'] ?? '🍽️', style: const TextStyle(fontSize: 24)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(meal['name'] ?? 'Bilinmeyen Yemek', style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
                    if (meal['timestamp'] != null || meal['addedAt'] != null)
                      Text(_formatDate(meal['timestamp'] ?? meal['addedAt']), style: TextStyle(fontSize: 13, color: Colors.grey.shade600)),
                  ],
                ),
              ),
              IconButton(
                onPressed: () {
                  if (isFavorite && favoriteId != null) {
                    _removeFromFavorites(favoriteId);
                  } else {
                    _addToFavorites(meal);
                  }
                },
                icon: Icon(
                  isFavorite ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                  color: isFavorite ? favoriteColor : Colors.grey.shade400,
                ),
                tooltip: isFavorite ? 'Favorilerden Kaldır' : 'Favorilere Ekle',
              ),
            ],
          ),
          if (meal['calories'] != null) ...[
            const Divider(height: 24),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                _buildNutritionChip('Kalori', '${meal['calories']} kcal', Icons.local_fire_department_rounded, Colors.orange),
                if (meal['protein'] != null)
                  _buildNutritionChip('Protein', '${meal['protein']}g', Icons.fitness_center_rounded, Colors.blue),
                if (meal['prep_time'] != null)
                  _buildNutritionChip('Süre', '${meal['prep_time']} dk', Icons.timer_outlined, Colors.teal),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildNutritionChip(String label, String value, IconData icon, Color color) {
    // DÜZELTME: Hatalı olan .shade800 kullanımı, Color.lerp ile değiştirildi.
    // Bu yöntem, gelen rengi %60 oranında siyah ile karıştırarak koyulaştırır.
    final Color textColor = Color.lerp(color, Colors.black, 0.6)!;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(20)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 6),
          Text(value, style: TextStyle(fontSize: 13, color: textColor, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  String _formatDate(dynamic timestamp) {
    if (timestamp == null) return '';
    final date = (timestamp as Timestamp).toDate();
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0 && now.day == date.day) return 'Bugün, ${TimeOfDay.fromDateTime(date).format(context)}';
    if (difference.inDays == 1 || (difference.inDays == 0 && now.day != date.day)) return 'Dün';
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