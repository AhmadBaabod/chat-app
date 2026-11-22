// Integration tests for the chat server. Run with: npm test
// Uses a tiny Socket.IO v4 client built on Node's built-in WebSocket,
// so no extra dependencies are needed.
const { test, before, after } = require("node:test");
const assert = require("node:assert/strict");
const { createChatServer, MAX_MESSAGE_LENGTH } = require("../app");

let server;
let port;

before(async () => {
  ({ server } = createChatServer());
  await new Promise((resolve) => server.listen(0, resolve));
  port = server.address().port;
});

after(() => new Promise((resolve) => server.close(resolve)));

// Minimal Socket.IO client (Engine.IO v4 over WebSocket).
function connect() {
  return new Promise((resolve, reject) => {
    const ws = new WebSocket(`ws://localhost:${port}/socket.io/?EIO=4&transport=websocket`);
    const events = [];
    const waiters = [];
    const client = {
      events,
      emit(event, data) {
        ws.send("42" + JSON.stringify([event, data]));
      },
      waitFor(event, predicate = () => true, timeout = 2000) {
        const found = events.find((e) => e.event === event && predicate(e.data));
        if (found) {
          events.splice(events.indexOf(found), 1);
          return Promise.resolve(found.data);
        }
        return new Promise((res, rej) => {
          const timer = setTimeout(() => rej(new Error(`timed out waiting for ${event}`)), timeout);
          waiters.push({ event, predicate, res, timer });
        });
      },
      close() {
        ws.close();
      },
    };
    ws.onerror = reject;
    ws.onmessage = ({ data }) => {
      if (data.startsWith("0")) ws.send("40"); // engine open -> connect namespace
      else if (data === "2") ws.send("3"); // ping -> pong
      else if (data.startsWith("40")) {
        client.id = JSON.parse(data.slice(2)).sid;
        resolve(client);
      } else if (data.startsWith("42")) {
        const [event, payload] = JSON.parse(data.slice(2));
        const i = waiters.findIndex((w) => w.event === event && w.predicate(payload));
        if (i >= 0) {
          const [w] = waiters.splice(i, 1);
          clearTimeout(w.timer);
          w.res(payload);
        } else events.push({ event, data: payload });
      }
    };
  });
}

test("health endpoint responds", async () => {
  const res = await fetch(`http://localhost:${port}/health`);
  assert.equal(res.status, 200);
  assert.equal((await res.json()).status, "ok");
});

test("messages reach every client with sender name and timestamp", async () => {
  const sara = await connect();
  const omar = await connect();
  sara.emit("join", { name: "Sara" });
  await sara.waitFor("history");
  omar.emit("join", { name: "Omar" });
  await omar.waitFor("history");
  await sara.waitFor("users", (u) => u.includes("Omar"));

  sara.emit("send", { msg: "  Salam!  " });
  for (const client of [sara, omar]) {
    const m = await client.waitFor("message", (m) => m.msg === "Salam!");
    assert.equal(m.sender, "Sara");
    assert.equal(m.senderId, sara.id);
    assert.ok(!Number.isNaN(Date.parse(m.date)));
  }
  sara.close();
  omar.close();
});

test("new users receive recent history", async () => {
  const a = await connect();
  a.emit("join", { name: "Ali" });
  await a.waitFor("history");
  a.emit("send", { msg: "history check" });
  await a.waitFor("message", (m) => m.msg === "history check");

  const b = await connect();
  b.emit("join", { name: "Badr" });
  const history = await b.waitFor("history");
  assert.ok(history.some((m) => m.msg === "history check" && m.sender === "Ali"));
  a.close();
  b.close();
});

test("rejects sending before joining, empty names and oversized messages", async () => {
  const c = await connect();
  c.emit("send", { msg: "hi" });
  assert.match((await c.waitFor("error_msg")).text, /Join the chat/);

  c.emit("join", { name: "   " });
  assert.match((await c.waitFor("error_msg")).text, /enter a name/);

  c.emit("join", { name: "Huda" });
  await c.waitFor("history");
  c.emit("send", { msg: "x".repeat(MAX_MESSAGE_LENGTH + 1) });
  assert.match((await c.waitFor("error_msg")).text, /at most/);
  c.close();
});

test("typing indicator goes to others, and leaving is announced", async () => {
  const d = await connect();
  const e = await connect();
  d.emit("join", { name: "Dana" });
  await d.waitFor("history");
  e.emit("join", { name: "Eman" });
  await e.waitFor("history");

  d.emit("typing", true);
  const typing = await e.waitFor("typing");
  assert.deepEqual(typing, { name: "Dana", isTyping: true });

  d.close();
  await e.waitFor("system", (s) => s.text === "Dana left the chat");
  const users = await e.waitFor("users", (u) => !u.includes("Dana"));
  assert.ok(users.includes("Eman"));
  e.close();
});
