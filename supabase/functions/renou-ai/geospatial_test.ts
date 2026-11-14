import { GeospatialAnalyzer } from "./geospatial.ts";

Deno.test("geospatial analyzer counts close cases using original coordinates", () => {
  const analyzer = new GeospatialAnalyzer();
  analyzer.add("RENOU-2026-000001", -34.9011, -56.1645, "2026-01-01");
  analyzer.add("RENOU-2026-000002", -34.9012, -56.1646, "2026-01-02");
  const result = analyzer.summary();
  if (result.total_casos_con_coordenadas !== 2) throw new Error("Debió contar dos casos georreferenciados");
  if (result.pares_a_menos_de_1_km !== 1) throw new Error("Debió detectar el par a menos de 1 km");
  if (result.ejemplos_pares_hasta_5_km.length !== 1) throw new Error("Debió conservar el ejemplo de proximidad");
});

Deno.test("geospatial analyzer does not count distant cases as close", () => {
  const analyzer = new GeospatialAnalyzer();
  analyzer.add("RENOU-2026-000001", -34.9011, -56.1645, "2026-01-01");
  analyzer.add("RENOU-2026-000002", -31.4167, -64.1833, "2026-01-02");
  if (analyzer.summary().pares_a_menos_de_25_km !== 0) throw new Error("No debió detectar proximidad entre ubicaciones distantes");
});

Deno.test("geospatial analyzer rejects missing and out-of-range coordinates", () => {
  const analyzer = new GeospatialAnalyzer();
  analyzer.add("RENOU-2026-000001", null, null, "2026-01-01");
  analyzer.add("RENOU-2026-000002", 95, 200, "2026-01-02");
  const result = analyzer.summary();
  if (result.total_casos_con_coordenadas !== 0) throw new Error("No debió aceptar coordenadas inválidas");
  if (result.total_casos_sin_coordenadas !== 2) throw new Error("Debió contabilizar ambos casos sin coordenadas válidas");
  if (result.coordenadas_presentes_pero_invalidas !== 1) throw new Error("Debió identificar coordenadas presentes pero inválidas");
});

Deno.test("geospatial analyzer preserves sub-centesimal coordinate differences", () => {
  const analyzer = new GeospatialAnalyzer();
  analyzer.add("RENOU-2026-000001", -34.90111, -56.16451, "2026-01-01");
  analyzer.add("RENOU-2026-000002", -34.90119, -56.16459, "2026-01-02");
  if (analyzer.summary().pares_a_menos_de_1_km !== 1) throw new Error("Debió analizar coordenadas con precisión completa");
});
