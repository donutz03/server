const http=require('http');

const server = http.createServer((req,res)=>{
    const url = req.url;

    if (url === '/') {
        res.setHeader('content-type','text/html');
        res.write('<h1 style="color:green">Hello Ionut</h1>');
        res.end();
    } else if (url==='/json') {
        res.setHeader('content-type', 'application/json');
        const object = {
            prop: 1,
            prop2: [1,2,3],
            prop3: "test",
        };
        res.end(JSON.stringify(object));
    }
else {
        res.setHeader('content-type','text/html');
        res.write('<h1 style="color:red">Path not found</h1>');
        res.end();
    }

    console.log(url);
   

});

const PORT=3000;
server.listen(PORT, ()=>console.log(`server is running on port ${PORT}`));
