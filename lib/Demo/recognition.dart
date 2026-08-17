import 'dart:io';
import 'dart:typed_data';

import 'package:ecosnap/Demo/species_info.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:image/image.dart' as img;
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:tflite_flutter/tflite_flutter.dart';

import '../Services/plantnet_service.dart';
import 'bottomnavbar.dart';

class RecognitionPage extends StatefulWidget {
  const RecognitionPage({super.key});
  @override
  State<RecognitionPage> createState() => _RecognitionPageState();
}

class _RecognitionPageState extends State<RecognitionPage> {
  File? _selectedImage;
  List<Map<String, dynamic>>? _recognitions;
  late Interpreter _interpreter;
  bool _interpreterInitialized = false;
  bool _isProcessing = false;

  // Below this, the local model's guess is unreliable enough that we try
  // the Pl@ntNet fallback (if configured) instead of trusting it outright.
  static const double _lowConfidenceThreshold = 0.5;

  final PlantNetService _plantNetService = PlantNetService();

  List<String> labels = [];

  @override
  void initState() {
    super.initState();
    _loadModel();
  }

  Future<void> _loadModel() async {
    try {
      // The label file is the single source of truth for class names, kept
      // in lockstep with the model instead of a second hardcoded list here.
      final labelText =
          await rootBundle.loadString('assets/models/label.txt');
      labels = labelText
          .split('\n')
          .map((l) => l.trim())
          .where((l) => l.isNotEmpty)
          .toList();

      _interpreter = await Interpreter.fromAsset(
        'assets/models/ecospan_model_80_accuracy.tflite',
        options: InterpreterOptions()..threads = 4,
      );
      setState(() => _interpreterInitialized = true);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to load model: ${e.toString()}")),
      );
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    if (_isProcessing) return;

    setState(() {
      _isProcessing = true;
      _recognitions = null;
    });

    try {
      final permissionStatus = await (source == ImageSource.camera
          ? Permission.camera.request()
          : Permission.photos.request());

      if (!permissionStatus.isGranted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Permission denied")),
        );
        return;
      }

      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(source: source);
      if (pickedFile != null) {
        final file = File(pickedFile.path);
        setState(() {
          _selectedImage = file;
        });

        if (_interpreterInitialized) {
          await _runInference(file);
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: ${e.toString()}")),
      );
    } finally {
      setState(() {
        _isProcessing = false;
      });
    }
  }

