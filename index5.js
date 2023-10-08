const express = require("express");

const app = express();

app.get("/", (req,res) => {
  res.send("Hello world!");
});

app.get("/json", (req,res) =>{
  res.send({prop1: 1, prop2 : 2});
  
});

app.get("/test", (req,res) =>{

  const a = Math.floor(Math.random() * 100);
  const b = Math.floor(Math.random() * 100);
  res.send(`${ a * b }`);
  
});

const PORT = 3000;
app.listen(PORT, () => console.log(`Server is running on PORT ${PORT}`));
