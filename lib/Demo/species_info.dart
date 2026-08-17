import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ecosnap/Demo/species_info_details.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../Services/unsplash_service.dart';

class ResultScreen extends StatefulWidget {
  final File? imageFile;
  final List<Map<String, dynamic>> recognitions;

  const ResultScreen({
    Key? key,
    required this.imageFile,
    required this.recognitions,
  }) : super(key: key);

  @override
  State<ResultScreen> createState() => _ResultScreenState();
}

class _ResultScreenState extends State<ResultScreen> {
  // Below this, the local model's top guess is unreliable enough that we
  // tell the user instead of presenting it with false confidence.
  static const double _lowConfidenceThreshold = 0.5;

  // Firestore reads are cached per doc id for the app's lifetime so
  // revisiting the same species (or this screen rebuilding) doesn't refetch.
  static final Map<String, Future<DocumentSnapshot>> _speciesDocCache = {};

  // Custom mapping from TFLite labels to Firestore doc IDs
  static const Map<String, String> labelToDocId = {
    'aloevera': 'aloe-vera',
    // Add more mappings here if needed, for example:
    // 'peperchili': 'pepper-chili',
  };

  late final List<Future<DocumentSnapshot>> _docFutures;
  late final List<Future<String?>> _imageFutures;

  @override
  void initState() {
    super.initState();
    // Build each recognition's futures exactly once, up front, so scrolling
    // or any parent rebuild doesn't trigger duplicate Firestore/Unsplash
    // requests (the previous StatelessWidget version created a brand new
    // Future inside itemBuilder on every build).
    _docFutures = widget.recognitions.map((rec) {
      final label = (rec['label'] ?? 'Unknown').toString().trim();
      final docId = getFirestoreDocId(label);
      return _speciesDocCache.putIfAbsent(
        docId,
        () => FirebaseFirestore.instance.collection('data').doc(docId).get(),
      );
    }).toList();

    _imageFutures = widget.recognitions.map((rec) {
      final label = (rec['label'] ?? 'Unknown').toString().trim();
      return UnsplashService().fetchImageUrl(label);
    }).toList();
  }

  String getFirestoreDocId(String label) {
    final lower = label.toLowerCase();
    return labelToDocId[lower] ?? lower.replaceAll(' ', '-');
  }

  String capitalizeEachWord(String text) {
    return text
        .split(' ')
        .map((word) =>
            word.isNotEmpty ? word[0].toUpperCase() + word.substring(1) : '')
        .join(' ');
  }

