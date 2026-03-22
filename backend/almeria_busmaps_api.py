from flask import Flask, jsonify, request
from flask_cors import CORS
import os
import zipfile
import pandas as pd
from datetime import datetime

app = Flask(__name__)
CORS(app)

import pandas as pd

def normalize_stop_id(stop_id):
    if pd.isna(stop_id):
        return None
    # quitar letras (E000..., S000...)
    stop_id = ''.join(filter(str.isdigit, str(stop_id)))
    return str(int(stop_id))

def get_zone_by_location(lat, lon):
    """Determina zona basada en ubicación geográfica"""
    # Centro histórico
    if 36.838 <= lat <= 36.845 and -2.470 <= lon <= -2.450:
        return "Centro"
    # Universidad/Este
    elif lat <= 36.830 and lon >= -2.410:
        return "Este"
    # Hospital/Norte
    elif lat >= 36.860:
        return "Norte"
    # Zona oeste
    elif lon <= -2.465:
        return "Oeste"
    else:
        return "A"

def clean_route_name(name: str) -> str:
    if not name:
        return ""
    return name.replace("ALSA - ", "").strip()


def parse_gtfs_time_to_seconds(time_str):
    """Parses GTFS HH:MM:SS (supports HH>=24) into seconds from service day start."""
    if pd.isna(time_str):
        return None
    try:
        hh, mm, ss = str(time_str).split(':')
        return int(hh) * 3600 + int(mm) * 60 + int(ss)
    except Exception:
        return None

