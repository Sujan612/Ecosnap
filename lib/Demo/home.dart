import 'package:ecosnap/Demo/recognition.dart';
import 'package:ecosnap/Demo/species_info_details.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../Services/unsplash_service.dart';
import 'bottomnavbar.dart';

class EcoSnapHomeScreen extends StatefulWidget {
  const EcoSnapHomeScreen({super.key});

  @override
  State<EcoSnapHomeScreen> createState() => _EcoSnapHomeScreenState();
}

class _EcoSnapHomeScreenState extends State<EcoSnapHomeScreen> {
  List<QueryDocumentSnapshot>? _shuffledFacts;

  @override
  void initState() {
    super.initState();
    _fetchFactsOnce();
  }

  Future<void> _fetchFactsOnce() async {
    final snapshot = await FirebaseFirestore.instance.collection('eco_facts').get();
    final docs = snapshot.docs.toList();
    docs.shuffle();
    setState(() {
      _shuffledFacts = docs.take(4).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFEFE6D5),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: IntrinsicHeight(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildHeader(),
                        const SizedBox(height: 24),
                        _buildCarousel(),
                        const SizedBox(height: 32),
                        _buildSnapPrompt(context),
                        const SizedBox(height: 32),
                        const Text(
                          "Recent Discoveries",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 20,
                            color: Color(0xFF2E7D32),
                          ),
                        ),
                        const SizedBox(height: 16),
                        _buildRecentDiscoveries(),
                        const SizedBox(height: 24), // Add space for bottom nav bar
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),

      bottomNavigationBar: const CustomBottomNavBar(currentIndex: 0),
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: const [
            Icon(Icons.eco, size: 30, color: Color(0xFF4CAF50)),
            SizedBox(width: 12),
            Text(
              'EcoSnap',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Color(0xFF4CAF50),
              ),
            ),
          ],
        ),
        const Icon(Icons.notifications, color: Color(0xFF4CAF50), size: 28),
      ],
    );
  }

  Widget _buildCarousel() {
    if (_shuffledFacts == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return SizedBox(
      height: 190,
      child: PageView.builder(
        controller: PageController(viewportFraction: 0.9),
        itemCount: _shuffledFacts!.length,
        itemBuilder: (context, index) {
          final data = _shuffledFacts![index].data()! as Map<String, dynamic>;
          final title = data['title'] ?? 'Nature';
          final subtitle = data['description'] ?? '';

          return FutureBuilder<String?>(
            future: UnsplashService().fetchImageUrl(title),
            builder: (context, snapshot) {
              final imageUrl = snapshot.data;

              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      if (imageUrl != null)
                        Image.network(
                          imageUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) =>
                          const Center(child: Icon(Icons.error, color: Colors.white, size: 40)),
                        )
                      else
                        const Center(child: CircularProgressIndicator()),
                      Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.bottomCenter,
                            end: Alignment.topCenter,
                            colors: [
                              Colors.black.withOpacity(0.65),
                              Colors.transparent,
                            ],
                          ),
                        ),
                      ),
                      Positioned(
                        bottom: 16,
                        left: 16,
                        right: 16,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              title,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                shadows: [
                                  Shadow(
                                    blurRadius: 6,
                                    color: Colors.black54,
                                    offset: Offset(0, 2),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              subtitle,
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 14,
                                shadows: [
                                  Shadow(
                                    blurRadius: 4,
                                    color: Colors.black45,
                                    offset: Offset(0, 1),
                                  ),
                                ],
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildSnapPrompt(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const RecognitionPage()),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Colors.green.withOpacity(0.25),
              blurRadius: 15,
              offset: const Offset(0, 8),
            ),
          ],
          border: Border.all(color: Colors.green.shade200),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.green.shade200.withOpacity(0.6),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: const Icon(Icons.camera_alt, color: Colors.green, size: 28),
            ),
            const SizedBox(width: 18),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Start today's snap?",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      color: Color(0xFF2E7D32),
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    "Explore nearby nature?",
                    style: TextStyle(
                      color: Colors.grey,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios, size: 18, color: Color(0xFF4CAF50)),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentDiscoveries() {
    return SizedBox(
      height: 220, // Slightly increased height to accommodate scroll
      child: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('recent_discoveries')
            .orderBy('viewed_at', descending: true)
            .limit(6)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text("No recent discoveries yet."));
          }

          final docs = snapshot.data!.docs;

          return ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: docs.length,
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            itemBuilder: (context, index) {
              final data = docs[index].data()! as Map<String, dynamic>;

              final commonName = data['common_name'] ?? 'Unknown';
              final scientificName = data['scientific_name'] ?? '';
              final description = data['description'] ?? '';
              final storedImageUrl = data['image_url'];

              final Future<String?> imageFuture = storedImageUrl != null
                  ? Future.value(storedImageUrl)
                  : UnsplashService().fetchImageUrl(commonName);

              return FutureBuilder<String?>(
                future: imageFuture,
                builder: (context, snapshot) {
                  final imageUrl = snapshot.data;

                  return GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => SpeciesDetailsScreen(
                            scientificName: scientificName,
                            commonName: commonName,
                            family: data['family'] ?? '',
                            confidence: (data['confidence'] ?? 100).toDouble(),
                            description: description,
                            distribution: data['distribution'] ?? '',
                            habitat: data['habitat'] ?? '',
                            category: data['category'] ?? '',
                            region: data['region'] ?? '',
                            uniqueFact: data['unique_fact'] ?? '',
                          ),
                        ),
                      );
                    },
                    child: Container(
                      width: 170,
                      margin: EdgeInsets.only(right: index == docs.length - 1 ? 0 : 12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.green.shade100.withOpacity(0.6),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      padding: const EdgeInsets.all(14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: imageUrl != null
                                ? Image.network(
                              imageUrl,
                              height: 110,
                              width: double.infinity,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) => Container(
                                height: 110,
                                color: Colors.grey.shade200,
                                child: const Icon(
                                  Icons.image_not_supported,
                                  size: 40,
                                  color: Colors.grey,
                                ),
                              ),
                            )
                                : Container(
                              height: 110,
                              color: Colors.grey.shade200,
                              child: Center(
                                child: Text(
                                  commonName.isNotEmpty ? commonName[0].toUpperCase() : '?',
                                  style: const TextStyle(fontSize: 40, color: Colors.grey),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            commonName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                              color: Color(0xFF2E7D32),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Expanded(
                            child: SingleChildScrollView(
                              child: Text(
                                scientificName,
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontStyle: FontStyle.italic,
                                  color: Colors.black54,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }

}
