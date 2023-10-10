const express = require("express");
const bodyParser = require("body-parser");

const app = express();

app.use(bodyParser.json({limit: '25mb'}));
app.use(bodyParser.urlencoded({extended:true}))

app.get("/login", (req, res) => {
  const body = req.body;
  console.log(body);
  res.send("Login route");
});

app.get("/params", (req, res) => {
  const queryParams = req.query;
  console.log(queryParams);
  const a = +queryParams.a;
  const b = +queryParams.b;
  res.send(a * b + "");
});

app.get("/", (req, res) => {
  res.send("Route with no params");
});

app.get("/:id", (req, res) => {
  const id = parseInt(req.params.id, 10);
  console.log(id * id);
  const response = "" + id * id;
  res.send(response);
});

const PORT = 3000;
app.listen(PORT, () => console.log(`server is running on port ${PORT}`));
