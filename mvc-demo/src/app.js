const express = require("express");
const bodyParser = require("body-parser");
const path = require("path");

const UsersRoute=require('./routes/users.routes')

const app = express();
app.use(bodyParser.json({ limit: "25mb" }));
app.use(bodyParser.urlencoded({ extended: false }));

const publicPath = path.resolve(__dirname, "public");
app.use(express.static(publicPath));

new UsersRoute().routes(app)

const PORT = 3000;
app.listen(PORT, () => console.log('srv is running...'))