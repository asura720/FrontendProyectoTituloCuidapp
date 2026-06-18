import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:intl/intl.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'dart:typed_data';
import '../services/catalog_service.dart';

class ScannerScreen extends StatefulWidget {
  const ScannerScreen({super.key});

  @override
  State<ScannerScreen> createState() => _ScannerScreenState();
}

class _ScannerScreenState extends State<ScannerScreen> {
  late MobileScannerController _scannerController;
  bool _isScanning = true;
  bool _isProcessing = false;
  Uint8List? _latestImage;
  final List<Map<String, dynamic>> _scannedHistory = [
    {
      'barcode': '8714789987654',
      'name': 'Aspirina 500mg',
      'date': DateTime.now().subtract(const Duration(days: 1)),
      'status': 'success',
      'type': 'barcode',
    },
    {
      'barcode': '8714789987620',
      'name': 'Ibuprofeno 200mg',
      'date': DateTime.now().subtract(const Duration(days: 2)),
      'status': 'success',
      'type': 'barcode',
    },
    {
      'barcode': '8714789987789',
      'name': 'Vitamina C 1000mg',
      'date': DateTime.now().subtract(const Duration(days: 3)),
      'status': 'success',
      'type': 'barcode',
    },
  ];

  @override
  void initState() {
    super.initState();
    _scannerController = MobileScannerController(
      formats: [
        BarcodeFormat.all, // Soporta todos los formatos: QR, EAN, CODE128, etc.
      ],
      facing: CameraFacing.back,
      torchEnabled: false,
      returnImage: true,
    );
  }

  @override
  void dispose() {
    _scannerController.dispose();
    super.dispose();
  }

  void _handleDetect(BarcodeCapture capture) {
    _latestImage = capture.image;

    final List<Barcode> barcodes = capture.barcodes;

    if (barcodes.isNotEmpty && _isScanning && !_isProcessing) {
      final scannedValue = barcodes.first.rawValue ?? '';

      setState(() {
        _isScanning = false;
        _isProcessing = true;
      });
      _scannerController.stop();

      _lookupBarcodeAndShow(scannedValue);
    }
  }

  /// Consulta el catálogo del backend por código de barras y muestra el resultado.
  Future<void> _lookupBarcodeAndShow(String code) async {
    Map<String, dynamic>? med;
    try {
      med = await CatalogService.findByBarcode(code);
    } catch (_) {
      med = null;
    }
    if (!mounted) return;
    _showScanResult(code, 'barcode', med);
  }

  /// Busca en el catálogo por las palabras del texto OCR y muestra el resultado.
  Future<void> _lookupOcrAndShow(String ocrText) async {
    Map<String, dynamic>? med;
    final words = ocrText
        .toLowerCase()
        .replaceAll('\n', ' ')
        .split(RegExp(r'[^a-záéíóúñ0-9]+'))
        .where((w) => w.length > 3)
        .toList();
    try {
      for (final w in words.take(6)) {
        final results = await CatalogService.search(w);
        if (results.isNotEmpty) {
          med = results.first;
          break;
        }
      }
    } catch (_) {
      med = null;
    }
    if (!mounted) return;
    final shown = med != null
        ? (med['name']?.toString() ?? ocrText)
        : (ocrText.length > 40 ? ocrText.substring(0, 40) : ocrText);
    _showScanResult(shown, 'ocr', med);
  }

