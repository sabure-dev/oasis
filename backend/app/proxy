from fastapi import FastAPI, HTTPException, Request
from fastapi.responses import Response, JSONResponse
import httpx
from urllib.parse import urljoin
import logging

app = FastAPI(title="Yeet Proxy API")
TARGET_BASE_URL = "https://dab.yeet.su"

# Настройка логирования
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

@app.api_route("/{path:path}", methods=["GET", "POST", "PUT", "DELETE", "PATCH", "OPTIONS", "HEAD"])
async def proxy_request(path: str, request: Request):
    """
    Прокси-эндпоинт, который перенаправляет все запросы на целевой сервер dab.yeet.su
    """
    try:
        # Формируем целевой URL
        target_url = urljoin(TARGET_BASE_URL, path)
        
        # Получаем параметры запроса
        params = dict(request.query_params)
        
        # Получаем тело запроса (если есть)
        body = None
        if await request.body():
            body = await request.body()
        
        # Получаем заголовки запроса
        headers = {}
        for key, value in request.headers.items():
            # Исключаем некоторые заголовки, которые могут мешать
            if key.lower() not in ['host', 'content-length', 'connection']:
                headers[key] = value
        
        # Устанавливаем правильный Host-заголовок для целевого сервера
        headers['Host'] = 'dab.yeet.su'
        
        # Создаем клиент HTTPX с таймаутами
        async with httpx.AsyncClient() as client:
            # Выполняем запрос к целевому серверу
            response = await client.request(
                method=request.method,
                url=target_url,
                params=params,
                content=body,
                headers=headers,
                timeout=30.0
            )
            
            # Возвращаем ответ от целевого сервера
            return Response(
                content=response.content,
                status_code=response.status_code,
                headers=dict(response.headers),
                media_type=response.headers.get('content-type')
            )
            
    except httpx.TimeoutException:
        logger.error("Таймаут при запросе к целевому серверу")
        return JSONResponse(
            status_code=504,
            content={"error": "Таймаут при обращении к целевому серверу"}
        )
    except httpx.RequestError as e:
        logger.error(f"Ошибка при запросе к целевому серверу: {str(e)}")
        return JSONResponse(
            status_code=502,
            content={"error": f"Ошибка при обращении к целевому серверу: {str(e)}"}
        )
    except Exception as e:
        logger.error(f"Неожиданная ошибка: {str(e)}")
        return JSONResponse(
            status_code=500,
            content={"error": f"Внутренняя ошибка сервера: {str(e)}"}
        )

@app.get("/")
async def root():
    return {"message": "Прокси-сервер для dab.yeet.su", "status": "active"}

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8000)
