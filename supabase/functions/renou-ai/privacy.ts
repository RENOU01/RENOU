// Filtros preventivos de privacidad para RENOU AI.
// No garantizan detectar todos los nombres propios ni toda la información personal.

function normalize(value: unknown): string {
  if (value === null || value === undefined) return "";
  if (Array.isArray(value)) return value.map(normalize).join(" ");
  if (typeof value === "object") return JSON.stringify(value);
  return String(value);
}

export function sanitizeGeographicText(value: unknown, maxLength = 100): string {
  return normalize(value)
    .normalize("NFC")
    .replace(/[\r\n\t]+/g, " ")
    .replace(/\b[A-Z0-9._%+-]+@[A-Z0-9.-]+\.[A-Z]{2,}\b/gi, "[dato omitido]")
    .replace(/(?<![A-Z0-9.-])(?:\+\d{1,3}[\s().-]?)?(?:\d{2,4}[\s().-]){1,3}\d{3,4}(?![A-Z0-9.-])|\b\d{8,15}\b/g, "[dato omitido]")
    .replace(/\b\d{1,2}\.?\d{3}\.?\d{3}-?\d\b/g, "[dato omitido]")
    .replace(/\s+/g, " ")
    .trim()
    .slice(0, maxLength);
}

export function containsLikelyPersonalData(value: string): boolean {
  const email = /\b[A-Z0-9._%+-]+@[A-Z0-9.-]+\.[A-Z]{2,}\b/i;
  const phone = /(?<![A-Z0-9.-])(?:\+\d{1,3}[\s().-]?)?(?:\d{2,4}[\s().-]){1,3}\d{3,4}(?![A-Z0-9.-])|\b\d{8,15}\b/;
  const uruguayId = /\b\d{1,2}\.?\d{3}\.?\d{3}-?\d\b/;
  // Heurística contextual: evita confundir "testigo de luz" o "persona observó" con nombres. No detecta todos los nombres propios.
  const identifiedPerson = /\b(?:[Tt]estigo|[Dd]enunciante|[Rr]eportante|[Ii]nvestigador(?:a)?|[Ss]eñor|[Ss]eñora|[Ss]r\.?|[Ss]ra\.?)(?:\s*[:：]\s*(?:(?:llamado|de nombre|identificado como)\s+)?[A-ZÁÉÍÓÚÑ][a-záéíóúñ]+(?:\s+[A-ZÁÉÍÓÚÑ][a-záéíóúñ]+){0,2}|\s+(?:(?:llamado|de nombre|identificado como)\s+[A-ZÁÉÍÓÚÑ][a-záéíóúñ]+(?:\s+[A-ZÁÉÍÓÚÑ][a-záéíóúñ]+){0,2}|[A-ZÁÉÍÓÚÑ][a-záéíóúñ]+\s+[A-ZÁÉÍÓÚÑ][a-záéíóúñ]+(?:\s+[A-ZÁÉÍÓÚÑ][a-záéíóúñ]+)?))\b/u;
  return email.test(value) || phone.test(value) || uruguayId.test(value) || identifiedPerson.test(value);
}
