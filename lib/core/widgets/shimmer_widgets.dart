import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import '../theme/app_theme.dart';

class ShimmerWidgets {
  static Widget buildProfileShimmer(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: context.isDarkMode ? Colors.grey[800]! : Colors.grey[300]!,
      highlightColor: context.isDarkMode ? Colors.grey[700]! : Colors.grey[100]!,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const SizedBox(height: 20),
            // Avatar
            const CircleAvatar(radius: 60),
            const SizedBox(height: 16),
            // Name
            Container(width: 150, height: 24, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8))),
            const SizedBox(height: 8),
            // Phone
            Container(width: 100, height: 16, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8))),
            const SizedBox(height: 32),
            // Stats
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: List.generate(3, (index) => Column(
                children: [
                  Container(width: 40, height: 24, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8))),
                  const SizedBox(height: 4),
                  Container(width: 60, height: 14, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8))),
                ],
              )),
            ),
            const SizedBox(height: 32),
            // Menu Items
            ...List.generate(5, (index) => Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Row(
                children: [
                  const CircleAvatar(radius: 20),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Container(height: 20, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8))),
                  ),
                ],
              ),
            )),
          ],
        ),
      ),
    );
  }

  static Widget buildJobDetailShimmer(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: context.isDarkMode ? Colors.grey[800]! : Colors.grey[300]!,
      highlightColor: context.isDarkMode ? Colors.grey[700]! : Colors.grey[100]!,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            height: 200,
            color: Colors.white,
          ),
          const SizedBox(height: 20),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(width: 100, height: 40, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8))),
                    const SizedBox(width: 16),
                    Container(width: 100, height: 40, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8))),
                  ],
                ),
                const SizedBox(height: 24),
                Container(width: 150, height: 20, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8))),
                const SizedBox(height: 12),
                Container(width: double.infinity, height: 14, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(4))),
                const SizedBox(height: 8),
                Container(width: double.infinity, height: 14, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(4))),
                const SizedBox(height: 8),
                Container(width: 200, height: 14, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(4))),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
