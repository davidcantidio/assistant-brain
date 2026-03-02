from __future__ import annotations

import uvicorn

from ops_api.app import create_app


def main() -> int:
    uvicorn.run(create_app(), host="127.0.0.1", port=18901)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
