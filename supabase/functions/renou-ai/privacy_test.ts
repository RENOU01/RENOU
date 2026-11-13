import { containsLikelyPersonalData, resolveAccessScope, resolveCasesUserId, sanitizeGeographicText } from "./privacy.ts";

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

Deno.test("only active investigators receive research scope", () => {
  if (resolveAccessScope(true) !== "research") throw new Error("Investigador activo debe recibir alcance research");
  if (resolveAccessScope(false) !== "public") throw new Error("Usuario sin ficha activa debe conservar alcance público");
});

Deno.test("public scope never passes an authenticated non-investigator ID to the privileged cases RPC", () => {
  if (resolveCasesUserId("public", "user-123") !== null) throw new Error("El alcance público debe enviar p_user_id null");
  if (resolveCasesUserId("research", "investigator-123") !== "investigator-123") throw new Error("El investigador activo debe conservar su ID");
  if (resolveCasesUserId("research", null) !== null) throw new Error("No debe inventarse un ID de investigador");
});
