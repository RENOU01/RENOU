// Análisis geoespacial de casos RENOU.
// Conserva las coordenadas originales recibidas desde PostgreSQL.
// Las distancias se calculan con Haversine sobre la esfera terrestre.
const EARTH_RADIUS_KM = 6371.0088;
const MAX_RADIUS_KM = 25;
const CELL_SIZE_KM = MAX_RADIUS_KM;
const RAD = Math.PI / 180;
type GeoPoint = { id: string; lat: number; lon: number; date: string; x: number; y: number; z: number };
type ClosePair = { caso_a: string; caso_b: string; fecha_a: string; fecha_b: string; distancia_km: number };

function asCoordinate(value: unknown, min: number, max: number): number | null {
  if (typeof value !== "number" || !Number.isFinite(value) || value < min || value > max) return null;
  return value;
}
function haversineKm(a: GeoPoint, b: GeoPoint): number {
  const lat1 = a.lat * RAD, lat2 = b.lat * RAD;
  const dLat = (b.lat - a.lat) * RAD, dLon = (b.lon - a.lon) * RAD;
  const h = Math.sin(dLat / 2) ** 2 + Math.cos(lat1) * Math.cos(lat2) * Math.sin(dLon / 2) ** 2;
  return 2 * EARTH_RADIUS_KM * Math.asin(Math.sqrt(Math.min(1, h)));
}
function cartesian(lat: number, lon: number) {
  const phi = lat * RAD, lambda = lon * RAD;
  return {
    x: EARTH_RADIUS_KM * Math.cos(phi) * Math.cos(lambda),
    y: EARTH_RADIUS_KM * Math.cos(phi) * Math.sin(lambda),
    z: EARTH_RADIUS_KM * Math.sin(phi),
  };
}
function cell(value: number): number { return Math.floor(value / CELL_SIZE_KM); }

export class GeospatialAnalyzer {
  private readonly buckets = new Map<string, GeoPoint[]>();
  private readonly closePairs: ClosePair[] = [];
  private totalWithCoordinates = 0;
  private totalWithoutCoordinates = 0;
  private invalidCoordinates = 0;
  private pairs1km = 0;
  private pairs5km = 0;
  private pairs10km = 0;
  private pairs25km = 0;
  private nearestPair: ClosePair | null = null;

  add(idValue: unknown, latValue: unknown, lonValue: unknown, dateValue: unknown): void {
    const id = typeof idValue === "string" ? idValue : "";
    const lat = asCoordinate(latValue, -90, 90);
    const lon = asCoordinate(lonValue, -180, 180);
    if (lat === null || lon === null || !id) {
      this.totalWithoutCoordinates++;
      if ((latValue !== null && latValue !== undefined) || (lonValue !== null && lonValue !== undefined)) this.invalidCoordinates++;
      return;
    }
    this.totalWithCoordinates++;
    const xyz = cartesian(lat, lon);
    const point: GeoPoint = { id, lat, lon, date: typeof dateValue === "string" ? dateValue : "", ...xyz };
    const cx = cell(point.x), cy = cell(point.y), cz = cell(point.z);

    // En el espacio cartesiano, puntos a menos de 25 km solo pueden estar
    // en la misma celda o en una de las 26 celdas vecinas.
    for (let dx = -1; dx <= 1; dx++) {
      for (let dy = -1; dy <= 1; dy++) {
        for (let dz = -1; dz <= 1; dz++) {
          const nearby = this.buckets.get(`${cx + dx}:${cy + dy}:${cz + dz}`);
          if (!nearby) continue;
          for (const previous of nearby) {
            const distance = haversineKm(point, previous);
            if (distance > MAX_RADIUS_KM) continue;
            const pair: ClosePair = {
              caso_a: previous.id, caso_b: point.id,
              fecha_a: previous.date, fecha_b: point.date,
              distancia_km: Number(distance.toFixed(2)),
            };
            this.pairs25km++;
            if (distance <= 10) this.pairs10km++;
            if (distance <= 5) this.pairs5km++;
            if (distance <= 1) this.pairs1km++;
            if (!this.nearestPair || distance < this.nearestPair.distancia_km) this.nearestPair = pair;
            if (distance <= 5) {
              this.closePairs.push(pair);
              this.closePairs.sort((a, b) => a.distancia_km - b.distancia_km);
              if (this.closePairs.length > 12) this.closePairs.pop();
            }
          }
        }
      }
    }
    const key = `${cx}:${cy}:${cz}`;
    const bucket = this.buckets.get(key) || [];
    bucket.push(point);
    this.buckets.set(key, bucket);
  }

  summary() {
    return {
      metodo: "Distancia Haversine; búsqueda de vecinos mediante celdas cartesianas de 25 km",
      total_casos_con_coordenadas: this.totalWithCoordinates,
      total_casos_sin_coordenadas: this.totalWithoutCoordinates,
      coordenadas_presentes_pero_invalidas: this.invalidCoordinates,
      pares_a_menos_de_1_km: this.pairs1km,
      pares_a_menos_de_5_km: this.pairs5km,
      pares_a_menos_de_10_km: this.pairs10km,
      pares_a_menos_de_25_km: this.pairs25km,
      par_mas_cercano: this.nearestPair,
      ejemplos_pares_hasta_5_km: this.closePairs,
      nota: "Los pares son coincidencias de proximidad entre ubicaciones de incidentes. No demuestran relación causal ni identifican personas.",
    };
  }
}
