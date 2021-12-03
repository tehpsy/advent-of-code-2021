const fs = require("fs");
const input = process.argv[2];

var depth = 0;
var horizontal = 0;
var aim = 0;

fs.readFileSync(input, "utf-8")
  .split("\n")
  .forEach(function (line) {
    const regex = new RegExp("(.{1,}) ([0-9]{1,})");
    const results = line.match(regex);
    const command = results[1];
    const value = parseInt(results[2], 10);

    switch (command) {
      case "up":
        aim -= value;
        break;
      case "down":
        aim += value;
        break;
      case "forward":
        horizontal += value;
        depth += aim * value;
        break;
    }
  });

console.log(depth * horizontal);
