const http = require('http');
const urlLib = require("url");

const app = http.createServer((req,res) => {
  const url=req.url;
  console.log(url);

  if (url === "/random"){
    const random = Math.floor(Math.random() * 100);
    res.write(random.toString());
  } else if (url.indexOf("/param/")!== -1){
const components = url.split("/");
const value = parseInt(components[2], 10);
res.write((value * value).toString());
    
  } else if (url.indexOf("/query") !== -1) {
    const query = urlLib.parse(url, true).query;
    console.log(query.a);
    const a = parseInt(query.a,10);
    const b = parseInt(query.b, 10);
    const pow = Math.pow(a,b);
    console.log(a,b);
    res.write(pow.toString());
  } else {

      res.write("Ruta nedefinita");
    
  }
  res.end();
});

app.listen(4200, () => console.log("Server is running..."));
