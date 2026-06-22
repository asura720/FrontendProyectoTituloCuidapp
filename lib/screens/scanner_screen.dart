import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../services/catalog_service.dart';
import '../providers/medication_provider.dart';
import '../models/medication.dart';
import '../widgets/app_header.dart';

class ScannerScreen extends StatefulWidget {
  const ScannerScreen({super.key});

  @override
  State<ScannerScreen> createState() => _ScannerScreenState();
}

class _ScannerScreenState extends State<ScannerScreen>
    with WidgetsBindingObserver {
  bool _isProcessing = false;
  CameraController? _camera;
  bool _cameraReady = false;
  String? _cameraError;
  final List<Map<String, dynamic>> _scannedHistory = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initCamera();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _camera?.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final cam = _camera;
    if (cam == null || !cam.value.isInitialized) return;
    if (state == AppLifecycleState.inactive) {
      cam.dispose();
    } else if (state == AppLifecycleState.resumed) {
      _initCamera();
    }
  }

  Future<void> _initCamera() async {
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        setState(() => _cameraError = 'No se encontró cámara');
        return;
      }
      final back = cameras.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.back,
        orElse: () => cameras.first,
      );
      final controller = CameraController(
        back,
        ResolutionPreset.high,
        enableAudio: false,
      );
      await controller.initialize();
      if (!mounted) {
        controller.dispose();
        return;
      }
      setState(() {
        _camera = controller;
        _cameraReady = true;
        _cameraError = null;
      });
    } catch (e) {
      if (mounted) setState(() => _cameraError = 'No se pudo abrir la cámara: $e');
    }
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

  /// Captura un cuadro de la cámara en vivo, reconoce el texto (OCR) y busca.
  Future<void> _performOCR() async {
    final cam = _camera;
    if (_isProcessing || cam == null || !cam.value.isInitialized) return;
    setState(() => _isProcessing = true);
    try {
      final XFile photo = await cam.takePicture();

      final inputImage = InputImage.fromFilePath(photo.path);
      final textRecognizer =
          TextRecognizer(script: TextRecognitionScript.latin);
      final RecognizedText recognizedText =
          await textRecognizer.processImage(inputImage);
      await textRecognizer.close();

      if (recognizedText.text.trim().isEmpty) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text(
                  'No se detectó texto. Acerca la cámara al nombre del medicamento.')),
        );
        return;
      }
      await _lookupOcrAndShow(recognizedText.text);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error en OCR: $e'), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  /// Bloque visual para "Para qué sirve" / "Efectos secundarios".
  Widget _infoBlock(
    IconData icon,
    String title,
    String text,
    Color color,
    Color bg,
  ) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: color),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            text,
            style: const TextStyle(fontSize: 13, color: Color(0xFF374151), height: 1.4),
          ),
        ],
      ),
    );
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
        'uso': med['uso']?.toString() ?? '',
        'efectos': med['efectosSecundarios']?.toString() ?? '',
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
                if ((foundItem['uso'] as String).isNotEmpty) ...[
                  const SizedBox(height: 12),
                  _infoBlock(
                    Icons.healing_outlined,
                    'Para qué sirve',
                    foundItem['uso'],
                    const Color(0xFF1A56DB),
                    const Color(0xFFEFF4FF),
                  ),
                ],
                if ((foundItem['efectos'] as String).isNotEmpty) ...[
                  const SizedBox(height: 12),
                  _infoBlock(
                    Icons.warning_amber_rounded,
                    'Efectos secundarios',
                    foundItem['efectos'],
                    const Color(0xFFB45309),
                    const Color(0xFFFEF3C7),
                  ),
                ],
                const SizedBox(height: 20),
              ],
              // Agregar el medicamento escaneado para recordatorios
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF10B981),
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  icon: const Icon(Icons.add_alarm, color: Colors.white),
                  label: const Text(
                    'Agregar a mis medicamentos',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w600),
                  ),
                  onPressed: () {
                    Navigator.pop(context);
                    _showAddMedicationSheet(
                      (foundItem?['name'] ?? scannedValue).toString(),
                      (foundItem?['dosage'] ?? '').toString(),
                    );
                  },
                ),
              ),
              const SizedBox(height: 12),
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
        _isProcessing = false;
      });
    }
  }

  /// Formulario rápido para agregar el medicamento escaneado a los recordatorios.
  void _showAddMedicationSheet(String name, String dosage) {
    final nameCtrl = TextEditingController(text: name.trim());
    final dosageCtrl = TextEditingController(text: dosage.trim());
    final List<String> times = ['08:00'];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setSheet) => SafeArea(
          top: false,
          child: Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            padding: EdgeInsets.only(
              left: 20,
              right: 20,
              top: 22,
              bottom: MediaQuery.of(ctx).viewInsets.bottom + 22,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                const Text('Agregar medicamento',
                    style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1A1A1A))),
                const SizedBox(height: 16),
                TextField(
                  controller: nameCtrl,
                  decoration: InputDecoration(
                    labelText: 'Nombre del medicamento',
                    prefixIcon: const Icon(Icons.medication_outlined,
                        color: Color(0xFF1A56DB)),
                    filled: true,
                    fillColor: const Color(0xFFF5F7FB),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: dosageCtrl,
                  decoration: InputDecoration(
                    labelText: 'Dosis (ej: 50mg)',
                    prefixIcon: const Icon(Icons.scale_outlined,
                        color: Color(0xFF1A56DB)),
                    filled: true,
                    fillColor: const Color(0xFFF5F7FB),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text('Horarios',
                      style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey[700])),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    ...times.map((t) => Chip(
                          label: Text(t),
                          backgroundColor: const Color(0xFFE8EEFB),
                          labelStyle: const TextStyle(
                              color: Color(0xFF1A56DB),
                              fontWeight: FontWeight.w600),
                          onDeleted: () => setSheet(() => times.remove(t)),
                          deleteIconColor: const Color(0xFF1A56DB),
                        )),
                    ActionChip(
                      avatar: const Icon(Icons.add,
                          size: 18, color: Color(0xFF1A56DB)),
                      label: const Text('Agregar hora'),
                      onPressed: () async {
                        final picked = await showTimePicker(
                            context: ctx, initialTime: TimeOfDay.now());
                        if (picked != null) {
                          final f =
                              '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
                          if (!times.contains(f)) {
                            setSheet(() {
                              times.add(f);
                              times.sort();
                            });
                          }
                        }
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 22),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1A56DB),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: () {
                      if (nameCtrl.text.trim().isEmpty) {
                        ScaffoldMessenger.of(ctx).showSnackBar(
                          const SnackBar(
                              content: Text('Escribe el nombre del medicamento')),
                        );
                        return;
                      }
                      final med = Medication(
                        id: DateTime.now().millisecondsSinceEpoch.toString(),
                        name: nameCtrl.text.trim(),
                        dosage: dosageCtrl.text.trim(),
                        frequency: times.length == 1
                            ? '1 vez al día'
                            : '${times.length} veces al día',
                        times: List<String>.from(times),
                        containerColor: const Color(0xFFf3f3f5),
                        iconColor: const Color(0xFF1A56DB),
                      );
                      context.read<MedicationProvider>().addMedication(med);
                      Navigator.pop(ctx);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('"${med.name}" agregado a tus medicamentos'),
                          backgroundColor: const Color(0xFF10B981),
                        ),
                      );
                    },
                    child: const Text('Guardar',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w600)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          sectionSliverAppBar('Escáner'),

          // Scanner View
          SliverToBoxAdapter(
            child: Column(
              children: [
                // Vista de cámara en vivo
                Container(
                  height: 300,
                  margin: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.black,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFF1A56DB), width: 2),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      if (_cameraReady && _camera != null)
                        FittedBox(
                          fit: BoxFit.cover,
                          child: SizedBox(
                            width: _camera!.value.previewSize?.height ?? 1,
                            height: _camera!.value.previewSize?.width ?? 1,
                            child: CameraPreview(_camera!),
                          ),
                        )
                      else
                        Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const CircularProgressIndicator(
                                  valueColor:
                                      AlwaysStoppedAnimation<Color>(Colors.white)),
                              const SizedBox(height: 12),
                              Text(
                                _cameraError ?? 'Abriendo cámara...',
                                textAlign: TextAlign.center,
                                style: const TextStyle(color: Colors.white70),
                              ),
                            ],
                          ),
                        ),
                      // Marco guía para encuadrar el nombre
                      if (_cameraReady)
                        Center(
                          child: Container(
                            margin: const EdgeInsets.symmetric(horizontal: 24),
                            height: 90,
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.white, width: 2),
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ),
                      if (_isProcessing)
                        Container(
                          color: Colors.black54,
                          child: const Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                CircularProgressIndicator(
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                        Colors.white)),
                                SizedBox(height: 12),
                                Text('Leyendo el nombre...',
                                    style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w600)),
                              ],
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
                                    'Encuadra el nombre dentro del marco y captura',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFFA16207),
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  const Text(
                                    'Leemos el nombre del medicamento y su información',
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
                      // Botón para escanear el NOMBRE de la caja (OCR)
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF10B981),
                            padding: const EdgeInsets.symmetric(vertical: 13),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          onPressed: _isProcessing ? null : _performOCR,
                          icon: const Icon(Icons.camera_alt,
                              color: Colors.white),
                          label: const Text(
                            'Capturar y escanear',
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.w600),
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
