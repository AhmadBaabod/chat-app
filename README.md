# Chat App: real-time group chat with Flutter and Socket.IO

A group chat app with a Flutter client and a Node.js server. Messages are delivered over WebSockets using Socket.IO.

## Features

- **Pick a display name** before joining the chat.
- **Live group chat**: your messages show on the right, other people's on the left with their name and the time.
- **Recent history**: new users see the last 50 messages when they join.
- **Presence**: join and leave notices, an online count, and a list of who's online.
- **Typing indicator**: shows "Sara is typing…".
- **Input checks on the server**: empty names and empty messages are rejected, messages are capped at 1,000 characters, and you have to join before you can send.
- **Tested**: Node integration tests for the server, plus Flutter widget and model tests.

## Project structure

```
chat_app/
├── lib/
│   ├── main.dart            # Name screen + chat screen (Socket.IO client)
│   ├── model/msgModel.dart  # Message model (JSON parsing, system notices)
│   └── widget/msg.dart      # Chat bubble and system-message widgets
├── test/widget_test.dart    # Flutter tests
└── server/
    ├── app.js               # Express + Socket.IO chat server
    └── test/chat.test.js    # Server integration tests (node:test)
```

## Running it

### 1. Start the server (Node.js 22 or newer)

```bash
cd chat_app/server
npm install
npm start          # listens on port 4000 (set PORT to change it)
npm test           # runs the server tests
```

To check it's running, open `http://localhost:4000/health`.

### 2. Run the Flutter app (Flutter 3.10 or newer)

```bash
cd chat_app
flutter pub get
flutter run                                                     # Android emulator → http://10.0.2.2:4000
flutter run --dart-define=SERVER_URL=http://192.168.1.50:4000   # real phone on the same Wi-Fi
flutter test
```

To try the chat, open the app on two devices or emulators, join with different names and start talking.

## Socket.IO events

| Direction | Event | Payload |
|---|---|---|
| client → server | `join` | `{ name }` |
| client → server | `send` | `{ msg }` |
| client → server | `typing` | `true` / `false` |
| server → client | `history` | list of messages |
| server → client | `message` | `{ id, senderId, sender, msg, date }` |
| server → client | `system` | `{ text, date }` |
| server → client | `users` | list of online names |
| server → client | `typing` | `{ name, isTyping }` |
| server → client | `error_msg` | `{ text }` |

## Tech

Flutter · Dart · socket_io_client · Node.js · Express · Socket.IO
