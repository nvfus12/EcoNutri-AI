import json
import urllib.request
from urllib.parse import quote
from src.core.config import settings

class WeatherService:
    @staticmethod
    def get_current_weather(lat: float = None, lon: float = None) -> str:
        weather_str, _ = WeatherService.get_current_weather_with_city(lat, lon)
        return weather_str

    @staticmethod
    def get_current_weather_with_city(lat: float = None, lon: float = None) -> tuple:
        if not settings.OPENWEATHER_API_KEY:
            return "Chưa cấu hình API Key", None
        if lat in (None, "") or lon in (None, ""):
            return "Không có thông tin thời tiết", None
        
        try:
            url = f"https://api.openweathermap.org/data/2.5/weather?lat={lat}&lon={lon}&appid={settings.OPENWEATHER_API_KEY}&units=metric&lang=vi"
            
            req = urllib.request.Request(url, headers={'User-Agent': 'Mozilla/5.0'})
            with urllib.request.urlopen(req, timeout=5) as response:
                if response.status == 200:
                    data = json.loads(response.read().decode())
                    desc = data['weather'][0]['description']
                    temp = data['main']['temp']
                    city_name = data.get('name', None)
                    
                    # Thêm icon thời tiết tự động
                    desc_lower = desc.lower()
                    icon = "🌡️"
                    if any(x in desc_lower for x in ["mưa", "rain", "drizzle"]):
                        icon = "🌧️"
                    elif any(x in desc_lower for x in ["mây", "cloud", "overcast"]):
                        icon = "☁️"
                    elif any(x in desc_lower for x in ["nắng", "quang", "clear", "sun"]):
                        icon = "☀️"
                    elif any(x in desc_lower for x in ["dông", "sấm", "thunderstorm"]):
                        icon = "⛈️"
                    elif any(x in desc_lower for x in ["sương", "mist", "fog"]):
                        icon = "🌫️"
                        
                    return f"{icon} {temp}°C, {desc.capitalize()}", city_name
        except Exception as e:
            err_msg = str(e)
            if "401" in err_msg:
                return "API Key mới tạo (Cần chờ 1-2h để kích hoạt)", None
            elif "404" in err_msg:
                return "Không tìm thấy địa điểm này", None
            return f"Lỗi {e.__class__.__name__}: {err_msg}", None
        
        return "Không có thông tin thời tiết", None