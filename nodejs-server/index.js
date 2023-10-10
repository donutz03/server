const express = require("express");
const bodyParser = require("body-parser");
const path = require("path");
const exphbs = require("express-handlebars");

const app = express();

app.engine('hbs', exphbs({
    defaultLayout: 'main',
    extname: '.hbs'
}));

app.set('view engine', 'hbs');

app.use(bodyParser.json({ limit: "25mb" }));
app.use(bodyParser.urlencoded({ extended: true }));

const publicPath = path.resolve(__dirname, "public");
app.use(express.static(publicPath));

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
    res.send((a * b).toString());
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

app.get('/hbs', (req, res) => {
    res.render('home');
});

const PORT = 3000;
app.listen(PORT, () => console.log(`server is running on port ${PORT}`));
