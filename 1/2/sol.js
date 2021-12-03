const fs = require("fs");
const input = process.argv[2];

const values = fs
  .readFileSync(input, "utf-8")
  .split("\n")
  .filter(Boolean)
  .map((s) => parseInt(s, 10));

const windowSize = 3;

var condensedValues = [];
for (let i = 0; i <= values.length - windowSize; i++) {
  const slice = values.slice(i, i + windowSize);
  const sum = slice.reduce(function (a, b) {
    return a + b;
  }, 0);

  condensedValues.push(sum);
}

const count = condensedValues.filter(function (value, index) {
  if (index == 0) {
    return false;
  }

  return value > condensedValues[index - 1];
}).length;

console.log(count);
