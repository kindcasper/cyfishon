#!/usr/bin/env python3
"""
Демо-версия скрипта для загрузки ключевых тайлов карты Кипра
"""

import os
import requests
import time
import math
from pathlib import Path

# Границы Кипра (более узкая область для демо)
MIN_LAT = 34.8
MAX_LAT = 35.4
MIN_LNG = 32.5
MAX_LNG = 34.2

# Уровни зума для загрузки (только основные)
MIN_ZOOM = 8
MAX_ZOOM = 12

# URL шаблон для OpenStreetMap
TILE_URL = "https://tile.openstreetmap.org/{z}/{x}/{y}.png"

# Директория для сохранения тайлов
TILES_DIR = Path("../assets/tiles")

# User-Agent для запросов
USER_AGENT = "CyFishON/1.0 (Offline Map Downloader Demo)"

def deg2num(lat_deg, lon_deg, zoom):
    """Конвертация координат в номера тайлов"""
    lat_rad = math.radians(lat_deg)
    n = 2.0 ** zoom
    x = int((lon_deg + 180.0) / 360.0 * n)
    y = int((1.0 - math.asinh(math.tan(lat_rad)) / math.pi) / 2.0 * n)
    return (x, y)

def download_tile(x, y, z, session):
    """Загрузка одного тайла"""
    url = TILE_URL.format(x=x, y=y, z=z)
    
    # Создаем директорию для тайла
    tile_dir = TILES_DIR / str(z) / str(x)
    tile_dir.mkdir(parents=True, exist_ok=True)
    
    tile_path = tile_dir / f"{y}.png"
    
    # Пропускаем если файл уже существует
    if tile_path.exists():
        print(f"⏭️  Пропущен тайл {z}/{x}/{y} (уже существует)")
        return True
    
    try:
        response = session.get(url, timeout=10)
        response.raise_for_status()
        
        with open(tile_path, 'wb') as f:
            f.write(response.content)
        
        print(f"✅ Загружен тайл {z}/{x}/{y}")
        return True
        
    except Exception as e:
        print(f"❌ Ошибка загрузки тайла {z}/{x}/{y}: {e}")
        return False

def main():
    """Основная функция загрузки"""
    print("🗺️  Демо-загрузка ключевых тайлов карты Кипра")
    print(f"📍 Область: {MIN_LAT}°-{MAX_LAT}°N, {MIN_LNG}°-{MAX_LNG}°E")
    print(f"🔍 Зум: {MIN_ZOOM}-{MAX_ZOOM}")
    
    # Создаем директорию для тайлов
    TILES_DIR.mkdir(parents=True, exist_ok=True)
    
    # Создаем сессию с настройками
    session = requests.Session()
    session.headers.update({
        'User-Agent': USER_AGENT,
        'Accept': 'image/png,image/*;q=0.8,*/*;q=0.5',
        'Accept-Language': 'en-US,en;q=0.5',
        'Accept-Encoding': 'gzip, deflate',
        'Connection': 'keep-alive',
    })
    
    total_tiles = 0
    downloaded_tiles = 0
    
    # Подсчитываем общее количество тайлов
    for zoom in range(MIN_ZOOM, MAX_ZOOM + 1):
        min_x, max_y = deg2num(MIN_LAT, MIN_LNG, zoom)
        max_x, min_y = deg2num(MAX_LAT, MAX_LNG, zoom)
        
        for x in range(min_x, max_x + 1):
            for y in range(min_y, max_y + 1):
                total_tiles += 1
    
    print(f"📊 Всего тайлов для загрузки: {total_tiles}")
    
    # Загружаем тайлы
    for zoom in range(MIN_ZOOM, MAX_ZOOM + 1):
        print(f"\n🔍 Загрузка зума {zoom}...")
        
        min_x, max_y = deg2num(MIN_LAT, MIN_LNG, zoom)
        max_x, min_y = deg2num(MAX_LAT, MAX_LNG, zoom)
        
        zoom_tiles = 0
        zoom_downloaded = 0
        
        for x in range(min_x, max_x + 1):
            for y in range(min_y, max_y + 1):
                zoom_tiles += 1
                
                if download_tile(x, y, zoom, session):
                    zoom_downloaded += 1
                    downloaded_tiles += 1
                
                # Небольшая задержка чтобы не перегружать сервер
                time.sleep(0.2)
                
                # Показываем прогресс каждые 10 тайлов
                if zoom_tiles % 10 == 0:
                    progress = (downloaded_tiles / total_tiles) * 100
                    print(f"📈 Прогресс: {progress:.1f}% ({downloaded_tiles}/{total_tiles})")
        
        print(f"✅ Зум {zoom}: {zoom_downloaded}/{zoom_tiles} тайлов")
    
    print(f"\n🎉 Демо-загрузка завершена!")
    print(f"📊 Загружено: {downloaded_tiles}/{total_tiles} тайлов")
    
    # Подсчитываем размер
    total_size = 0
    for tile_file in TILES_DIR.rglob("*.png"):
        total_size += tile_file.stat().st_size
    
    size_mb = total_size / (1024 * 1024)
    print(f"💾 Общий размер: {size_mb:.1f} МБ")
    
    # Создаем файл с информацией о загрузке
    info_file = TILES_DIR / "demo_info.txt"
    with open(info_file, 'w', encoding='utf-8') as f:
        f.write(f"Демо тайлы карты Кипра\n")
        f.write(f"Область: {MIN_LAT}°-{MAX_LAT}°N, {MIN_LNG}°-{MAX_LNG}°E\n")
        f.write(f"Зум: {MIN_ZOOM}-{MAX_ZOOM}\n")
        f.write(f"Загружено тайлов: {downloaded_tiles}\n")
        f.write(f"Размер: {size_mb:.1f} МБ\n")
        f.write(f"Источник: OpenStreetMap\n")
        f.write(f"Дата загрузки: {time.strftime('%Y-%m-%d %H:%M:%S')}\n")
    
    print(f"📝 Информация сохранена в {info_file}")

if __name__ == "__main__":
    main()
