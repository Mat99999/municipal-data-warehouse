FROM ghcr.io/astral-sh/uv:0.11.29 AS uv
FROM python:3.12-slim AS runtime
COPY --from=uv /uv /uvx /bin/
ENV PYTHONDONTWRITEBYTECODE=1 PYTHONUNBUFFERED=1 UV_LINK_MODE=copy
WORKDIR /app
COPY pyproject.toml uv.lock README.md ./
RUN uv sync --frozen --all-extras --no-install-project
COPY src ./src
COPY . .
RUN uv sync --frozen --all-extras
ENV PATH="/app/.venv/bin:$PATH"
ENTRYPOINT ["municipal-dw"]
