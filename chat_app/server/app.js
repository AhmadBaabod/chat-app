// Real-time chat server for the Flutter chat app.
// Socket.IO events:
//   client -> server: "join" { name }, "send" { msg }, "typing" boolean
//   server -> client: "history" [Message], "message" Message,
//                     "system" { text, date }, "users" [name], "typing" { name, isTyping },
//                     "error_msg" { text }
// Message = { id, senderId, sender, msg, date }

const express = require("express");
const http = require("http");
const { Server } = require("socket.io");

const MAX_MESSAGE_LENGTH = 1000;
const MAX_NAME_LENGTH = 30;
const HISTORY_SIZE = 50;

function createChatServer() {
  const app = express();
  const server = http.createServer(app);
  const io = new Server(server, { cors: { origin: "*" } });

  const users = new Map(); // socket.id -> name
  const history = [];
  let nextId = 1;

  app.get("/health", (_req, res) => {
    res.json({ status: "ok", users: users.size, messages: history.length });
  });

  const userList = () => [...users.values()];
  const now = () => new Date().toISOString();

  io.on("connection", (socket) => {
    socket.on("join", (data) => {
      const name = String((data && data.name) || "").trim().slice(0, MAX_NAME_LENGTH);
      if (!name) {
        socket.emit("error_msg", { text: "Please enter a name." });
        return;
      }
      const isRename = users.has(socket.id);
      users.set(socket.id, name);
      if (!isRename) socket.emit("history", history);
      io.emit("system", { text: `${name} joined the chat`, date: now() });
      io.emit("users", userList());
    });

    socket.on("send", (data) => {
      const sender = users.get(socket.id);
      if (!sender) {
        socket.emit("error_msg", { text: "Join the chat before sending messages." });
        return;
      }
      const msg = String((data && data.msg) || "").trim();
      if (!msg) return;
      if (msg.length > MAX_MESSAGE_LENGTH) {
        socket.emit("error_msg", {
          text: `Messages can be at most ${MAX_MESSAGE_LENGTH} characters.`,
        });
        return;
      }
      const message = { id: nextId++, senderId: socket.id, sender, msg, date: now() };
      history.push(message);
      if (history.length > HISTORY_SIZE) history.shift();
      io.emit("message", message);
    });

    socket.on("typing", (isTyping) => {
      const name = users.get(socket.id);
      if (name) socket.broadcast.emit("typing", { name, isTyping: Boolean(isTyping) });
    });

    socket.on("disconnect", () => {
      const name = users.get(socket.id);
      if (!name) return;
      users.delete(socket.id);
      io.emit("system", { text: `${name} left the chat`, date: now() });
      io.emit("users", userList());
    });
  });

  return { app, server, io };
}

if (require.main === module) {
  const port = Number(process.env.PORT) || 4000;
  const { server } = createChatServer();
  server.listen(port, "0.0.0.0", () => {
    console.log(`Chat server listening on port ${port}`);
  });
}

module.exports = { createChatServer, MAX_MESSAGE_LENGTH, HISTORY_SIZE };
