import 'package:beltech/core/theme/app_colors.dart';
import 'package:flutter/material.dart';

/// Shared visual descriptor for a spending category.
///
/// Used in transaction rows, expense snapshot cards, and analytics breakdowns
/// so that icon, foreground colour, and background colour are always consistent
/// across the whole app.
({IconData icon, Color foreground, Color background}) categoryVisual(
  String category,
) {
  final normalized = category.trim().toLowerCase();

  if (normalized.contains('food') ||
      normalized.contains('restaurant') ||
      normalized.contains('groceries')) {
    return (
      icon: Icons.restaurant_outlined,
      foreground: AppColors.categoryFood,
      background: AppColors.categoryFoodBg,
    );
  }
  if (normalized.contains('airtime') ||
      normalized.contains('mobile') ||
      normalized.contains('data')) {
    return (
      icon: Icons.phone_android_outlined,
      foreground: AppColors.categoryAirtime,
      background: AppColors.categoryAirtimeBg,
    );
  }
  if (normalized.contains('bill') || normalized.contains('utilities')) {
    return (
      icon: Icons.receipt_long_outlined,
      foreground: AppColors.categoryBill,
      background: AppColors.categoryBillBg,
    );
  }
  if (normalized.contains('transport') ||
      normalized.contains('taxi') ||
      normalized.contains('uber') ||
      normalized.contains('matatu')) {
    return (
      icon: Icons.directions_bus_outlined,
      foreground: AppColors.categoryTransport,
      background: AppColors.categoryTransportBg,
    );
  }
  if (normalized.contains('health') || normalized.contains('medical')) {
    return (
      icon: Icons.local_hospital_outlined,
      foreground: AppColors.categoryHealth,
      background: AppColors.categoryHealth.withValues(alpha: 0.18),
    );
  }
  if (normalized.contains('fuliza')) {
    return (
      icon: Icons.account_balance_outlined,
      foreground: AppColors.warning,
      background: AppColors.warning.withValues(alpha: 0.18),
    );
  }
  if (normalized.contains('salary') || normalized.contains('income')) {
    return (
      icon: Icons.payments_outlined,
      foreground: AppColors.success,
      background: AppColors.success.withValues(alpha: 0.18),
    );
  }
  if (normalized.contains('shopping') || normalized.contains('clothes')) {
    return (
      icon: Icons.shopping_bag_outlined,
      foreground: AppColors.violet,
      background: AppColors.violet.withValues(alpha: 0.18),
    );
  }
  if (normalized.contains('entertainment') || normalized.contains('leisure')) {
    return (
      icon: Icons.movie_outlined,
      foreground: AppColors.azure,
      background: AppColors.azure.withValues(alpha: 0.18),
    );
  }
  // fallback
  return (
    icon: Icons.payments_outlined,
    foreground: AppColors.textSecondary,
    background: AppColors.accentSoft.withValues(alpha: 0.3),
  );
}
