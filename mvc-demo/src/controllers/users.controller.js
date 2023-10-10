class UsersController {
  constructor() {
    this.users = [];
  }
  getAll() {
    return this.users;
  }

  get(id) {
    const user = this.users.find((user) => user.id === id);
    return user;
  }

  add(user) {
    this.users.push(user);
  }
}

module.exports = UsersController;
