from fastapi import Request
from fastapi.responses import JSONResponse
from config import get_config

class ConfigController:
    @staticmethod
    async def config_give(request: Request):
        try:
            body = await request.json()
            name = body.get("name")
            if not name:
                return JSONResponse(status_code=400, content={"error": "Field 'name' is required"})

            config = get_config()
            if name not in config:
                return JSONResponse(status_code=404, content={"error": f"Config '{name}' not found"})

            return JSONResponse(status_code=200, content={"status": 1, "config": config[name]})
        except Exception as e:
            print("ConfigController.config_give error:", e)
            return JSONResponse(status_code=500, content={"error": "Internal server error"})
