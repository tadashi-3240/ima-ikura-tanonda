export type PlaceCandidate = {
  id: string
  name: string
  distanceM: number
}

export type GeoPosition = {
  latitude: number
  longitude: number
}

function haversineM(a: GeoPosition, b: GeoPosition): number {
  const toRad = (deg: number) => (deg * Math.PI) / 180
  const earth = 6371000
  const dLat = toRad(b.latitude - a.latitude)
  const dLon = toRad(b.longitude - a.longitude)
  const lat1 = toRad(a.latitude)
  const lat2 = toRad(b.latitude)
  const h =
    Math.sin(dLat / 2) ** 2 +
    Math.cos(lat1) * Math.cos(lat2) * Math.sin(dLon / 2) ** 2
  return 2 * earth * Math.asin(Math.sqrt(h))
}

export function getCurrentPosition(): Promise<GeoPosition> {
  return new Promise((resolve, reject) => {
    if (!navigator.geolocation) {
      reject(new Error('この端末では位置情報を使えません'))
      return
    }
    navigator.geolocation.getCurrentPosition(
      (pos) => {
        resolve({
          latitude: pos.coords.latitude,
          longitude: pos.coords.longitude,
        })
      },
      (err) => {
        if (err.code === err.PERMISSION_DENIED) {
          reject(new Error('位置情報の許可が必要です'))
        } else if (err.code === err.TIMEOUT) {
          reject(new Error('位置情報の取得がタイムアウトしました'))
        } else {
          reject(new Error('位置情報を取得できませんでした'))
        }
      },
      { enableHighAccuracy: true, timeout: 12000, maximumAge: 30000 },
    )
  })
}

type OverpassElement = {
  type: string
  id: number
  lat?: number
  lon?: number
  center?: { lat: number; lon: number }
  tags?: Record<string, string>
}

async function fetchOverpass(position: GeoPosition, signal?: AbortSignal): Promise<PlaceCandidate[]> {
  const { latitude: lat, longitude: lon } = position
  const radius = 120
  const query = `
[out:json][timeout:15];
(
  node["amenity"~"^(restaurant|cafe|bar|fast_food|pub|biergarten|food_court)$"](around:${radius},${lat},${lon});
  way["amenity"~"^(restaurant|cafe|bar|fast_food|pub|biergarten|food_court)$"](around:${radius},${lat},${lon});
  node["leisure"="karaoke_box"](around:${radius},${lat},${lon});
  way["leisure"="karaoke_box"](around:${radius},${lat},${lon});
  node["tourism"~"^(hotel|guest_house)$"](around:${radius},${lat},${lon});
);
out center tags 20;
`.trim()

  const response = await fetch('https://overpass-api.de/api/interpreter', {
    method: 'POST',
    headers: { 'Content-Type': 'application/x-www-form-urlencoded;charset=UTF-8' },
    body: `data=${encodeURIComponent(query)}`,
    signal,
  })
  if (!response.ok) throw new Error('近くの店を検索できませんでした')
  const data = (await response.json()) as { elements?: OverpassElement[] }
  const seen = new Set<string>()
  const candidates: PlaceCandidate[] = []

  for (const el of data.elements ?? []) {
    const name = el.tags?.['name:ja'] || el.tags?.name
    if (!name) continue
    const key = name.trim()
    if (seen.has(key)) continue
    seen.add(key)
    const elLat = el.lat ?? el.center?.lat
    const elLon = el.lon ?? el.center?.lon
    if (elLat == null || elLon == null) continue
    candidates.push({
      id: `${el.type}/${el.id}`,
      name: key,
      distanceM: Math.round(haversineM(position, { latitude: elLat, longitude: elLon })),
    })
  }

  return candidates.sort((a, b) => a.distanceM - b.distanceM).slice(0, 5)
}

async function fetchNominatimFallback(
  position: GeoPosition,
  signal?: AbortSignal,
): Promise<PlaceCandidate[]> {
  const url = new URL('https://nominatim.openstreetmap.org/reverse')
  url.searchParams.set('format', 'jsonv2')
  url.searchParams.set('lat', String(position.latitude))
  url.searchParams.set('lon', String(position.longitude))
  url.searchParams.set('zoom', '18')
  url.searchParams.set('addressdetails', '0')

  const response = await fetch(url, {
    headers: { Accept: 'application/json' },
    signal,
  })
  if (!response.ok) return []
  const data = (await response.json()) as { name?: string; display_name?: string }
  const name = data.name?.trim()
  if (!name || name.length < 2) return []
  return [{ id: 'nominatim', name, distanceM: 0 }]
}

export async function findNearbyPlaces(
  position: GeoPosition,
  signal?: AbortSignal,
): Promise<PlaceCandidate[]> {
  try {
    const nearby = await fetchOverpass(position, signal)
    if (nearby.length > 0) return nearby
  } catch {
    // fall through
  }
  return fetchNominatimFallback(position, signal)
}

export async function searchNearbyPlaces(signal?: AbortSignal): Promise<PlaceCandidate[]> {
  const position = await getCurrentPosition()
  return findNearbyPlaces(position, signal)
}
