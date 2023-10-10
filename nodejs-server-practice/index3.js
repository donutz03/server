const a = 10;
const b = Math.floor(Math.random() * 100);

if (isLessThan(a + b)) {
  console.log(a + b);
  if (isBetween(a)) {
    console.log("Between 50 and 100");
  }
} else {
  console.log(b);
  if (isGreaterThan(b)) {
    console.log(" > 50");
  }
}

function isGreaterThan(m) {
  return m > 50;
}

function isLessThan(n) {
  return n < 100;
}

function isBetween(n, m) {
  return isGreaterThan(m) && isLessThan(n);
}
