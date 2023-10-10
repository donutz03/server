const express = require("express");

const app = express();

const PORT = 3000;

app.get("/", (req,res) =>{
  res.send("GET request type);
});

app.put("/:n", (req,res) =>{
  const n = req.params.n;
  res.send("PUT request type - " + n);
});

app.post("/:n", (req,res)=>{
  const n = req.params.n;
  res.send("POST request type - " + n);
});

app.delete("/:n", (req,res) =>{
  const n = req.params.n;
  res.send("DELETE request type - " + n);
});

app.listen(PORT, () => console.log(`Server is running on PORT ${PORT}`));
