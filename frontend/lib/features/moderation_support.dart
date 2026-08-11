import 'package:flutter/material.dart';

/// Conflict-safe moderation helpers. Backend deletion and account updates remain
/// outside this file because those tasks are assigned to other developers.
class ModerationSupport {
  const ModerationSupport._();

  static bool canMarkViolation({
    required String reportedReason,
    required bool guidelineConfirmed,
  }) {
    return reportedReason.trim().isNotEmpty && guidelineConfirmed;
  }

  static Future<bool> confirmViolation(
    BuildContext context, {
    required String listingName,
    required String reportedReason,
  }) async {
    if (reportedReason.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('A reported reason is required.')),
      );
      return false;
    }

    return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Confirm Guideline Violation'),
            content: Text(
              'Listing: $listingName\n\nReported reason: $reportedReason\n\n'
              'Confirm only after reviewing the listing against the community guidelines.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(context, true),
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF2E7D32),
                ),
                child: const Text('Violation Confirmed'),
              ),
            ],
          ),
        ) ??
        false;
  }

    /// Call this AFTER the teammate-owned delete API succeeds.
  static Future<List<T>> refreshAfterRemoval<T>({
    required Future<List<T>> Function() reloadListings,
  }) async {
    return reloadListings();
  }

    /// The actual database ban operation remains teammate-owned.
  static Future<List<T>?> confirmBanAndRefresh<T>(
    BuildContext context, {
    required String userName,
    required Future<bool> Function() performBan,
    required Future<List<T>> Function() reloadUsers,
  }) async {
    final confirmed = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            icon: const Icon(Icons.block, color: Colors.redAccent),
            title: const Text('Ban User?'),
            content: Text(
              'Ban $userName from NeighbourShare? This action should only be used for confirmed community-guideline violations.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(context, true),
                style: FilledButton.styleFrom(backgroundColor: Colors.redAccent),
                child: const Text('Confirm Ban'),
              ),
            ],
          ),
        ) ??
        false;

    if (!confirmed) return null;

    final success = await performBan();
    if (!context.mounted) return null;

    if (!success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Unable to ban user. Please try again.'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return null;
    }

    final refreshedUsers = await reloadUsers();
    if (!context.mounted) return refreshedUsers;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$userName was banned successfully. User list refreshed.'),
        backgroundColor: const Color(0xFF2E7D32),
      ),
    );

    return refreshedUsers;
  }
}
