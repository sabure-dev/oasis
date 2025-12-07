#!/bin/bash
uv run alembic upgrade head
cd app
uv run gunicorn main:app --workers 1 --worker-class uvicorn.workers.UvicornWorker --bind=0.0.0.0:8000 --access-logfile - --log-level info --timeout 120