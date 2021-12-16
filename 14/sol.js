const fs = require("fs");

const lines = fs.readFileSync("input.txt", "utf-8").toString().split("\n");
const polymerTemplate = lines[0];
const rules = lines.slice(2);
const rulesMap = rules.reduce((acc, curr) => {
  const [src, dest] = curr.split(" -> ");
  acc[src] = dest;
  return acc;
}, {});

const generatePairs = (input) => {
  const chars = input.split("");
  const pairs = {};
  for (i = 0; i < chars.length - 1; i++) {
    const code = chars[i] + chars[i + 1];
    pairs[code] = (pairs[code] || 0) + 1;
  }
  return pairs;
};

const countOccurences = (pairs, startingChar) => {
  const dict = {};
  dict[startingChar] = 1;
  return Object.keys(pairs).reduce((acc, curr) => {
    const char = curr[1];
    acc[char] = (acc[char] || 0) + pairs[curr];
    return acc;
  }, dict);
};

const computeMinMaxDiff = (occurences) => {
  const minVal = Math.min(...Object.values(occurences));
  const maxVal = Math.max(...Object.values(occurences));
  return maxVal - minVal;
};

const process = (pairs, rules) => {
  const newPairs = {};
  Object.keys(pairs).forEach((key) => {
    const insertedChar = rules[key];
    const pair1 = key[0] + insertedChar;
    const pair2 = insertedChar + key[1];
    newPairs[pair1] = (newPairs[pair1] || 0) + pairs[key];
    newPairs[pair2] = (newPairs[pair2] || 0) + pairs[key];
  });
  return newPairs;
};

let pairs = generatePairs(polymerTemplate);

Array.from(Array(40)).forEach((x, i) => {
  pairs = process(pairs, rulesMap);
});
const occurences = countOccurences(pairs, polymerTemplate[0]);
console.log(computeMinMaxDiff(occurences));