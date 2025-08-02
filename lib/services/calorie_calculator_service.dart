import 'package:flutter/material.dart';

class CalorieCalculatorService {
  static const Map<String, double> _activityMultipliers = {
    'sedentary': 1.2,
    'light': 1.375,
    'moderate': 1.55,
    'active': 1.725,
    'very_active': 1.9,
  };

  // BMR hesaplama (Basal Metabolic Rate)
  static double calculateBMR({
    required double weight,
    required double height,
    required int age,
    required String gender,
  }) {
    if (gender.toLowerCase() == 'male' || gender.toLowerCase() == 'erkek') {
      return 88.362 + (13.397 * weight) + (4.799 * height) - (5.677 * age);
    } else {
      return 447.593 + (9.247 * weight) + (3.098 * height) - (4.330 * age);
    }
  }

  // Günlük kalori ihtiyacı hesaplama
  static double calculateDailyCalories({
    required double weight,
    required double height,
    required int age,
    required String gender,
    required String activityLevel,
  }) {
    final bmr = calculateBMR(
      weight: weight,
      height: height,
      age: age,
      gender: gender,
    );

    final multiplier = _activityMultipliers[activityLevel] ?? 1.2;
    return bmr * multiplier;
  }

  // BMI hesaplama
  static double calculateBMI({
    required double weight,
    required double height,
  }) {
    final heightInMeters = height / 100;
    return weight / (heightInMeters * heightInMeters);
  }

  // BMI kategorisi belirleme
  static String getBMICategory(double bmi) {
    if (bmi < 18.5) {
      return 'Zayıf';
    } else if (bmi < 25) {
      return 'Normal';
    } else if (bmi < 30) {
      return 'Fazla Kilolu';
    } else {
      return 'Obez';
    }
  }

  // Hedef kilo için kalori hesaplama
  static double calculateCaloriesForGoal({
    required double currentWeight,
    required double targetWeight,
    required double dailyCalories,
    required String goal, // 'lose', 'gain', 'maintain'
  }) {
    switch (goal.toLowerCase()) {
      case 'lose':
        return dailyCalories - 500; // 0.5 kg/hafta için
      case 'gain':
        return dailyCalories + 500; // 0.5 kg/hafta için
      case 'maintain':
      default:
        return dailyCalories;
    }
  }

  // Yemek kalori tahmini
  static Map<String, dynamic> estimateFoodCalories(String foodName) {
    final Map<String, Map<String, dynamic>> foodDatabase = {
      'elma': {'calories': 52, 'protein': 0.3, 'carbs': 14, 'fat': 0.2},
      'muz': {'calories': 89, 'protein': 1.1, 'carbs': 23, 'fat': 0.3},
      'tavuk göğsü': {'calories': 165, 'protein': 31, 'carbs': 0, 'fat': 3.6},
      'pilav': {'calories': 130, 'protein': 2.7, 'carbs': 28, 'fat': 0.3},
      'salata': {'calories': 20, 'protein': 1, 'carbs': 4, 'fat': 0.1},
      'ekmek': {'calories': 265, 'protein': 9, 'carbs': 49, 'fat': 3.2},
      'yumurta': {'calories': 155, 'protein': 13, 'carbs': 1.1, 'fat': 11},
    };

    final normalizedFood = foodName.toLowerCase().trim();
    return foodDatabase[normalizedFood] ?? {
      'calories': 100,
      'protein': 5,
      'carbs': 15,
      'fat': 3,
    };
  }

  // Günlük kalori takibi
  static double calculateTotalDailyCalories(List<Map<String, dynamic>> meals) {
    double total = 0;
    for (final meal in meals) {
      total += (meal['calories'] as num?)?.toDouble() ?? 0;
    }
    return total;
  }

  // Kalori hedefine kalan miktar
  static double getRemainingCalories({
    required double targetCalories,
    required double consumedCalories,
  }) {
    return targetCalories - consumedCalories;
  }

  // Makro besin dağılımı hesaplama
  static Map<String, double> calculateMacroDistribution({
    required double totalCalories,
    double proteinRatio = 0.25, // %25 protein
    double carbRatio = 0.45, // %45 karbonhidrat
    double fatRatio = 0.30, // %30 yağ
  }) {
    return {
      'protein': totalCalories * proteinRatio / 4, // 1g protein = 4 kalori
      'carbs': totalCalories * carbRatio / 4, // 1g karbonhidrat = 4 kalori
      'fat': totalCalories * fatRatio / 9, // 1g yağ = 9 kalori
    };
  }
}
