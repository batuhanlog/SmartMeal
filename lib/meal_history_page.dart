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
        // Yemek geçmişini yükle
        final historyQuery = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('meal_history')
            .orderBy('timestamp', descending: true)
            .limit(50)
            .get();

        // Favori yemekleri yükle
        final favoritesQuery = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('favorite_meals')
            .orderBy('addedAt', descending: true)
            .get();

        setState(() {
          _mealHistory = historyQuery.docs.map((doc) {
            final data = doc.data();
            data['id'] = doc.id;
            return data;
          }).toList();

          _favoriteMeals = favoritesQuery.docs.map((doc) {
            final data = doc.data();
            data['id'] = doc.id;
            return data;
          }).toList();

          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ErrorHandler.showError(context, 'Veriler yüklenirken hata oluştu');
      }
    }
  }

  Future<void> _addToFavorites(Map<String, dynamic> meal) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('favorite_meals')
            .add({
          ...meal,
          'addedAt': FieldValue.serverTimestamp(),
        });

        if (mounted) {
          ErrorHandler.showSuccess(context, 'Favorilere eklendi!');
          _loadData(); // Listeyi yenile
        }
      }
    } catch (e) {
      if (mounted) {
        ErrorHandler.showError(context, 'Favorilere eklenirken hata oluştu');
      }
    }
  }

  Future<void> _removeFromFavorites(String docId) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('favorite_meals')
            .doc(docId)
            .delete();

        if (mounted) {
          ErrorHandler.showSuccess(context, 'Favorilerden kaldırıldı');
          _loadData(); // Listeyi yenile
        }
      }
    } catch (e) {
      if (mounted) {
        ErrorHandler.showError(context, 'Favorilerden kaldırılırken hata oluştu');
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
        title: const Text('📋 Yemek Geçmişim'),
        backgroundColor: Colors.orange.shade300,
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(
              icon: Icon(Icons.history),
              text: 'Geçmiş',
            ),
            Tab(
              icon: Icon(Icons.favorite),
              text: 'Favoriler',
            ),
          ],
        ),
      ),
      body: TabBarView(
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
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.restaurant_menu,
              size: 64,
              color: Colors.grey,
            ),
            SizedBox(height: 16),
            Text(
              'Henüz yemek geçmişin yok',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'AI\'dan yemek önerisi aldığında burada görünecek',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _mealHistory.length,
      itemBuilder: (context, index) {
        final meal = _mealHistory[index];
        return _buildMealCard(meal, isHistory: true);
      },
    );
  }

  Widget _buildFavoritesTab() {
    if (_favoriteMeals.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.favorite_border,
              size: 64,
              color: Colors.grey,
            ),
            SizedBox(height: 16),
            Text(
              'Henüz favori yemeğin yok',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Beğendiğin yemekleri favorilere ekleyebilirsin',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _favoriteMeals.length,
      itemBuilder: (context, index) {
        final meal = _favoriteMeals[index];
        return _buildMealCard(meal, isHistory: false);
      },
    );
  }

  Widget _buildMealCard(Map<String, dynamic> meal, {required bool isHistory}) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  meal['emoji'] ?? '🍽️',
                  style: const TextStyle(fontSize: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        meal['name'] ?? 'Bilinmeyen Yemek',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (meal['timestamp'] != null || meal['addedAt'] != null)
                        Text(
                          _formatDate(meal['timestamp'] ?? meal['addedAt']),
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                          ),
                        ),
                    ],
                  ),
                ),
                if (isHistory)
                  IconButton(
                    onPressed: () => _addToFavorites(meal),
                    icon: const Icon(Icons.favorite_border),
                    tooltip: 'Favorilere Ekle',
                  )
                else
                  IconButton(
                    onPressed: () => _removeFromFavorites(meal['id']),
                    icon: const Icon(Icons.favorite, color: Colors.red),
                    tooltip: 'Favorilerden Kaldır',
                  ),
              ],
            ),
            if (meal['calories'] != null || meal['protein'] != null) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  if (meal['calories'] != null)
                    _buildNutritionChip('Kalori', '${meal['calories']}', Colors.orange),
                  if (meal['protein'] != null) ...[
                    const SizedBox(width: 8),
                    _buildNutritionChip('Protein', '${meal['protein']}g', Colors.blue),
                  ],
                  if (meal['prep_time'] != null) ...[
                    const SizedBox(width: 8),
                    _buildNutritionChip('Süre', '${meal['prep_time']} dk', Colors.green),
                  ],
                ],
              ),
            ],
            if (meal['description'] != null) ...[
              const SizedBox(height: 8),
              Text(
                meal['description'],
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.grey,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildNutritionChip(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        '$label: $value',
        style: TextStyle(
          fontSize: 12,
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  String _formatDate(dynamic timestamp) {
    if (timestamp == null) return '';
    
    DateTime date;
    if (timestamp is Timestamp) {
      date = timestamp.toDate();
    } else if (timestamp is DateTime) {
      date = timestamp;
    } else {
      return '';
    }

    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return 'Bugün ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
    } else if (difference.inDays == 1) {
      return 'Dün';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} gün önce';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }
}

// Yemek geçmişine kaydetmek için yardımcı fonksiyon
class MealHistoryService {
  static Future<void> saveMealToHistory(Map<String, dynamic> meal) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('meal_history')
            .add({
          ...meal,
          'timestamp': FieldValue.serverTimestamp(),
        });
      }
    } catch (e) {
      print('Error saving meal to history: $e');
    }
  }
}
