import { containsLikelyPersonalData, sanitizeGeographicText } from "./privacy.ts";

Deno.test("free text blocks common personal identifiers", () => {
  const blocked = [
    "Contactar a juan@example.com",
    "Llamar al 099 123 456",
    "Teléfono +598 99 123 456",
    "Cédula 4.567.890-1",
    "Testigo: Juan Pérez",
    "El denunciante llamado Juan Pérez",
    "La señora María López",
  ];
  for (const value of blocked) {
    if (!containsLikelyPersonalData(value)) throw new Error(`Debió bloquear: ${value}`);
  }
});

Deno.test("free text preserves ordinary case questions and descriptive phrases", () => {
  const allowed = [
    "¿Qué vio el testigo de luz en Canelones?",
    "La persona observó una esfera sobre el río",
    "El testigo visual describió una luz",
    "El investigador de RENOU clasificó el caso",
    "¿Hay casos cerca de Montevideo?",
    "¿Qué pasó el 2026-11-13?",
    "Analiza el caso RENOU-2026-000001",
  ];
  for (const value of allowed) {
    if (containsLikelyPersonalData(value)) throw new Error(`No debió bloquear: ${value}`);
  }
});

Deno.test("geographic sanitization removes common personal identifiers", () => {
  const value = "Canelones +598 99 123 456 juan@example.com 4.567.890-1";
  const sanitized = sanitizeGeographicText(value);
  if (/\+598|099|@|4\.567\.890-1/.test(sanitized)) {
    throw new Error(`Quedó un identificador personal: ${sanitized}`);
  }
});

Deno.test("geographic sanitization preserves dates, RENOU IDs and place names", () => {
  const value = "Montevideo, caso RENOU-2026-000001, fecha 2026-11-13";
  const sanitized = sanitizeGeographicText(value);
  if (sanitized !== value) throw new Error(`Se alteró texto no personal: ${sanitized}`);
});

Deno.test("geographic sanitization enforces the output length", () => {
  const sanitized = sanitizeGeographicText("Canelones".repeat(30), 40);
  if (sanitized.length > 40) throw new Error("No se respetó el límite de longitud");
});
