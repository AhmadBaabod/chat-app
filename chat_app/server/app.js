const express = require("express");
const app = express();
const port = 4000;
const server = require('http').createServer(app);
const io = require('socket.io')(server);

io.on('connection', (userSocket) => {
    console.log('connected');
    userSocket.on('send',(data)=>{
      console.log(data);
    })
});

server.listen(port, () => {
  console.log("Server on...");
});
