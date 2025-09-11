from fastapi import FastAPI

from backend.app.api import api_router

app = FastAPI(
    title="Oasis API",
    root_path="/api/v1"
)

app.include_router(api_router)