class BusMapsClient:
    def __init__(self):
        gtfs_path = os.path.join(os.path.dirname(__file__), "alsa-autobuses.zip")
        
        with zipfile.ZipFile(gtfs_path) as z:
            self.routes = pd.read_csv(z.open("routes.txt"))
            self.stops = pd.read_csv(z.open("stops.txt"))
            self.trips = pd.read_csv(z.open("trips.txt"))
            self.stop_times = pd.read_csv(z.open("stop_times.txt"))
        
        print(f"Total stops GTFS: {len(self.stops)}")
        
        # Normalizar stop_ids en ambos datasets
        self.stops['stop_id_norm'] = self.stops['stop_id'].apply(normalize_stop_id)
        self.stop_times['stop_id_norm'] = self.stop_times['stop_id'].apply(normalize_stop_id)
        
        # Identificar paradas de Almería por coordenadas geográficas (método correcto)
        almeria_stops = self.stops[
            (self.stops['stop_lat'].between(36.75, 36.90)) &
            (self.stops['stop_lon'].between(-2.55, -2.35))
        ]
        
        print(f"Paradas reales de Almería: {len(almeria_stops)}")
        
        if len(almeria_stops) > 0:
            print("Ejemplos de paradas en Almería:")
            print(almeria_stops[['stop_id', 'stop_name', 'stop_lat', 'stop_lon']].head())
            almeria_stop_ids = set(almeria_stops['stop_id_norm'])
        else:
            print("No se encontraron paradas en Almería")
            almeria_stop_ids = set()
        
        print(f"Paradas identificadas en Almería: {len(almeria_stop_ids)}")
        print(f"Ejemplo stop_ids normalizados: {list(almeria_stop_ids)[:5]}")
        
        # Detectar líneas urbanas de Almería específicamente
        # Usar los route_ids conocidos de Almería del GTFS
        almeria_route_ids = {
            2330, 2331, 2333, 2334, 2335, 2336, 2337, 2338, 2339, 2340, 
            2341, 2344, 2487, 2488, 3561, 3562
        }
        
        self.urban_routes_almeria = self.routes[
            self.routes['route_id'].isin(almeria_route_ids)
        ]
        
        print(f"Líneas urbanas de Almería detectadas: {len(self.urban_routes_almeria)}")
        if len(self.urban_routes_almeria) > 0:
            print("Ejemplos de líneas urbanas:")
            print(self.urban_routes_almeria[['route_id', 'route_short_name', 'route_long_name']].head())
        
        # Cache para líneas
        self.lines_cache = None
        self.line_arrivals_cache = {}

        self.urban_routes_almeria = self.urban_routes_almeria.copy()
        self.urban_routes_almeria['line_id'] = self.urban_routes_almeria['route_short_name'].apply(clean_route_name)

        # Mapa route_id -> line_id
        self.route_to_line = dict(
            zip(self.urban_routes_almeria['route_id'], self.urban_routes_almeria['line_id'])
        )

        # stop_times enriquecido para calcular llegadas programadas
        trip_routes = self.trips[['trip_id', 'route_id']]
        st = self.stop_times[['trip_id', 'stop_id_norm', 'arrival_time']].copy()
        st = st.merge(trip_routes, on='trip_id', how='inner')
        st = st[st['route_id'].isin(set(self.urban_routes_almeria['route_id']))]
        st['line_id'] = st['route_id'].map(self.route_to_line)
        st['arrival_seconds'] = st['arrival_time'].apply(parse_gtfs_time_to_seconds)
        st = st[st['arrival_seconds'].notna() & st['line_id'].notna() & st['stop_id_norm'].notna()]
        self.stop_times_with_line = st[['line_id', 'stop_id_norm', 'arrival_seconds']]

    def get_almeria_lines(self):
        """Obtiene todas las líneas urbanas de Almería"""
        if self.lines_cache is not None:
            return self.lines_cache
            
        lines = []
        
        for _, route in self.urban_routes_almeria.iterrows():
            short_name = clean_route_name(route['route_short_name'])
            long_name = route.get('route_long_name', short_name)
            
            print(f"Procesando línea urbana: {short_name} - {long_name}")
            
            # Obtener trips de esta ruta (uno por dirección)
            route_trips = self.trips[self.trips['route_id'] == route['route_id']]
            print(f"  Trips encontrados para {short_name}: {len(route_trips)}")
            
            if len(route_trips) == 0:
                print(f"  ⚠️ No hay trips para {short_name}")
                continue
                
            route_trips = route_trips.groupby('direction_id').head(1)
            print(f"  Trips después de agrupar: {len(route_trips)}")
            
            stops_for_route = []

            for _, trip in route_trips.iterrows():
                print(f"    Procesando trip: {trip['trip_id']}")
                # Obtener paradas del trip
                trip_stops = self.stop_times[self.stop_times['trip_id'] == trip['trip_id']].copy()
                print(f"    Paradas en stop_times: {len(trip_stops)}")
                
                if len(trip_stops) == 0:
                    print(f"    ⚠️ No hay paradas en stop_times para trip {trip['trip_id']}")
                    continue
                    
                trip_stops = trip_stops.merge(
                    self.stops,
                    on='stop_id_norm',
                    how='left'
                ).sort_values('stop_sequence')
                
                trip_stops = trip_stops[trip_stops['stop_name'].notna()]
                print(f"    Paradas después del merge: {len(trip_stops)}")
                
                for _, s in trip_stops.iterrows():
                    stops_for_route.append({
                        "id": s['stop_id_norm'],
                        "name": s['stop_name'],
                        "lat": s['stop_lat'],
                        "lon": s['stop_lon'],
                        "zone": get_zone_by_location(s['stop_lat'], s['stop_lon'])
                    })

            # Eliminar duplicados y mantener orden
            seen = set()
            unique_stops = []
            for s in stops_for_route:
                if s['id'] not in seen:
                    seen.add(s['id'])
                    unique_stops.append(s)

            lines.append({
                "id": short_name,
                "name": short_name,
                "fullName": clean_route_name(long_name),
                "description": route.get('route_desc', '') if pd.notna(route.get('route_desc')) else '',
                "color": f"#{route.get('route_color', '002786')}",
                "frequency": "15-30 min",
                "firstService": "06:30",
                "lastService": "22:30",
                "totalStops": len(unique_stops),
                "stops": unique_stops
            })

        print(f"Total líneas urbanas procesadas: {len(lines)}")
        self.lines_cache = lines
        return lines

    def _now_seconds_service_day(self):
        now = datetime.now()
        return now.hour * 3600 + now.minute * 60 + now.second

    def get_line_arrivals(self, line_id):
        """Devuelve próxima llegada programada por parada para una línea (GTFS estático)."""
        cache_key = (line_id, datetime.now().strftime('%Y%m%d%H%M'))
        if cache_key in self.line_arrivals_cache:
            return self.line_arrivals_cache[cache_key]

        df = self.stop_times_with_line[self.stop_times_with_line['line_id'] == line_id]
        if df.empty:
            return {"lineId": line_id, "arrivals": []}

        now_seconds = self._now_seconds_service_day()
        work = df.copy()
        work['delta_seconds'] = work['arrival_seconds'] - now_seconds
        work.loc[work['delta_seconds'] < 0, 'delta_seconds'] += 86400

        min_by_stop = work.groupby('stop_id_norm', as_index=False)['delta_seconds'].min()
        min_by_stop['minutes'] = (min_by_stop['delta_seconds'] / 60).apply(lambda x: int(x) if x >= 1 else 1)

        result = {
            "lineId": line_id,
            "generatedAt": datetime.now().isoformat(),
            "arrivals": [
                {"stopId": str(row['stop_id_norm']), "minutes": int(row['minutes'])}
                for _, row in min_by_stop.iterrows()
            ],
        }

        self.line_arrivals_cache = {cache_key: result}
        return result

    def get_stop_arrivals(self, stop_id, limit=3):
        """Devuelve próximas llegadas programadas por línea para una parada."""
        stop_id_norm = normalize_stop_id(stop_id)
        if stop_id_norm is None:
            return []

        df = self.stop_times_with_line[self.stop_times_with_line['stop_id_norm'] == stop_id_norm]
        if df.empty:
            return []

        now_seconds = self._now_seconds_service_day()
        work = df.copy()
        work['delta_seconds'] = work['arrival_seconds'] - now_seconds
        work.loc[work['delta_seconds'] < 0, 'delta_seconds'] += 86400

        min_by_line = work.groupby('line_id', as_index=False)['delta_seconds'].min()
        min_by_line = min_by_line.sort_values('delta_seconds').head(limit)
        min_by_line['minutes'] = (min_by_line['delta_seconds'] / 60).apply(lambda x: int(x) if x >= 1 else 1)

        return [
            {
                "lineId": row['line_id'],
                "minutes": int(row['minutes']),
            }
            for _, row in min_by_line.iterrows()
        ]

