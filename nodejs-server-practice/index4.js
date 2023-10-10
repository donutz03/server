const faker = require("faker");

const args = process.argv;

const s = args[2];

const n = parseInt(args[3], 10);

if (s === "dog" || s === "snake" || s === "cat") {
  for (let i = 0; i < n; i++) {
    const animal = faker.animal[s]();
    console.log(animal);
  }
} else {
  console.log("Invalid animal type");
}
