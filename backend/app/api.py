from fastapi import APIRouter

api_router = APIRouter()


@api_router.get("/healthcheck")
async def healthcheck():
    return {"status": "healthy"}