client = BusMapsClient()

@app.route('/lines')
def get_lines():
    """Devuelve todas las líneas de Almería con paradas reales desde GTFS"""
    return jsonify(client.get_almeria_lines())

@app.route('/lines/<line_id>/stops')
def get_line_stops(line_id):
    """Obtiene paradas de una línea específica"""
    print(f"Buscando paradas para línea: {line_id}")
    lines = client.get_almeria_lines()
    print(f"Líneas disponibles: {[line['id'] for line in lines]}")
    
    for line in lines:
        if line['id'] == line_id:
            print(f"Línea encontrada: {line['id']}, paradas: {len(line['stops'])}")
            return jsonify(line['stops'])
    
    print(f"Línea {line_id} no encontrada")
    return jsonify([])

@app.route('/stops/<stop_id>')
def get_stop_detail(stop_id):
    """Obtiene detalles de una parada"""
    return jsonify({
        "id": stop_id,
        "name": f"Parada {stop_id}",
        "lat": 36.8381,
        "lon": -2.4597,
        "zone": "A",
        "arrivals": client.get_stop_arrivals(stop_id)
    })


@app.route('/lines/<line_id>/arrivals')
def get_line_arrivals(line_id):
    """Obtiene próxima llegada programada por parada para una línea."""
    return jsonify(client.get_line_arrivals(line_id))


@app.route('/stops/<stop_id>/arrivals')
def get_stop_arrivals(stop_id):
    """Obtiene próximas llegadas programadas por línea para una parada."""
    limit = request.args.get('limit', default=3, type=int)
    return jsonify(client.get_stop_arrivals(stop_id, limit=limit))

if __name__ == '__main__':
    print("Iniciando API de Almería con datos GTFS reales...")
    app.run(debug=True, host='0.0.0.0', port=5000)