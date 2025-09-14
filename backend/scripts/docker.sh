#!/bin/bash
cd app
uv run gunicorn proxy:app --workers 1 --worker-class uvicorn.workers.UvicornWorker --bind=0.0.0.0:8000 --access-logfile - --log-level info --timeout 120
