from fastapi import FastAPI, Depends

from app.config import get_settings, Settings


app = FastAPI()


@app.get("/")
def root(settings: Settings = Depends(get_settings)):
    return {
        "version": "0.0.0",
        "environment": settings.environment,
        "testing": settings.testing
    }
