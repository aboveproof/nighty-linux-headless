import sys
import unittest
from pathlib import Path
from unittest.mock import patch


SCRIPTS = Path(__file__).resolve().parents[1] / "scripts"
sys.path.insert(0, str(SCRIPTS))

import bridge  # noqa: E402


class HealthzEndpointTests(unittest.TestCase):
    def test_api_path_includes_healthz(self):
        # Create dummy request handler instance
        handler = bridge.H.__new__(bridge.H)
        handler.headers = {}
        handler.command = "GET"
        handler.requestline = "GET /healthz HTTP/1.1"
        handler.request_version = "HTTP/1.1"

        with patch.object(bridge, "web_up", return_value=True), \
             patch.object(bridge, "panel_blocked", return_value=False), \
             patch.object(bridge.H, "_send") as mock_send:

            handler.path = "/healthz"
            handler.do_GET()

            # Verify _send was called with 200 OK JSON response instead of proxying
            mock_send.assert_called_once()
            args, kwargs = mock_send.call_args
            ctype = args[1] if len(args) > 1 else kwargs.get("ctype")
            code = kwargs.get("code", 200)
            body = args[0]
            body_str = body.decode("utf-8") if isinstance(body, bytes) else body

            self.assertIn('"status": "ok"', body_str)
            self.assertIn('"ready": true', body_str)
            self.assertEqual(code, 200)
            self.assertEqual(ctype, "application/json")

    def test_healthz_is_live_while_panel_is_starting(self):
        handler = bridge.H.__new__(bridge.H)
        handler.headers = {}
        handler.command = "GET"
        handler.requestline = "GET /healthz HTTP/1.1"
        handler.request_version = "HTTP/1.1"
        handler.path = "/healthz"

        with patch.object(bridge, "web_up", return_value=False), \
             patch.object(bridge, "setup_locked", return_value=False), \
             patch.object(bridge, "_onboarded", return_value=False), \
             patch.object(bridge.H, "_send") as mock_send:
            handler.do_GET()

        args, kwargs = mock_send.call_args
        self.assertIn('"ready": false', args[0])
        self.assertEqual(kwargs["code"], 200)

    def test_ready_fails_while_panel_is_starting(self):
        handler = bridge.H.__new__(bridge.H)
        handler.headers = {}
        handler.command = "GET"
        handler.requestline = "GET /ready HTTP/1.1"
        handler.request_version = "HTTP/1.1"
        handler.path = "/ready"

        with patch.object(bridge, "web_up", return_value=False), \
             patch.object(bridge, "setup_locked", return_value=False), \
             patch.object(bridge, "_onboarded", return_value=False), \
             patch.object(bridge.H, "_send") as mock_send:
            handler.do_GET()

        self.assertEqual(mock_send.call_args.kwargs["code"], 503)


if __name__ == "__main__":
    unittest.main()