  @override
  Widget build(BuildContext context) {
    final backgroundColor = const Color(0xFFF4EEDF);
    final lightGreen = const Color(0xFFDDF9D0);
    final green = const Color(0xFF4CAF50);

    final topConfidence = widget.recognitions.isNotEmpty
        ? (widget.recognitions.first['confidence'] as double)
        : 1.0;
    final isLowConfidence = topConfidence < _lowConfidenceThreshold;

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: backgroundColor,
        elevation: 0,
        leading: BackButton(color: Colors.green),
        centerTitle: true,
        title: Text(
          'Result',
          style: GoogleFonts.poppins(
            fontSize: 24,
            fontWeight: FontWeight.w600,
            color: green,
          ),
        ),
      ),
      body: Column(
        children: [
          if (widget.imageFile != null)
            Padding(
              padding: const EdgeInsets.all(16),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(30),
                child: AspectRatio(
                  aspectRatio: 4 / 3,
                  child: Image.file(
                    widget.imageFile!,
                    width: double.infinity,
                    fit: BoxFit.contain,
                  ),
                ),
              ),
            ),
          if (isLowConfidence)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF3CD),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFE0C060)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline, color: Color(0xFF8A6D1B)),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        "The model isn't very confident about this one — "
                        "treat the match below as a best guess, not a "
                        "certain identification.",
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          color: const Color(0xFF8A6D1B),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              itemCount: widget.recognitions.length,
              itemBuilder: (context, index) {
                final rec = widget.recognitions[index];
                final speciesLabelRaw = rec['label'] ?? 'Unknown';
                final speciesLabel = speciesLabelRaw.trim();
                final confidence = (rec['confidence'] as double) * 100;

                return FutureBuilder<DocumentSnapshot>(
                  future: _docFutures[index],
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Padding(
                        padding: EdgeInsets.all(16),
                        child: Center(child: CircularProgressIndicator()),
                      );
                    }

                    final data = snapshot.data?.data() as Map<String, dynamic>?;

                    final scientificName = capitalizeEachWord(
                        data?['scientificName']?.toString() ?? 'Unknown');
                    final family = capitalizeEachWord(
                        (data?['family']?.toString() ?? 'Unknown') + ' Family');
                    final category = data?['category']?.toString() ?? 'Unknown';

                    final icon = category.toLowerCase() == 'plant'
                        ? Icons.local_florist
                        : Icons.pets;

                    return FutureBuilder<String?>(
                      future: _imageFutures[index],
                      builder: (context, imageSnapshot) {
                        Widget imageWidget;

                        if (imageSnapshot.connectionState ==
                            ConnectionState.waiting) {
                          imageWidget = Container(
                            width: 70,
                            height: 70,
                            color: Colors.grey.shade200,
                            child: const Center(
                                child: CircularProgressIndicator(strokeWidth: 2)),
                          );
                        } else if (imageSnapshot.hasData &&
                            imageSnapshot.data != null) {
                          imageWidget = ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.network(
                              imageSnapshot.data!,
                              width: 70,
                              height: 70,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => Container(
                                width: 70,
                                height: 70,
                                color: Colors.grey.shade200,
                                child: const Icon(Icons.image_not_supported),
                              ),
                            ),
                          );
                        } else {
                          imageWidget = Container(
                            width: 70,
                            height: 70,
                            color: Colors.grey.shade200,
                            child: const Icon(Icons.image_not_supported),
                          );
                        }

                        return Container(
                          padding: const EdgeInsets.all(12),
                          margin: const EdgeInsets.only(bottom: 16),
                          decoration: BoxDecoration(
                            color: lightGreen,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: const [
                              BoxShadow(
                                color: Colors.black12,
                                blurRadius: 6,
                                offset: Offset(0, 3),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  imageWidget,
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          capitalizeEachWord(speciesLabel),
                                          style: GoogleFonts.poppins(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.green[800],
                                          ),
                                        ),
                                        Text(
                                          scientificName,
                                          style: GoogleFonts.poppins(
                                            fontSize: 14,
                                            fontStyle: FontStyle.italic,
                                            color: Colors.green[700],
                                          ),
                                        ),
                                        Text(
                                          family,
                                          style: GoogleFonts.poppins(
                                            fontSize: 12,
                                            color: Colors.green[700],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Column(
                                    children: [
                                      Icon(icon, color: Colors.green[800], size: 24),
                                      const SizedBox(height: 4),
                                      Text(
                                        '${confidence.toStringAsFixed(1)}%',
                                        style: GoogleFonts.poppins(
                                          color: Colors.green[800],
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFFE9F7D7),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                      vertical: 12),
                                ),
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => SpeciesDetailsScreen(
                                        commonName:
                                            capitalizeEachWord(speciesLabel),
                                        scientificName: capitalizeEachWord(
                                            data?['scientificName'] ?? 'Unknown'),
                                        family: capitalizeEachWord(
                                            data?['family'] ?? 'Unknown'),
                                        confidence: confidence,
                                        description:
                                            data?['description'] ?? 'No description available',
                                        distribution:
                                            data?['distribution'] ?? 'No distribution data',
                                        habitat: data?['habitat'] ?? 'No habitat information',
                                        category: data?['category'] ?? 'Unknown',
                                        region: data?['region'] ?? 'No region info',
                                        uniqueFact:
                                            data?['unique_fact'] ?? 'No unique fact',
                                      ),
                                    ),
                                  );
                                },
                                child: const Text(
                                  'Confirm',
                                  style: TextStyle(
                                    color: Colors.black87,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
