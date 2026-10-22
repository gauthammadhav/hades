"""FastAPI application factory for HADES Core."""

from contextlib import asynccontextmanager
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from hades.api.routes import router, start_device_monitor


@asynccontextmanager
async def _lifespan(app: FastAPI):
    """Start background tasks on startup."""
    start_device_monitor()
    yield


def create_app() -> FastAPI:
    """Create and configure the HADES Core FastAPI application."""
    app = FastAPI(
        title="HADES Core Control Plane API",
        version="0.1.0",
        description="Hardware-Aware Development Sandbox API for Flutter Desktop Integration",
        lifespan=_lifespan,
    )

    # Enable CORS for desktop and web presentation clients
    app.add_middleware(
        CORSMiddleware,
        allow_origins=["*"],
        allow_credentials=True,
        allow_methods=["*"],
        allow_headers=["*"],
    )

    app.include_router(router)

    @app.get("/")
    def root():
        return {
            "name": "HADES Core Control Plane API",
            "version": "0.1.0",
            "docs": "/docs",
            "health": "/v1/health",
        }

    return app


app = create_app()

