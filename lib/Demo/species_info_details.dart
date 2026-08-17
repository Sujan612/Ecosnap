import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../Services/unsplash_service.dart';

class SpeciesDetailsScreen extends StatefulWidget {
  final String scientificName;
  final String commonName;
  final String family;
  final double confidence;
  final String description;
  final String distribution;
  final String habitat;
  final String category;
  final String region;
  final String uniqueFact;

  const SpeciesDetailsScreen({
    super.key,
    required this.scientificName,
    required this.commonName,
    required this.family,
    required this.confidence,
    required this.description,
    required this.distribution,
    required this.habitat,
    required this.category,
    required this.region,
    required this.uniqueFact,
  });

  @override
  State<SpeciesDetailsScreen> createState() => _SpeciesDetailsScreenState();
}

class _SpeciesDetailsScreenState extends State<SpeciesDetailsScreen> {
  bool isSaved = false;
  bool isShared = false;

  String? imageUrl;
  bool isLoadingImage = true;

  @override
  void initState() {
    super.initState();
    fetchUnsplashImage(widget.commonName);
    _saveViewedSpecies(widget.commonName);
    _saveViewedSpeciesToFirestore();
  }

  String normalizeKey(String name) {
    return name.toLowerCase().replaceAll(' ', '-');
  }

  Future<void> _saveViewedSpecies(String commonName) async {
    final prefs = await SharedPreferences.getInstance();
    final viewedList = prefs.getStringList('viewed_species') ?? [];

    if (!viewedList.contains(commonName)) {
      viewedList.add(commonName);
      await prefs.setStringList('viewed_species', viewedList);
    }
  }

  Future<void> _saveViewedSpeciesToFirestore() async {
    try {
      final docId = normalizeKey(widget.commonName);

      final data = {
        'common_name': widget.commonName,
        'scientific_name': widget.scientificName,
        'family': widget.family,
        'description': widget.description,
        'category': widget.category,
        'region': widget.region,
        'unique_fact': widget.uniqueFact,
        'habitat': widget.habitat,
        'confidence': widget.confidence,
        'distribution': widget.distribution,
        'viewed_at': FieldValue.serverTimestamp(),
      };

      await FirebaseFirestore.instance
          .collection('recent_discoveries')
          .doc(docId)
          .set(data, SetOptions(merge: true));
    } catch (e) {
      debugPrint("Error saving viewed species to Firestore: $e");
    }
  }

  Future<void> fetchUnsplashImage(String query) async {
    setState(() => isLoadingImage = true);

    final fetchedUrl = await UnsplashService().fetchImageUrl(
      query,
      fallbackKeyword: query.contains('-') ? query.replaceAll('-', ' ') : null,
    );

    if (!mounted) return;
    setState(() {
      imageUrl = fetchedUrl;
      isLoadingImage = false;
    });
  }

  Widget sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6.0),
      child: Text(
        title,
        style: GoogleFonts.poppins(
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: const Color(0xFF2E7D32),
        ),
      ),
    );
  }

  Widget sectionContent(String content, {bool italic = false}) {
    return Text(
      content.isNotEmpty ? content : 'Not available',
      style: GoogleFonts.openSans(
        fontSize: 16,
        fontStyle: italic ? FontStyle.italic : FontStyle.normal,
        height: 1.5,
        color: const Color(0xFF3E4E3E),
      ),
    );
  }

  Widget buildActionButton({
    required bool isActive,
    required VoidCallback onTap,
    required IconData iconData,
    required String label,
  }) {
    final activeColor = const Color(0xFF4CAF50);
    final inactiveColor = Colors.grey.shade400;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isActive ? activeColor.withOpacity(0.15) : Colors.transparent,
          border: Border.all(color: isActive ? activeColor : inactiveColor),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(iconData, color: isActive ? activeColor : inactiveColor, size: 24),
            const SizedBox(width: 8),
            Text(
              label,
              style: GoogleFonts.openSans(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: isActive ? activeColor : inactiveColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bgColor = const Color(0xFFF0F6EF);
    final shadowColor = Colors.green.shade200;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        title: Text('Species Details', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
        centerTitle: true,
        backgroundColor: const Color(0xFF4CAF50),
        elevation: 4,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: Container(
                height: 230,
                decoration: BoxDecoration(
                  boxShadow: [
                    BoxShadow(
                      color: shadowColor.withOpacity(0.4),
                      blurRadius: 12,
                      offset: const Offset(0, 6),
                    )
                  ],
                ),
                child: isLoadingImage
                    ? const Center(child: CircularProgressIndicator(color: Color(0xFF4CAF50)))
                    : imageUrl != null
                    ? Image.network(imageUrl!, fit: BoxFit.cover)
                    : Container(
                  color: Colors.grey.shade300,
                  child: const Center(
                    child: Icon(Icons.image_not_supported, size: 80, color: Colors.grey),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 24),

            Align(
              alignment: Alignment.centerLeft,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFFC8E6C9),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${widget.category[0].toUpperCase()}${widget.category.substring(1).toLowerCase()}: ${widget.commonName}',
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF2E7D32),
                    fontSize: 16,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 16),
            sectionTitle('Description'),
            sectionContent(widget.description),

            const SizedBox(height: 18),
            sectionTitle('Family'),
            sectionContent(widget.family),

            const SizedBox(height: 18),
            sectionTitle('Region'),
            sectionContent(widget.region),

            const SizedBox(height: 18),
            sectionTitle('Scientific Name'),
            sectionContent(widget.scientificName, italic: true),

            const SizedBox(height: 18),
            sectionTitle('Unique Fact'),
            sectionContent(widget.uniqueFact, italic: true),

            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0xFFE6F4EA),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFF81C784)),
              ),
              child: Center(
                child: Text(
                  'Confidence: ${widget.confidence.toStringAsFixed(1)}%',
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF388E3C),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 32),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                buildActionButton(
                  isActive: isSaved,
                  onTap: () {
                    setState(() => isSaved = !isSaved);
                  },
                  iconData: isSaved ? Icons.bookmark : Icons.bookmark_border,
                  label: 'Save info',
                ),
                buildActionButton(
                  isActive: isShared,
                  onTap: () {
                    setState(() => isShared = !isShared);
                  },
                  iconData: isShared ? Icons.share : Icons.share_outlined,
                  label: 'Share',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
