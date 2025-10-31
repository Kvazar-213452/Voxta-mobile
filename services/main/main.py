import os
import asyncio
from contextlib import asynccontextmanager
from fastapi import FastAPI, Request, Response
from fastapi.middleware.cors import CORSMiddleware
from routes import api_routes
from config import load_config, get_config
import uvicorn
import httpx
from datetime import datetime

http_client = None

async def get_http_client():
    global http_client
    if http_client is None:
        http_client = httpx.AsyncClient(
            timeout=httpx.Timeout(10.0, connect=2.0),  # Зменшені таймаути
            limits=httpx.Limits(
                max_keepalive_connections=100,  # Більше keep-alive з'єднань
                max_connections=200,            # Більше паралельних з'єднань
                keepalive_expiry=30.0          # Тримати з'єднання довше
            ),
            follow_redirects=True
        )
    return http_client

@asynccontextmanager
async def lifespan(app: FastAPI):

    await get_http_client()
    yield

    global http_client
    if http_client:
        await http_client.aclose()

async def create_app() -> FastAPI:
    await load_config()
    config = get_config()

    app = FastAPI(lifespan=lifespan)

    app.add_middleware(
        CORSMiddleware,
        allow_origins=["*", "https://2xedbot.site"],
        allow_credentials=True,
        allow_methods=["*"],
        allow_headers=["*"],
        expose_headers=["set-cookie"],
        max_age=3600
    )

    @app.middleware("http")
    async def log_requests(request, call_next):
        print(f"[{datetime.now().strftime('%H:%M')}] {request.method} {request.url}")
        return await call_next(request)

    app.include_router(api_routes, prefix="/api")

    def create_proxy(target_base_url: str, prefix: str):
        async def proxy(request: Request):
            path = str(request.url.path)
            if path.startswith(prefix):
                path = path[len(prefix):] or "/"
            url = f"{target_base_url}{path}"

            headers = {
                k: v for k, v in request.headers.items() 
                if k.lower() not in {'host', 'content-length'}
            }

            client = await get_http_client()
            
            body_task = asyncio.create_task(request.body())
            
            try:
                body = await body_task

                resp = await client.request(
                    method=request.method,
                    url=url,
                    headers=headers,
                    params=request.query_params,
                    content=body
                )

                response_headers = {
                    k: v for k, v in resp.headers.items()
                    if k.lower() not in {'content-length', 'transfer-encoding', 'connection'}
                }

                return Response(
                    content=resp.content,
                    status_code=resp.status_code,
                    headers=response_headers
                )
                
            except httpx.TimeoutException:
                return Response(
                    content="Gateway Timeout",
                    status_code=504
                )
            except Exception as e:
                print(f"Proxy error: {e}")
                return Response(
                    content="Bad Gateway",
                    status_code=502
                )

        return proxy

    global_url = config["GLOBAL_URL"]
    proxy_map = {
        "/data": global_url["MICROSERVICES_DATA"],
        "/chat": global_url["MICROSERVICES_CHAT"],
    }

    for route_prefix, target_url in proxy_map.items():
        app.add_api_route(
            f"{route_prefix}/{{path:path}}",
            create_proxy(target_url, route_prefix + "/"),
            methods=["GET", "POST", "PUT", "DELETE", "OPTIONS"]
        )

    return app


if __name__ == "__main__":
    app = asyncio.run(create_app())
    config = get_config()
    
    uvicorn.run(
        app, 
        host=config.get("API", "127.0.0.1"), 
        port=int(config.get("PORT", 3014)),
        access_log=False
    )