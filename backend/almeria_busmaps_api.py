from flask import Flask, jsonify, request
from flask_cors import CORS
import pandas as pd
import json
import os
import random
import time

app = Flask(__name__)
CORS(app)

# Store (lineId, stopId) -> {"initial_minutes": X, "assigned_at": timestamp}
_arrival_times_cache = {}

def _get_remaining_minutes(line_id: str, stop_id: str, now_ts=None) -> int:
    """Retorna los minutos restantes para una (línea, parada) usando cache en memoria.

    - O(1) por consulta.
    - No realiza lecturas de disco.
    """
    if now_ts is None:
        now_ts = time.time()

    key = f"{line_id}:{stop_id}"

    # Primera llamada: asignar tiempo aleatorio
    if key not in _arrival_times_cache:
        _arrival_times_cache[key] = {
            "initial_minutes": random.randint(1, 20),
            "assigned_at": now_ts,
        }

    cache_entry = _arrival_times_cache[key]
    initial_minutes = cache_entry["initial_minutes"]
    assigned_at = cache_entry["assigned_at"]

    elapsed_seconds = now_ts - assigned_at
    elapsed_minutes = int(elapsed_seconds // 60)

    remaining = initial_minutes - elapsed_minutes

    # Si llega a 0 o menos, reiniciar
    if remaining <= 0:
        _arrival_times_cache[key]["assigned_at"] = now_ts
        remaining = initial_minutes

    return int(remaining)

def _clean_id(val):
    """Limpia los IDs para que el CSV y el JSON coincidan perfectamente (ej: 404.0 -> '404')"""
    if pd.isna(val): return ""
    try:
        return str(int(float(val)))
    except ValueError:
        return str(val).strip()

def get_zone_by_location(lat, lon):
    if 36.838 <= lat <= 36.845 and -2.470 <= lon <= -2.450: return "Centro"
    elif lat <= 36.830 and lon >= -2.410: return "Este"
    elif lat >= 36.860: return "Norte"
    elif lon <= -2.465: return "Oeste"
    return "A"



class PerfectBusClient:
    def __init__(self):
        base_dir = os.path.dirname(__file__)
        paradas_csv_path = os.path.join(base_dir, "Paradas.csv")
        json_path = os.path.join(base_dir, "todas_las_lineas.json") # O el nombre que tenga tu JSON
        
        
        # 1. CARGAMOS LAS COORDENADAS EXACTAS 
        self.local_stops = {}
        try:
            df_paradas = pd.read_csv(paradas_csv_path, sep=';', encoding='utf-8-sig')
            for _, row in df_paradas.iterrows():
                pid = _clean_id(row['numero'])
                if not pid: continue
                
                lat = float(str(row['latitud']).replace(',', '.'))
                lon = float(str(row['longitud']).replace(',', '.'))
                
                self.local_stops[pid] = {
                    "id": pid,
                    "name": str(row['nombre']).strip().title(), # Ponemos el nombre correctamente capitalizado
                    "lat": lat,
                    "lon": lon,
                    "zone": get_zone_by_location(lat, lon)
                }
            print(f" {len(self.local_stops)} coordenadas exactas cargadas")
        except Exception as e:
            print(f" Error leyendo Paradas.csv: {e}")

        # 2. Cargamos el JSON con el orden correcto de las paradas para cada línea (sin importar si el JSON tiene coordenadas o no, solo el orden y la relación línea-parada)

        try:
            with open(json_path, 'r', encoding='utf-8') as f:
                scraped_data = json.load(f)
        except Exception as e:
            print(f" Error leyendo JSON: {e}")
            scraped_data = {"lineas": []}

        # 3. FUSIONAMOS
        self.lineas_data = []
        for linea_json in scraped_data.get("lineas", []):
            line_id = linea_json.get("linea") # Ej: "L18"
            
            ordered_stops = []
            ordered_routes = []
            ruta_nombre_largo = f"Línea {line_id}"
            
            # Recorremos ida y vuelta en el orden del JSON.
            for idx, ruta in enumerate(linea_json.get("rutas", [])):
                # Guardamos el nombre de la primera ruta como nombre largo de la línea
                if idx == 0 and ruta.get("ruta"):
                    ruta_nombre_largo = str(ruta.get("ruta")).title()

                route_stops = []
                for parada in ruta.get("paradas", []):
                    pid = _clean_id(parada.get("id"))
                    
                    # Buscamos el ID del JSON en nuestro CSV local
                    coordenadas_reales = self.local_stops.get(pid)
                    
                    if coordenadas_reales:
                        route_stops.append(coordenadas_reales)
                    else:
                        nombre_parada = parada.get('nombre', 'Sin nombre')
                        print(f" Parada {pid} ({nombre_parada}) de la {line_id} existe en el JSON pero no en Paradas.csv")

                if route_stops:
                    ordered_routes.append({
                        "name": str(ruta.get("ruta") or f"Ruta {idx + 1}").title(),
                        "stops": route_stops,
                    })
                    ordered_stops.extend(route_stops)
            
            if ordered_stops:
                self.lineas_data.append({
                    "id": line_id,
                    "name": line_id,
                    "fullName": ruta_nombre_largo,
                    "description": f"Servicio urbano Almería",
                    "totalStops": len(ordered_stops),
                    "routes": ordered_routes,
                    "stops": ordered_stops
                })

        print(f" ¡Éxito! {len(self.lineas_data)} líneas generadas con 100% de precisión.")

        # 4. Indexes para lookups O(1)
        self.lines_by_id = {line["id"]: line for line in self.lineas_data}
        self.stop_to_lines = {}
        for line in self.lineas_data:
            line_id = line["id"]
            for stop in line.get("stops", []):
                sid = stop.get("id")
                if not sid:
                    continue
                self.stop_to_lines.setdefault(sid, set()).add(line_id)

client = PerfectBusClient()

# --- RUTAS DE LA API FLASK ---

@app.route('/lines')
def get_lines():
    return jsonify(client.lineas_data)

@app.route('/lines/<line_id>/stops')
def get_line_stops(line_id):
    line = client.lines_by_id.get(line_id)
    if not line:
        return jsonify([])
    return jsonify(line.get('routes', line['stops']))

@app.route('/lines/<line_id>/arrivals')
def get_line_arrivals(line_id):
    """Arrivals con tiempos fijos que cuentan hacia atrás y se reinician"""
    arrivals_list = []
    line = client.lines_by_id.get(line_id)
    if not line:
        return jsonify({"arrivals": []}), 200

    now_ts = time.time()
    arrivals_list = []
    for stop in line.get('stops', []):
        sid = stop.get('id')
        if not sid:
            continue
        remaining = _get_remaining_minutes(line_id=line_id, stop_id=sid, now_ts=now_ts)
        arrivals_list.append({
            "stopId": sid,
            "minutes": remaining,
        })

    return jsonify({"arrivals": arrivals_list}), 200


@app.route('/stops/<stop_id>/arrivals')
def get_stop_arrivals(stop_id):
    """Arrivals por parada.

    Respuesta: lista de {lineId, minutes}.

    Query params:
    - limit: int (default 3)
    - lineId: opcional; si viene, retorna solo esa línea (si pasa por la parada)
    """
    limit_raw = request.args.get('limit', '3')
    limit = int(limit_raw) if str(limit_raw).isdigit() else 3
    limit = max(1, min(limit, 50))

    only_line_id = request.args.get('lineId')
    now_ts = time.time()

    lines_for_stop = client.stop_to_lines.get(stop_id, set())
    if only_line_id:
        if only_line_id in lines_for_stop:
            minutes = _get_remaining_minutes(line_id=only_line_id, stop_id=stop_id, now_ts=now_ts)
            return jsonify([{"lineId": only_line_id, "minutes": minutes}]), 200
        return jsonify([]), 200

    items = []
    for line_id in lines_for_stop:
        minutes = _get_remaining_minutes(line_id=line_id, stop_id=stop_id, now_ts=now_ts)
        items.append({"lineId": line_id, "minutes": minutes})

    items.sort(key=lambda x: x.get('minutes', 10**9))
    return jsonify(items[:limit]), 200

@app.route('/stops/<stop_id>')
def get_stop_detail(stop_id):
    if stop_id in client.local_stops:
        data = client.local_stops[stop_id].copy()
        data["arrivals"] = [
            {"lineId": "L2", "minutes": random.randint(2, 5)},
            {"lineId": "L18", "minutes": random.randint(8, 15)}
        ]
        return jsonify(data)
    return jsonify({"error": "Parada no encontrada"}), 404

if __name__ == '__main__':
    print(" Iniciando API de Almería buses")
    app.run(debug=True, host='0.0.0.0', port=5000)