const fs = require("fs");
const assert = require("assert");
const input = process.argv[2];
const daysString = process.argv[3];

const days = parseInt(daysString);
const inputValues = fs
  .readFileSync(input, "utf-8")
  .split(",")
  .map((s) => parseInt(s, 10));

const spawnTime = 7;
const firstSpawnTime = 9;

const spawnDates = (startValue, remainingDays) => {
  if (remainingDays <= startValue) { return [] }
  const spawnCount = Math.ceil((remainingDays - startValue) / spawnTime);
  return Array(spawnCount).fill(0).map((_, index) => startValue + index * spawnTime);
};

const numFish = (startValue, remainingDays) => {
  const days = spawnDates(startValue, remainingDays);
  return 1 + days.reduce(function(partialSum, day) {
    return partialSum + numFish(firstSpawnTime, remainingDays - day);
  }, 0);
};

const condense = (input) => {
  return input.reduce((accumulator, key) => {
    accumulator[key] = (accumulator[key] || 0) + 1;
    return accumulator;
  }, {});
};

assert.deepEqual(spawnDates(3, 26), [3, 10, 17, 24]);
assert.deepEqual(spawnDates(0, 14), [0, 7]);
assert.deepEqual(spawnDates(9, 24), [9, 16, 23]);
assert.deepEqual(spawnDates(9, 17), [9, 16]);
assert.deepEqual(spawnDates(9, 9), []);
assert.deepEqual(spawnDates(9, 7), []);
assert.deepEqual(spawnDates(9, 11), [9]);
assert.deepEqual(spawnDates(3, 14), [3, 10]);
assert.equal(numFish(3, 14), 4);
assert.equal(numFish(9, 2), 1);
assert.equal(numFish(9, 11), 2);
assert.equal(numFish(3, 14), 4);
assert.equal(numFish(1, 18), 7);
assert.equal(numFish(2, 18), 5);
assert.equal(numFish(3, 18), 5);
assert.equal(numFish(4, 18), 4);
assert.deepEqual(condense([]), {});
assert.deepEqual(condense([1, 2, 1]), {1: 2, 2: 1});

const condensedInput = condense(inputValues);

const count = Object.keys(condensedInput).reduce((accumulator, key) => {
  console.log("Processing input: " + key);
  const multiplier = condensedInput[key];
  accumulator += numFish(parseInt(key), days) * multiplier;
  return accumulator;
}, 0);

console.log(count);