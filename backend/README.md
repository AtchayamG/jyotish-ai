# Jyotish AI — Backend (FastAPI)

## Architecture: Clean Architecture + Repository Pattern

```
backend/
├── app/
│   ├── api/v1/endpoints/     # Route handlers (thin layer)
│   ├── core/                 # Config, security, deps
│   ├── models/               # SQLAlchemy DB models
│   ├── schemas/              # Pydantic request/response schemas
│   ├── services/             # Business logic layer
│   ├── repositories/         # Data access layer
│   └── utils/                # Helpers (astro calculations, etc.)
├── tests/
├── .env.example
├── requirements.txt
└── main.py
```

## Key Design Decisions
- **Clean Architecture**: API → Service → Repository → DB/External API
- **Centralized HTTP client**: All external API calls via `core/http_client.py`
- **Dependency Injection**: FastAPI `Depends()` for all layers
- **JWT Auth**: Access + Refresh token pattern
- **Rate Limiting**: slowapi per-endpoint
- **Config**: Pydantic Settings, environment-driven

## Run Locally
```bash
pip install -r requirements.txt
cp .env.example .env
uvicorn main:app --reload
```

## Deploy to Render
- Runtime: Python 3.12
- Start Command: `uvicorn main:app --host 0.0.0.0 --port $PORT`
- Environment: Set all vars from .env.example
