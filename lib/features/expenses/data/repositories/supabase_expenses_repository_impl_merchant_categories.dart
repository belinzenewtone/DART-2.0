part of 'supabase_expenses_repository_impl.dart';

Future<String> _resolveLearnedCategoryImpl(
  SupabaseExpensesRepositoryImpl repo, {
  required String userId,
  required String merchantTitle,
  required String fallbackCategory,
  double? amountKes,
}) async {
  final merchantKey = _normalizeMerchantKey(merchantTitle);
  if (merchantKey.isEmpty) {
    return fallbackCategory;
  }
  final rows = await _safeSelectImpl(
    repo,
    table: 'merchant_categories',
    filters: (query) => query
        .select('category')
        .eq('owner_id', userId)
        .eq('merchant_key', merchantKey)
        .limit(1),
  );
  if (rows.isNotEmpty) {
    final learned = '${rows.first['category'] ?? ''}'.trim();
    if (learned.isNotEmpty) {
      return learned;
    }
  }
  final learned = await repo._merchantLearningService.resolveCategory(
    merchantTitle: merchantTitle,
    fallbackCategory: fallbackCategory,
  );
  if (learned == fallbackCategory && amountKes != null) {
    const engine = CategoryInferenceEngine();
    final guess = engine.infer(title: merchantTitle, amountKes: amountKes);
    if (guess != null && guess.confidence >= 0.6) {
      return guess.category;
    }
  }
  return learned;
}

Future<void> _learnMerchantCategoryImpl(
  SupabaseExpensesRepositoryImpl repo, {
  required String userId,
  required String merchantTitle,
  required String category,
}) async {
  final merchantKey = _normalizeMerchantKey(merchantTitle);
  final cleanedCategory = category.trim();
  if (merchantKey.isEmpty || cleanedCategory.isEmpty) {
    return;
  }

  try {
    final existingRows = await repo._client
        .from('merchant_categories')
        .select('id,usage_count')
        .eq('owner_id', userId)
        .eq('merchant_key', merchantKey)
        .limit(1);
    final existing = (existingRows as List).cast<Map<String, dynamic>>();
    if (existing.isEmpty) {
      await repo._client.from('merchant_categories').insert({
        'owner_id': userId,
        'merchant_key': merchantKey,
        'category': cleanedCategory,
        'usage_count': 1,
        'updated_at': DateTime.now().toUtc().toIso8601String(),
      });
    } else {
      final row = existing.first;
      await repo._client
          .from('merchant_categories')
          .update({
            'category': cleanedCategory,
            'usage_count': parseInt(row['usage_count']) + 1,
            'updated_at': DateTime.now().toUtc().toIso8601String(),
          })
          .eq('id', parseInt(row['id']))
          .eq('owner_id', userId);
    }
  } catch (_) {
    return;
  } finally {
    await repo._merchantLearningService.learn(
      merchantTitle: merchantTitle,
      category: cleanedCategory,
    );
  }
}

String _normalizeMerchantKey(String merchantTitle) {
  return merchantTitle
      .toLowerCase()
      .replaceAll(RegExp(r'[^a-z0-9 ]'), ' ')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();
}