  Future<void> _runInference(File imageFile) async {
    try {
      final bytes = await imageFile.readAsBytes();
      final image = img.decodeImage(bytes);
      if (image == null) return;

      final inputTensor = _interpreter.getInputTensor(0);
      final shape = inputTensor.shape;
      final height = shape[1], width = shape[2], channels = shape[3];
      if (!inputTensor.type.toString().contains('float32')) {
        throw Exception("Unsupported input type: ${inputTensor.type}");
      }
      final resizedImage = img.copyResize(image, width: width, height: height);

      // The model graph has no Rescaling/normalization op before its first
      // Conv2D (verified by inspecting the .tflite graph directly), so it
      // expects raw 0-255 float pixel values, not 0-1 or -1..1 normalized
      // input. This was confirmed empirically too: feeding normalized input
      // makes the model collapse to the same class for every image, while
      // raw 0-255 input produces varied, content-dependent predictions.
      final inputBuffer = Float32List(width * height * channels);
      int i = 0;
      for (int y = 0; y < height; y++) {
        for (int x = 0; x < width; x++) {
          final pixel = resizedImage.getPixel(x, y);
          inputBuffer[i++] = pixel.r.toDouble();
          inputBuffer[i++] = pixel.g.toDouble();
          inputBuffer[i++] = pixel.b.toDouble();
        }
      }
      final input = inputBuffer.reshape([1, height, width, channels]);

      final outputTensor = _interpreter.getOutputTensor(0);
      final outputShape = outputTensor.shape;
      if (!outputTensor.type.toString().contains('float32')) {
        throw Exception("Unsupported output type: ${outputTensor.type}");
      }
      // The final op in the graph is a Softmax, so this is already a
      // probability distribution over classes (sums to ~1) — not raw
      // logits, and not int8/uint8 quantized output needing dequantization.
      final output = List.filled(outputShape.reduce((a, b) => a * b), 0.0)
          .reshape(outputShape);

      _interpreter.run(input, output);
      final flatOutput = List<double>.from(
        output[0].map((v) => (v as num).toDouble()),
      );

      final topResults = List.generate(flatOutput.length, (i) {
        return {
          'label': i < labels.length ? labels[i] : 'Label $i',
          'confidence': flatOutput[i],
        };
      })
        ..sort((a, b) =>
            (b['confidence'] as double).compareTo(a['confidence'] as double));

      var recognitions = List<Map<String, dynamic>>.from(topResults.take(3));

      // Local model first, always — this fallback only runs when it's
      // uncertain, so EcoSnap keeps working fully offline otherwise.
      final topConfidence = recognitions.first['confidence'] as double;
      if (topConfidence < _lowConfidenceThreshold &&
          _plantNetService.isConfigured) {
        final plantMatches = await _plantNetService.identify(imageFile);
        // Only prefer Pl@ntNet if it's actually more confident than the
        // local model's uncertain guess; otherwise keep the local result
        // (the UI already flags it as low-confidence).
        if (plantMatches.isNotEmpty &&
            plantMatches.first.confidence > topConfidence) {
          recognitions = plantMatches.map((m) => m.toRecognition()).toList();
        }
      }

      setState(() {
        _recognitions = recognitions;
      });

      if (_selectedImage != null && _recognitions != null) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ResultScreen(
              imageFile: _selectedImage!,
              recognitions: _recognitions!,
            ),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Recognition failed: ${e.toString()}")),
      );
    }
  }

  @override
  void dispose() {
    _interpreter.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(
              'assets/5.png', // <-- Your background image here
              fit: BoxFit.cover,
            ),
          ),
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xAAE0F3E8), Color(0xAAFDF3E8)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
            ),
          ),
          SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(minHeight: constraints.maxHeight),
                    child: IntrinsicHeight(
                      child: Column(
                        children: [
                          const SizedBox(height: 20),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(16),
                              decoration: const BoxDecoration(
                                color: Color(0xFFE0F3E8),
                                borderRadius: BorderRadius.only(
                                  topLeft: Radius.circular(20),
                                  topRight: Radius.circular(40),
                                  bottomRight: Radius.circular(40),
                                ),
                              ),
                              child: Row(
                                children: [
                                  GestureDetector(
                                    onTap: () => Navigator.pop(context),
                                    child: const Icon(Icons.arrow_back,
                                        color: Colors.green),
                                  ),
                                  const SizedBox(width: 16),
                                  const Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Recognition',
                                        style: TextStyle(
                                            fontSize: 24,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.green),
                                      ),
                                      Text(
                                        'Identify plants and nature instantly',
                                        style: TextStyle(
                                            fontSize: 14, color: Colors.green),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),
                          if (_isProcessing)
                            const CircularProgressIndicator(color: Colors.green)
                          else
                            GestureDetector(
                              onTap: () => _pickImage(ImageSource.camera),
                              child: Container(
                                decoration: const BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Color(0xFFC9F9A6),
                                ),
                                padding: const EdgeInsets.all(40),
                                child: const Icon(Icons.camera_alt_rounded,
                                    size: 60, color: Colors.green),
                              ),
                            ),
                          const SizedBox(height: 20),
                          const Text(
                            'Tap to open camera and\nidentify instantly',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                                fontSize: 16,
                                color: Colors.green,
                                fontWeight: FontWeight.w500),
                          ),
                          if (_selectedImage != null)
                            Padding(
                              padding: const EdgeInsets.all(12),
                              child: Column(
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(16),
                                    child: Image.file(_selectedImage!,
                                        fit: BoxFit.contain),
                                  ),
                                  const SizedBox(height: 16),
                                  if (_recognitions != null)
                                    Column(
                                      children: _recognitions!.map((res) {
                                        return Padding(
                                          padding:
                                          const EdgeInsets.symmetric(vertical: 4),
                                          child: Text(
                                            "${res['label']} - ${(res['confidence'] * 100).toStringAsFixed(1)}%",
                                            style: const TextStyle(
                                                fontSize: 18,
                                                fontWeight: FontWeight.bold,
                                                color: Colors.green),
                                          ),
                                        );
                                      }).toList(),
                                    ),
                                ],
                              ),
                            ),
                          const SizedBox(height: 20),
                          ElevatedButton.icon(
                            onPressed: _isProcessing
                                ? null
                                : () => _pickImage(ImageSource.gallery),
                            icon: const Icon(Icons.image, color: Colors.green),
                            label: const Text('Upload',
                                style: TextStyle(color: Colors.green)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFE0FCCC),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 40, vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
      bottomNavigationBar: const CustomBottomNavBar(currentIndex: 1),
    );
  }
}

extension ListHelpers<T> on List<T> {
  List reshape(List<int> shape) {
    if (shape.length == 1) return this;
    int size = shape.reduce((a, b) => a * b);
    if (length != size) throw Exception("List size doesn't match shape");
    int chunkSize = size ~/ shape[0];
    return List.generate(shape[0], (i) {
      int start = i * chunkSize;
      int end = start + chunkSize;
      return sublist(start, end).reshape(shape.sublist(1));
    });
  }
}
