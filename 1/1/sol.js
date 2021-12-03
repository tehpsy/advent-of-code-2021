const fs = require("fs");
const input = process.argv[2];

const values = fs
  .readFileSync(input, "utf-8")
  .split("\n")
  .filter(Boolean)
  .map((s) => parseInt(s, 10));

const count = values.filter(function (value, index) {
  if (index == 0) {
    return false;
  }
  return value > values[index - 1];
}).length;

console.log(count);
