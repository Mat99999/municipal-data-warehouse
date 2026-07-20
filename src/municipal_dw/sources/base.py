from collections.abc import Mapping
from typing import Any

import httpx
from tenacity import retry, retry_if_exception, stop_after_attempt, wait_exponential_jitter


def _retryable(exc: BaseException) -> bool:
    if isinstance(exc, (httpx.TimeoutException, httpx.NetworkError)):
        return True
    return isinstance(exc, httpx.HTTPStatusError) and (
        exc.response.status_code == 429 or exc.response.status_code >= 500
    )


class HttpSource:
    def __init__(self, base_url: str, timeout: float = 60.0) -> None:
        self.client = httpx.Client(
            base_url=base_url.rstrip("/"),
            timeout=timeout,
            headers={"User-Agent": "municipal-data-warehouse/1.0"},
            follow_redirects=True,
        )

    @retry(
        stop=stop_after_attempt(5),
        wait=wait_exponential_jitter(initial=1, max=20),
        retry=retry_if_exception(_retryable),
        reraise=True,
    )
    def get(self, path: str, params: Mapping[str, Any] | None = None) -> httpx.Response:
        response = self.client.get(path, params=params)
        response.raise_for_status()
        return response

    @retry(
        stop=stop_after_attempt(5),
        wait=wait_exponential_jitter(initial=1, max=20),
        retry=retry_if_exception(_retryable),
        reraise=True,
    )
    def post(self, path: str, json: Any) -> httpx.Response:
        response = self.client.post(path, json=json)
        response.raise_for_status()
        return response
