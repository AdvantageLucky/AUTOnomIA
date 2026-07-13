// === MENSAJES DE VOZ ===
// Reducido drásticamente para agilizar el inicio del flujo peatonal
String welcomeMessage = "Hola, soy Kigo. Te ayudaré con tu registro. Comencemos.";

String listeningMessage = "Te escucho, puedes hablar ahora.";

// Causa + acción directa para el TTS
String ineInvalidMessage = "No reconocimos el documento. Acércalo a la cámara y vuelve a intentar.";

String faceNotDetectedMessage = "No detectamos tu rostro. Asegúrate de tener buena luz y vuelve a intentar.";

String registrationCompleteMessage = "Registro completado exitosamente.";

// === TEXTOS DE UI ===
const String kigoLabel = "Kigo";
const String footerText = "POWERED BY KIGO · FEPRO 2026";

// Botones: Ajustados estrictamente a VERBOS EN INFINITIVO (Regla del PRD)
const String retryButtonText = "Reintentar";
const String backButtonText = "Regresar";
const String continueButtonText = "Confirmar"; // Ajustado a término oficial "Confirmar"
const String continuePressText = "Presionar para continuar";

// Títulos y subtítulos de diálogos (Causa + Acción en el contenido)
const String ineInvalidErrorTitle = "Identificación inválida";
const String faceNotDetectedErrorTitle = "Rostro no detectado";

const String ineInvalidErrorContent = "No reconocimos el documento. Acércalo a la cámara y vuelve a intentar.";
const String faceNotDetectedErrorContent = "No detectamos tu rostro. Asegúrate de tener buena luz y vuelve a intentar.";

// Área de captura
const String instructionAreaCapture = "Área de captura";
const String instructionCameraPreview = "Vista previa de la cámara";
const String noLeida = "No leída"; // Corregido acento

// Identificación: Se cambia "INE" por "Identificación" o "Documento" en la UI general para mantenerlo estándar
const String ineDetectedTitle = "Identificación detectada, puedes continuar";
const String ineTitle = "Identificación";
const String ineSubtitle = "Mantén el documento centrado frente a la cámara";

// Rostro
const String photoEvidenceTitle = "Evidencia fotográfica";
const String photoEvidenceSubtitle = "Coloca tu rostro frente a la cámara";

// Indicaciones de voz breves (para que el visitante actúe rápido en el lobby)
const String voiceInstructionIne = "Muestra tu identificación frente a la cámara sin moverla.";
const String voiceInstructionFace = "Mira de frente a la cámara para tomar tu fotografía.";