  Future<void> _performOCR() async {
    if (_isProcessing || !_scannerController.isStarting) return;

    setState(() {
      _isProcessing = true;
      _isScanning = false;
    });
    _scannerController.stop();

    try {
      // 1. Obtener la última imagen capturada por la cámara
      final imageBytes = _latestImage;

      if (imageBytes == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Buscando enfoque... Apunta a la caja e intenta de nuevo.')),
        );
        _resumeScanning();
        return;
      }

      // 2. Guardar la imagen en un archivo temporal
      final tempDir = await getTemporaryDirectory();
      final tempFile = File('${tempDir.path}/ocr_image.png');
      await tempFile.writeAsBytes(imageBytes);

      // 3. Crear InputImage desde la ruta del archivo
      final inputImage = InputImage.fromFilePath(tempFile.path);

      // 4. Procesar la imagen con el TextRecognizer
      final textRecognizer = TextRecognizer(
        script: TextRecognitionScript.latin,
      );
      final RecognizedText recognizedText = await textRecognizer.processImage(
        inputImage,
      );
      await textRecognizer.close();

      // 5. Limpiar el archivo temporal
      await tempFile.delete();

      // 6. Buscar el medicamento en el catálogo del backend usando el texto OCR
      await _lookupOcrAndShow(recognizedText.text);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error en OCR: $e'),
          backgroundColor: Colors.red,
        ),
      );
      _resumeScanning();
    }
  }

  void _showScanResult(
    String scannedValue,
    String detectionType,
    Map<String, dynamic>? med,
  ) {
    // Construir el item a partir del resultado del catálogo (backend)
    Map<String, dynamic>? foundItem;
    if (med != null) {
      foundItem = {
        'barcode': (med['barcode'] ?? scannedValue).toString(),
        'name': (med['name'] ?? 'Medicamento').toString(),
        'date': DateTime.now(),
        'status': 'success',
        'type': detectionType,
        'dosage': med['dosage']?.toString() ?? '',
        'form': med['form']?.toString() ?? '',
      };
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => SafeArea(
        top: false,
        child: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.only(
          top: 24,
          left: 24,
          right: 24,
          bottom: 24,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE0E0E0),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              if (foundItem != null)
                Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFFECFDF5),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.check_circle,
                        color: Color(0xFF10B981),
                        size: 32,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Medicamento identificado',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF10B981),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              foundItem['name'],
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF059669),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                )
              else
                Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEF3C7),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.info,
                        color: Color(0xFFF59E0B),
                        size: 32,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Medicamento no identificado',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFFA16207),
                              ),
                            ),
                            const SizedBox(height: 4),
                            const Text(
                              'Este medicamento no está en nuestra base de datos',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFFB45309),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 20),
              Container(
                decoration: BoxDecoration(
                  color: const Color(0xFFF5F7FA),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE0E0E0)),
                ),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      detectionType == 'barcode'
                          ? 'Código de Barras'
                          : 'Texto Detectado',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF717182),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0xFFE0E0E0)),
                      ),
                      padding: const EdgeInsets.all(12),
                      child: Text(
                        scannedValue,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF030213),
                          fontFamily: 'Courier',
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              if (foundItem != null) ...[
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFE0E0E0)),
                  ),
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Información del Medicamento',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF030213),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Nombre:',
                            style: TextStyle(
                              fontSize: 12,
                              color: Color(0xFF717182),
                            ),
                          ),
                          Text(
                            foundItem['name'],
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF030213),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Tipo de Detección:',
                            style: TextStyle(
                              fontSize: 12,
                              color: Color(0xFF717182),
                            ),
                          ),
                          Container(
                            decoration: BoxDecoration(
                              color: detectionType == 'barcode'
                                  ? Colors.blue[100]
                                  : Colors.orange[100],
                              borderRadius: BorderRadius.circular(4),
                            ),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            child: Text(
                              detectionType == 'barcode'
                                  ? 'Código de Barras'
                                  : 'OCR (Texto)',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: detectionType == 'barcode'
                                    ? Colors.blue[700]
                                    : Colors.orange[700],
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Hora:',
                            style: TextStyle(
                              fontSize: 12,
                              color: Color(0xFF717182),
                            ),
                          ),
                          Text(
                            DateFormat(
                              'hh:mm a',
                              'es_ES',
                            ).format(foundItem['date']),
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF030213),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
              ],
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        side: const BorderSide(
                          color: Color(0xFFE0E0E0),
                          width: 2,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      onPressed: () => Navigator.pop(context),
                      child: const Text(
                        'Cerrar',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF717182),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1A56DB),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      onPressed: () {
                        // Agregar a historial
                        if (foundItem != null) {
                          setState(() {
                            _scannedHistory.add(foundItem!);
                          });
                        } else {
                          setState(() {
                            _scannedHistory.add({
                              'barcode': scannedValue,
                              'name': 'Medicamento desconocido',
                              'date': DateTime.now(),
                              'status': 'unknown',
                              'type': detectionType,
                            });
                          });
                        }
                        Navigator.pop(context);
                        _resumeScanning();
                      },
                      child: const Text(
                        'Escanear Otro',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    ),
  ).then((_) {
    _resumeScanning();
  });
  }

  void _resumeScanning() {
    if (mounted) {
      setState(() {
        _isScanning = true;
        _isProcessing = false;
      });
      _scannerController.start();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // Header
          SliverAppBar(
            floating: true,
            pinned: true,
            backgroundColor: const Color(0xFF1A56DB),
            elevation: 4,
            expandedHeight: 160,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFF1A56DB), Color(0xFF2563EB)],
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Escáner Avanzado',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        DateFormat(
                          'd \'de\' MMMM yyyy',
                          'es_ES',
                        ).format(DateTime.now()),
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.white70,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // Scanner View
          SliverToBoxAdapter(
            child: Column(
              children: [
                Container(
                  height: 300,
                  margin: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: const Color(0xFF1A56DB),
                      width: 2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF1A56DB).withValues(alpha: 0.2),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: MobileScanner(
                          controller: _scannerController,
                          onDetect: _handleDetect,
                          errorBuilder: (context, error, child) {
                            return Container(
                              color: Colors.black,
                              child: Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(
                                      Icons.camera_alt_outlined,
                                      color: Colors.white70,
                                      size: 64,
                                    ),
                                    const SizedBox(height: 16),
                                    Text(
                                      'Error de cámara:\n${error.errorCode.name}',
                                      textAlign: TextAlign.center,
                                      style: const TextStyle(
                                        color: Colors.white70,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      // Reticula de enfoque
                      Center(
                        child: Container(
                          width: 250,
                          height: 250,
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.white, width: 2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFFFEF3C7),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFF59E0B)),
                        ),
                        padding: const EdgeInsets.all(12),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.info_outline,
                              color: Color(0xFFA16207),
                              size: 20,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Escanea códigos de barras o QR',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFFA16207),
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  const Text(
                                    'Soporta: QR, EAN, CODE128, DataMatrix',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: Color(0xFFB45309),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF10B981),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 12,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        onPressed: _isProcessing ? null : _performOCR,
                        icon: const Icon(Icons.text_fields),
                        label: const Text(
                          'Leer Texto de la Caja (OCR)',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Historial de escaneos
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Historial de Escaneos (${_scannedHistory.length})',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF030213),
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
              ),
            ),
          ),

          // Lista de historial
          SliverList(
            delegate: SliverChildBuilderDelegate((context, index) {
              final item = _scannedHistory[index];
              final isOCR = item['type'] == 'ocr';
              return Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                ).copyWith(bottom: 12),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFE0E0E0)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 8,
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          color: isOCR
                              ? Colors.orange[100]
                              : const Color(0xFFECFDF5),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        padding: const EdgeInsets.all(8),
                        child: Icon(
                          isOCR ? Icons.text_fields : Icons.qr_code,
                          color: isOCR ? Colors.orange[700] : Colors.green[700],
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item['name'],
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF030213),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Text(
                                  DateFormat(
                                    'd \'de\' MMM - hh:mm a',
                                    'es_ES',
                                  ).format(item['date']),
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: Color(0xFF717182),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  decoration: BoxDecoration(
                                    color: isOCR
                                        ? Colors.orange[100]
                                        : Colors.blue[100],
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 2,
                                  ),
                                  child: Text(
                                    isOCR ? 'OCR' : 'Código',
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w600,
                                      color: isOCR
                                          ? Colors.orange[700]
                                          : Colors.blue[700],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFFF5F7FA),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        child: Text(
                          item['barcode'],
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF1A56DB),
                            fontFamily: 'Courier',
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }, childCount: _scannedHistory.length),
          ),

          const SliverPadding(padding: EdgeInsets.only(bottom: 20)),
        ],
      ),
    );
  }
}
