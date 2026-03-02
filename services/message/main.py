from fastapi import FastAPI
from main_router import main_router
from utils.config import load_config, rebuild_config, GET_CONFIG

load_config()
load_config("GLOBAL_DB")
rebuild_config()

app = FastAPI()

app.include_router(main_router)

import uvicorn
from main import app
from utils.config import GET_CONFIG

if __name__ == "__main__":
    config = GET_CONFIG()
    
    uvicorn.run(
        "main:app",
        host=config.get("API", "0.0.0.0"),
        port=int(config.get("PORT", 8000)),
        reload=True
    )