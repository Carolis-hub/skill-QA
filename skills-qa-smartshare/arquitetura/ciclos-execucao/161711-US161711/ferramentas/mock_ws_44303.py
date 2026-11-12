"""Mock HTTP para o ExecutaWs (#161716). Responde 200 com JSON valido em qualquer caminho e metodo.

Uso:  python mock_ws_44303.py [porta] [modo]
  porta  padrao 44303 (URL da WS_CONSULTA 1: http://localhost:44303/api/v1/Cliente/getCliente3)
  modo   ok (padrao) | erro500 | lento   (cenario 6 do mapa: endpoint fora do ar)
Cada requisicao e gravada em mock_ws_requests.log (uma linha), util para contar chamadas por fluxo.
"""
import json
import sys
import time
from datetime import datetime
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
from pathlib import Path

PORT = int(sys.argv[1]) if len(sys.argv) > 1 else 44303
MODE = sys.argv[2] if len(sys.argv) > 2 else "ok"
LOG = Path(__file__).with_name("mock_ws_requests.log")


class Handler(BaseHTTPRequestHandler):
    def _handle(self):
        length = int(self.headers.get("Content-Length") or 0)
        if length:
            self.rfile.read(length)
        with LOG.open("a", encoding="utf-8") as f:
            f.write(f"{datetime.now().isoformat(timespec='milliseconds')} {self.command} {self.path} modo={MODE}\n")
        if MODE == "lento":
            time.sleep(60)
        if MODE == "erro500":
            body = json.dumps({"erro": "mock indisponivel"}).encode()
            self.send_response(500)
        else:
            body = json.dumps({"ok": True, "origem": "mock-qa-161711", "args": {"teste": "smartshare"}}).encode()
            self.send_response(200)
        self.send_header("Content-Type", "application/json")
        self.send_header("Content-Length", str(len(body)))
        self.end_headers()
        self.wfile.write(body)

    do_GET = do_POST = do_PUT = do_DELETE = _handle

    def log_message(self, *args):
        pass


if __name__ == "__main__":
    print(f"mock ExecutaWs em http://127.0.0.1:{PORT} modo={MODE}; log em {LOG}", flush=True)
    ThreadingHTTPServer(("127.0.0.1", PORT), Handler).serve_forever()
