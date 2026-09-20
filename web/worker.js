// Websocket relay for Archers rooms. One Durable Object per room. The first
// socket in a room is the host; see net.gd for the framing.
import { DurableObject } from 'cloudflare:workers';

const MAX_PLAYERS = 12;

export class ArchersRoom extends DurableObject {
	peers() {
		return this.ctx.getWebSockets().map((ws) => ({ ws, ...ws.deserializeAttachment() }));
	}

	async fetch(request) {
		if (request.headers.get('Upgrade') !== 'websocket') {
			return new Response('expected websocket', { status: 426 });
		}
		const peers = this.peers();
		if (peers.length >= MAX_PLAYERS) {
			return new Response('room full', { status: 403 });
		}
		const name = (new URL(request.url).searchParams.get('name') || '').slice(0, 16);
		const id = peers.reduce((max, p) => Math.max(max, p.id), 0) + 1;
		const hostPeer = peers.find((p) => p.host);
		const host = !hostPeer;

		const [client, server] = Object.values(new WebSocketPair());
		this.ctx.acceptWebSocket(server);
		server.serializeAttachment({ id, host, name });
		server.send(JSON.stringify({
			t: 'welcome', id, host,
			peers: peers.map((p) => ({ id: p.id, name: p.name })),
		}));
		if (hostPeer) hostPeer.ws.send(JSON.stringify({ t: 'join', id, name }));
		return new Response(null, { status: 101, webSocket: client });
	}

	webSocketMessage(ws, message) {
		if (typeof message === 'string') return;
		const me = ws.deserializeAttachment();
		if (me.host) {
			const target = new DataView(message).getUint16(0, true);
			const payload = message.slice(2);
			for (const p of this.peers()) {
				if (p.host || (target !== 0 && p.id !== target)) continue;
				try { p.ws.send(payload); } catch {}
			}
		} else {
			const hostPeer = this.peers().find((p) => p.host);
			if (!hostPeer) return;
			const framed = new Uint8Array(message.byteLength + 2);
			new DataView(framed.buffer).setUint16(0, me.id, true);
			framed.set(new Uint8Array(message), 2);
			try { hostPeer.ws.send(framed); } catch {}
		}
	}

	webSocketClose(ws) { this.left(ws); }
	webSocketError(ws) { this.left(ws); }

	left(ws) {
		const me = ws.deserializeAttachment();
		const others = this.peers().filter((p) => p.ws !== ws);
		if (me.host) {
			for (const p of others) {
				try { p.ws.close(4000, 'The host left. Reload to start a new game.'); } catch {}
			}
		} else {
			const hostPeer = others.find((p) => p.host);
			try { hostPeer?.ws.send(JSON.stringify({ t: 'leave', id: me.id })); } catch {}
		}
		try { ws.close(); } catch {}
	}
}

export default {
	async fetch(request, env) {
		const url = new URL(request.url);
		if (url.pathname === '/archers/ws') {
			const room = (url.searchParams.get('room') || 'lobby').toLowerCase().slice(0, 32);
			return env.ROOMS.get(env.ROOMS.idFromName(room)).fetch(request);
		}
		return env.ASSETS.fetch(request);
	},
};
