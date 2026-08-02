// Archers relay worker: serves the Godot web export and relays game traffic
// between one host and N clients per room via a Durable Object.
// Wire format documented in netplay/relay.gd.

export class ArchersRoom {
  constructor(state, env) {
    this.host = null;
    this.clients = new Map(); // "ws-N" -> WebSocket
    this.nextId = 1;
  }

  async fetch(request) {
    if (request.headers.get("Upgrade") !== "websocket") {
      return new Response("expected websocket", { status: 426 });
    }
    const role = new URL(request.url).searchParams.get("role") || "join";
    const pair = new WebSocketPair();
    this.handle(pair[1], role);
    return new Response(null, { status: 101, webSocket: pair[0] });
  }

  send(ws, obj) {
    try {
      ws.send(typeof obj === "string" ? obj : JSON.stringify(obj));
    } catch {}
  }

  handle(ws, role) {
    ws.accept();
    if (role === "host") {
      if (this.host) {
        try { this.host.close(1000, "replaced by new host"); } catch {}
      }
      this.host = ws;
      ws.addEventListener("message", (e) => {
        let d;
        try { d = JSON.parse(e.data); } catch { return; }
        if (d.snap !== undefined) {
          for (const c of this.clients.values()) this.send(c, e.data);
        } else if (d.to) {
          const c = this.clients.get(d.to);
          if (c) this.send(c, { msg: d.msg });
        }
      });
      ws.addEventListener("close", () => {
        if (this.host !== ws) return;
        this.host = null;
        for (const c of this.clients.values()) this.send(c, { hostGone: true });
      });
    } else {
      const id = "ws-" + this.nextId++;
      this.clients.set(id, ws);
      ws.addEventListener("message", (e) => {
        let d;
        try { d = JSON.parse(e.data); } catch { return; }
        if (this.host && d.msg !== undefined) {
          this.send(this.host, { from: id, msg: d.msg });
        }
      });
      ws.addEventListener("close", () => {
        this.clients.delete(id);
        if (this.host) this.send(this.host, { left: id });
      });
    }
  }
}

export default {
  async fetch(request, env) {
    const url = new URL(request.url);
    if (url.pathname === "/ws") {
      const room = url.searchParams.get("room") || "arena";
      return env.ROOMS.get(env.ROOMS.idFromName(room)).fetch(request);
    }
    return env.ASSETS.fetch(request);
  },
};
