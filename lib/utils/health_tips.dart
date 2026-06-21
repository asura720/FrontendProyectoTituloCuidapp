import 'dart:math';

/// Consejos de salud que se muestran rotando en Inicio y Controles.
const List<String> healthTips = [
  'Recuerda tomar tus medicinas a la misma hora cada día',
  'Bebe al menos 6 a 8 vasos de agua al día',
  'Camina al menos 30 minutos diarios para cuidar tu corazón',
  'No suspendas tus medicamentos sin consultar a tu médico',
  'Duerme entre 7 y 8 horas para una buena recuperación',
  'Reduce la sal para ayudar a controlar tu presión arterial',
  'Asiste a tus controles médicos aunque te sientas bien',
  'Lávate las manos con frecuencia para evitar infecciones',
  'Incluye frutas y verduras en cada comida',
  'Controla tu presión y azúcar de forma periódica',
  'Evita el cigarro y el exceso de alcohol',
  'Mantén una lista actualizada de tus medicamentos',
  'Tómate un momento para respirar y reducir el estrés',
  'Exponte al sol con moderación para obtener vitamina D',
  'Si sientes mareos o dolor en el pecho, busca ayuda de inmediato',
];

/// Devuelve un consejo de salud al azar.
String randomHealthTip() => healthTips[Random().nextInt(healthTips.length)];
