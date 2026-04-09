import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

class LoadingScreen extends StatelessWidget {
  final String? message;

  const LoadingScreen({
    Key? key,
    this.message,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        physics: const NeverScrollableScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // App bar skeleton
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: Shimmer.fromColors(
                baseColor: Colors.grey[300]!,
                highlightColor: Colors.grey[100]!,
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Container(width: 80, height: 20, color: Colors.white),
                    const Spacer(),
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Hero banner skeleton
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Shimmer.fromColors(
                baseColor: Colors.grey[300]!,
                highlightColor: Colors.grey[100]!,
                child: Container(
                  height: 180,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Quick actions skeleton
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Shimmer.fromColors(
                baseColor: Colors.grey[300]!,
                highlightColor: Colors.grey[100]!,
                child: Row(
                  children: List.generate(4, (i) {
                    return Expanded(
                      child: Container(
                        height: 80,
                        margin: EdgeInsets.only(right: i < 3 ? 8 : 0),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                    );
                  }),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Category pills skeleton
            SizedBox(
              height: 40,
              child: Shimmer.fromColors(
                baseColor: Colors.grey[300]!,
                highlightColor: Colors.grey[100]!,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: 5,
                  itemBuilder: (_, i) {
                    return Container(
                      width: 80,
                      height: 36,
                      margin: const EdgeInsets.only(right: 10),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                      ),
                    );
                  },
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Section header skeleton
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Shimmer.fromColors(
                baseColor: Colors.grey[300]!,
                highlightColor: Colors.grey[100]!,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(width: 160, height: 18, color: Colors.white),
                    const SizedBox(height: 6),
                    Container(width: 220, height: 12, color: Colors.white),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Property cards skeleton (horizontal)
            SizedBox(
              height: 240,
              child: Shimmer.fromColors(
                baseColor: Colors.grey[300]!,
                highlightColor: Colors.grey[100]!,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: 3,
                  itemBuilder: (_, i) {
                    return Container(
                      width: 220,
                      margin: const EdgeInsets.only(right: 12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                      ),
                    );
                  },
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Second section
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Shimmer.fromColors(
                baseColor: Colors.grey[300]!,
                highlightColor: Colors.grey[100]!,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(width: 140, height: 18, color: Colors.white),
                    const SizedBox(height: 6),
                    Container(width: 200, height: 12, color: Colors.white),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Grid skeleton
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Shimmer.fromColors(
                baseColor: Colors.grey[300]!,
                highlightColor: Colors.grey[100]!,
                child: Row(
                  children: [
                    Expanded(
                      child: Container(
                        height: 200,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Container(
                        height: 200,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}