#!/usr/bin/env python3
"""
Navigate to a page with Playwright and emit a small JSON summary.
"""

from __future__ import annotations

import argparse
import json
import sys
from pathlib import Path


def parse_bool(value: str) -> bool:
    lowered = value.strip().lower()
    if lowered in {"true", "1", "yes", "y"}:
        return True
    if lowered in {"false", "0", "no", "n"}:
        return False
    raise argparse.ArgumentTypeError(f"Invalid boolean value: {value}")


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(description="Navigate with Playwright and print JSON output.")
    parser.add_argument("--url", required=True, help="Target URL")
    parser.add_argument("--wait-until", default="networkidle", choices=["load", "domcontentloaded", "networkidle", "commit"])
    parser.add_argument("--timeout", type=int, default=30000, help="Navigation timeout in milliseconds")
    parser.add_argument("--headless", type=parse_bool, default=True, help="Launch browser headless")
    parser.add_argument("--screenshot", help="Optional screenshot output path")
    parser.add_argument("--text-selector", help="Optional selector to extract text from")
    return parser


def main() -> int:
    parser = build_parser()
    args = parser.parse_args()

    try:
        from playwright.sync_api import sync_playwright
    except ImportError:
        print(
            json.dumps(
                {
                    "success": False,
                    "error": "Playwright is not installed. Run `pip install playwright` and `python -m playwright install chromium`."
                }
            ),
            file=sys.stderr,
        )
        return 1

    result: dict[str, object] = {"success": True}

    with sync_playwright() as playwright:
        browser = None

        try:
            browser = playwright.chromium.launch(headless=args.headless)
            page = browser.new_page()
            page.goto(args.url, wait_until=args.wait_until, timeout=args.timeout)
            result["url"] = page.url
            result["title"] = page.title()

            if args.text_selector:
                result["text"] = page.locator(args.text_selector).first.inner_text(timeout=args.timeout)

            if args.screenshot:
                output_path = Path(args.screenshot)
                output_path.parent.mkdir(parents=True, exist_ok=True)
                page.screenshot(path=str(output_path), full_page=True)
                result["screenshot"] = str(output_path.resolve())
        except Exception as error:
            print(json.dumps({"success": False, "error": str(error)}), file=sys.stderr)
            return 1
        finally:
            if browser is not None:
                browser.close()

    print(json.dumps(result, indent=2))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
