import sys, json, socket, os

def get_token():
    env_token = os.getenv("CONCAT_TOKEN")
    if env_token:
        return env_token

    candidate_paths = [
        os.path.expanduser("~/.config/app.concat.editor/settings.json"),
        os.path.join(os.getenv("APPDATA", ""), "app.concat.editor", "settings.json") if os.getenv("APPDATA") else None,
        os.path.expanduser("~/AppData/Roaming/app.concat.editor/settings.json"),
    ]

    for p in candidate_paths:
        if not p:
            continue
        try:
            if os.path.exists(p):
                with open(p, "r", encoding="utf-8") as f:
                    tok = json.load(f).get("server", {}).get("token")
                    if tok:
                        return tok
        except Exception:
            continue

    return "kucing123"

TOKEN = get_token()
HOST = os.getenv("CONCAT_HOST", "127.0.0.1")
PORT = int(os.getenv("CONCAT_PORT", "7420"))

sock = None
reader = None

def get_connection():
    global sock, reader
    if sock is not None:
        try:
            sock.sendall(b"")
            return sock, reader
        except Exception:
            sock = None
            reader = None

    s = socket.create_connection((HOST, PORT), timeout=2.0)
    s.sendall((json.dumps({"jsonrpc": "2.0", "id": 0, "method": "auth", "params": {"token": TOKEN}}) + "\n").encode())
    r = s.makefile(encoding="utf-8")
    auth_res = json.loads(r.readline())
    if "error" in auth_res:
        s.close()
        raise RuntimeError(f"Auth failed: {auth_res['error'].get('message', 'invalid token')}")
    sock = s
    reader = r
    return sock, reader

def rpc_call(method, params=None):
    for attempt in range(2):
        try:
            s, r = get_connection()
            payload = {"jsonrpc": "2.0", "id": 1, "method": method, "params": params or {}}
            s.sendall((json.dumps(payload) + "\n").encode())
            while True:
                line = r.readline()
                if not line:
                    raise ConnectionError("Concat socket closed or app quit")
                msg = json.loads(line)
                if msg.get("id") == 1:
                    if "error" in msg:
                        raise RuntimeError(msg["error"].get("message", "RPC error"))
                    return msg.get("result", {})
        except Exception as e:
            global sock, reader
            if sock:
                try: sock.close()
                except Exception: pass
            sock = None
            reader = None
            if attempt == 1:
                raise e

TOOLS = [
    {
        "name": "concat_version",
        "description": "Get Concat version and capabilities",
        "inputSchema": {"type": "object", "properties": {}}
    },
    {
        "name": "concat_call",
        "description": "Call any Concat JSON-RPC method (e.g. project.open, media.import, edit.apply, export.run)",
        "inputSchema": {
            "type": "object",
            "properties": {
                "method": {"type": "string"},
                "params": {"type": "object"}
            },
            "required": ["method"]
        }
    }
]

def handle(req):
    method = req.get("method")
    rid = req.get("id")
    if method == "initialize":
        return {"protocolVersion": "2024-11-05", "capabilities": {"tools": {}}, "serverInfo": {"name": "concat", "version": "0.2.6"}}
    elif method == "notifications/initialized":
        return None
    elif method == "tools/list":
        return {"tools": TOOLS}
    elif method == "tools/call":
        name = req.get("params", {}).get("name")
        args = req.get("params", {}).get("arguments", {})
        try:
            if name == "concat_version":
                data = rpc_call("version")
            elif name == "concat_call":
                data = rpc_call(args["method"], args.get("params"))
            else:
                return {"isError": True, "content": [{"type": "text", "text": f"Unknown tool: {name}"}]}
            return {"content": [{"type": "text", "text": json.dumps(data, indent=2)}]}
        except Exception as e:
            return {"isError": True, "content": [{"type": "text", "text": str(e)}]}
    return {"error": {"code": -32601, "message": "Method not found"}}

def main():
    # ponytail: single-threaded stdio loop without async; add rmcp if streaming events needed
    for line in sys.stdin:
        line = line.strip()
        if not line:
            continue
        try:
            req = json.loads(line)
            res = handle(req)
            if res is not None and "id" in req:
                out = {"jsonrpc": "2.0", "id": req["id"]}
                if "error" in res:
                    out["error"] = res["error"]
                else:
                    out["result"] = res
                sys.stdout.write(json.dumps(out) + "\n")
                sys.stdout.flush()
        except Exception as e:
            sys.stderr.write(f"Err: {e}\n")

if __name__ == "__main__":
    main()
