import 'package:flutter/foundation.dart';
import 'package:mobile/core/constants/app_config.dart';

class Recipe {
  final int id;
  final String title;
  final String description;
  final String cookingTime;
  final String localVideoPath;
  final String? thumbnailPath;
  final String source;
  final String externalId;
  final List<Ingredient> ingredients;
  final List<Step> steps;
  final List<Tag> tags;
  final String createdAt;

  Recipe({
    required this.id,
    required this.title,
    required this.description,
    required this.cookingTime,
    required this.localVideoPath,
    this.thumbnailPath,
    required this.source,
    required this.externalId,
    required this.ingredients,
    required this.steps,
    required this.tags,
    required this.createdAt,
  });

  factory Recipe.fromJson(Map<String, dynamic> json) {
    return Recipe(
      id: json['ID'] ?? 0,
      title: json['Title'] ?? '',
      description: json['Description'] ?? '',
      cookingTime: json['CookingTime'] ?? '',
      localVideoPath: json['LocalVideoPath'] ?? '',
      thumbnailPath: json['ThumbnailPath'],
      source: json['Source'] ?? '',
      externalId: json['ExternalID'] ?? '',
      createdAt: json['CreatedAt'] ?? '',
      ingredients: (json['Ingredients'] as List<dynamic>?)
              ?.map((e) => Ingredient.fromJson(e))
              .toList() ??
          [],
      steps: (json['Steps'] as List<dynamic>?)
              ?.map((e) => Step.fromJson(e))
              .toList() ??
          [],
      tags: (json['Tags'] as List<dynamic>?)
              ?.map((e) => Tag.fromJson(e))
              .toList() ??
          [],
    );
  }

  // Helper to get full video URL based on environment
  String get fullVideoUrl {
    final fileName = localVideoPath.split('/').last;
    return '${AppConfig.apiBaseUrl}/videos/$fileName';
  }

  String? get fullThumbnailUrl {
    if (thumbnailPath == null || thumbnailPath!.isEmpty) return null;
    final fileName = thumbnailPath!.split('/').last;
    return '${AppConfig.apiBaseUrl}/videos/$fileName';
  }
}

class Ingredient {
  final String item;
  final String quantity;

  Ingredient({required this.item, required this.quantity});

  factory Ingredient.fromJson(Map<String, dynamic> json) {
    return Ingredient(
      item: json['Item'] ?? '',
      quantity: json['Quantity'] ?? '',
    );
  }
}

class Step {
  final String text;

  Step({required this.text});

  factory Step.fromJson(Map<String, dynamic> json) {
    return Step(
      text: json['Text'] ?? '',
    );
  }
}

class Tag {
  final String name;

  Tag({required this.name});

  factory Tag.fromJson(Map<String, dynamic> json) {
    return Tag(
      name: json['Name'] ?? '',
    );
  }
}
