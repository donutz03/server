const UsersController = require('../controllers/users.controller')

class UsersRoute {
    constructor() {
        this.usersController = new UsersController();
    }

  routes(app) {
    app.get("/", (req, res) => {
        const users=this.usersController.getAll();
        if (users.length===0) {
            res.send('No usrs found')
        } else {
            res.json(users)
        }
    });

    app.post("/", (req, res) => {});
  }
}

module.exports = UsersRoute;
