const assert = require("assert");
const fs = require("fs");
const input = process.argv[2];

class Literal {
  constructor(value) {
    this.value = value;
  }

  magnitude() {
    return this.value;
  }
}

class Pair {
  constructor(left, right) {
    this.left = left;
    this.right = right;
  }

  magnitude() {
    return 3 * this.left.magnitude() + 2 * this.right.magnitude();
  }
}

const add = (obj1, obj2) => {
  const newPair = new Pair(obj1, obj2);
  obj1.parent = newPair;
  obj2.parent = newPair;
  reduce(newPair);
  return newPair;
};

const slice = (string) => {
  let depthCount = 0;
  for (i = 0; i < string.length; i++) {
    const char = string.charAt(i);
    switch (char) {
      case "[":
        depthCount++;
        break;
      case "]":
        depthCount--;
        break;
      case ",":
        if (depthCount == 1) {
          return {
            left: string.slice(1, i),
            right: string.slice(i + 1, string.length - 1),
          };
        }
        break;
    }
  }
  return undefined;
};

const parse = (string) => {
  if (!string.includes("[")) {
    return new Literal(parseInt(string));
  }
  const strings = slice(string);
  const left = parse(strings.left);
  const right = parse(strings.right);
  const pair = new Pair(left, right);
  left.parent = pair;
  right.parent = pair;
  return pair;
};

const parentCount = (pair) => {
  let count = 0;
  let parent = pair.parent;
  while (parent !== undefined) {
    count++;
    parent = parent.parent;
  }
  return count;
};

const leftLiteralUpwardsSearch = (pair) => {
  if (pair.left instanceof Literal) {
    return pair.left;
  }
  return leftLiteralUpwardsSearch(pair.left);
};

const rightLiteralUpwardsSearch = (pair) => {
  if (pair.right instanceof Literal) {
    return pair.right;
  }
  return rightLiteralUpwardsSearch(pair.right);
};

const literalLeftOf = (pair) => {
  if (pair.parent == undefined) {
    return undefined;
  }

  if (pair === pair.parent.left) {
    return literalLeftOf(pair.parent);
  }

  if (pair === pair.parent.right) {
    if (pair.parent.left instanceof Literal) {
      return pair.parent.left;
    } else {
      return rightLiteralUpwardsSearch(pair.parent.left);
    }
  }
};

const literalRightOf = (pair) => {
  if (pair.parent == undefined) {
    return undefined;
  }

  if (pair === pair.parent.right) {
    return literalRightOf(pair.parent);
  }

  if (pair === pair.parent.left) {
    if (pair.parent.right instanceof Literal) {
      return pair.parent.right;
    } else {
      return leftLiteralUpwardsSearch(pair.parent.right);
    }
  }
};

const explode = (rootPair) => {
  const explodingPair = firstPairForExploding(rootPair);
  if (explodingPair === undefined) {
    return false;
  }

  const leftLiteral = literalLeftOf(explodingPair);
  const rightLiteral = literalRightOf(explodingPair);

  if (leftLiteral !== undefined) {
    leftLiteral.value += explodingPair.left.value;
  }
  if (rightLiteral !== undefined) {
    rightLiteral.value += explodingPair.right.value;
  }

  if (explodingPair.parent) {
    const newLiteral = new Literal(0);
    newLiteral.parent = explodingPair.parent;

    if (explodingPair.parent.left === explodingPair) {
      explodingPair.parent.left = newLiteral;
    }
    if (explodingPair.parent.right === explodingPair) {
      explodingPair.parent.right = newLiteral;
    }
  }

  return true;
};

const split = (rootPair) => {
  const splittingLiteral = firstLiteralForSplitting(rootPair);
  if (splittingLiteral === undefined) {
    return false;
  }

  const literalLeft = new Literal(Math.floor(splittingLiteral.value / 2));
  const literalRight = new Literal(Math.ceil(splittingLiteral.value / 2));
  const newPair = new Pair(literalLeft, literalRight);
  newPair.parent = splittingLiteral.parent;
  literalLeft.parent = newPair;
  literalRight.parent = newPair;

  if (splittingLiteral.parent) {
    if (splittingLiteral.parent.left === splittingLiteral) {
      splittingLiteral.parent.left = newPair;
    }
    if (splittingLiteral.parent.right === splittingLiteral) {
      splittingLiteral.parent.right = newPair;
    }
  }

  return true;
};

const firstPairForExploding = (obj) => {
  if (!(obj instanceof Pair)) {
    return undefined;
  }
  if (parentCount(obj) >= 4) {
    return obj;
  }

  let foundPair = firstPairForExploding(obj.left);
  if (foundPair === undefined) {
    foundPair = firstPairForExploding(obj.right);
  }
  return foundPair;
};

const firstLiteralForSplitting = (obj) => {
  if (obj instanceof Literal) {
    return obj.value >= 10 ? obj : undefined;
  }

  let foundLiteral = firstLiteralForSplitting(obj.left);
  if (foundLiteral === undefined) {
    foundLiteral = firstLiteralForSplitting(obj.right);
  }
  return foundLiteral;
};

const reduce = (rootPair) => {
  while (true) {
    const didExplode = explode(rootPair);
    if (didExplode) {
      continue;
    }

    const didSplit = split(rootPair);
    if (didSplit) {
      continue;
    }

    break;
  }
};

const addLines = (strings) => {
  let result;
  for (const string of strings) {
    const newPair = parse(string);

    if (result === undefined) {
      result = newPair;
      continue;
    }

    result = add(result, newPair);
  }
  return result;
};

const largestMagnitudeAmong = (strings) => {
  let largest;
  for (let i = 0; i < strings.length; i++) {
    for (let j = 0; j < strings.length; j++) {
      const pair1 = parse(strings[i]);
      const pair2 = parse(strings[j]);
      let result = add(pair1, pair2);
      let magnitude = result.magnitude();

      if (largest === undefined || largest < magnitude) {
        largest = magnitude;
      }
    }
  }

  return largest;
};

const lines = fs.readFileSync(input, "utf-8").split("\n");
console.log(`Magnitude of sum: ${addLines(lines).magnitude()}`);
console.log(`Largest magnitude: ${largestMagnitudeAmong(lines)}`);

/********* TESTS *********/

{
  assert.deepEqual(slice("[[1,2],3]"), { left: "[1,2]", right: "3" });
}

{
  const pair = parse("[[[[1,2],[3,4]],[[5,6],[7,8]]],9]");
  assert.equal(pair.left.left.left.left.value, 1);
  assert.equal(pair.left.left.left.right.value, 2);
  assert.equal(pair.left.left.right.left.value, 3);
  assert.equal(pair.left.left.right.right.value, 4);
  assert.equal(pair.left.right.left.left.value, 5);
  assert.equal(pair.left.right.left.right.value, 6);
  assert.equal(pair.left.right.right.left.value, 7);
  assert.equal(pair.left.right.right.right.value, 8);
  assert.equal(pair.right.value, 9);
}

{
  const pair = parse("[[1,2],3]");
  assert.equal(pair.left.parent, pair);
  assert.equal(parentCount(pair.left), 1);
}

{
  const explodingPair = parse("[[3,[2,[1,[7,3]]]],[6,[5,[4,[3,2]]]]]");
  assert.equal(
    firstPairForExploding(explodingPair),
    explodingPair.left.right.right.right
  );
}

{
  const pair = parse("[[[1,4],2],3]");
  assert.equal(leftLiteralUpwardsSearch(pair), pair.left.left.left);
  assert.equal(rightLiteralUpwardsSearch(pair), pair.right);
  assert.equal(rightLiteralUpwardsSearch(pair.left), pair.left.right);
}

{
  const pair = parse("[[[1,4],2],[5,6]]");
  assert.equal(literalLeftOf(pair.right), pair.left.right);
}

{
  const pair = parse("[[[1,4],2],[[5,7],6]]");
  assert.equal(literalLeftOf(pair.right.left), pair.left.right);
}

{
  const pair = parse("[[[1,4],2],[6,[5,7]]]");
  assert.equal(literalLeftOf(pair.right.right), pair.right.left);
}

{
  const pair = parse("[[2,[1,[4,9]]],[5,6]]");
  assert.equal(literalLeftOf(pair.right), pair.left.right.right.right);
}

{
  const pair = parse("[[[1,4],2],1]");
  assert.equal(literalLeftOf(pair.left.left), undefined);
}

{
  const pair = parse("[[[1,4],2],[5,6]]");
  assert.equal(literalRightOf(pair.left), pair.right.left);
}

{
  const pair = parse("[[[1,4],2],[[5,7],6]]");
  assert.equal(literalRightOf(pair.left), pair.right.left.left);
}

{
  const pair = parse("[[[1,4],2],[6,[5,7]]]");
  assert.equal(literalRightOf(pair.left.left), pair.left.right);
}

{
  const pair = parse("[[2,[1,[4,9]]],[5,6]]");
  assert.equal(literalRightOf(pair.left.right.right), pair.right.left);
}

{
  const pair = parse("[1,[1,4]]");
  assert.equal(literalRightOf(pair.right), undefined);
}

{
  const explodeTests = [
    { original: "[[[[[9,8],1],2],3],4]", expected: "[[[[0,9],2],3],4]" },
    { original: "[7,[6,[5,[4,[3,2]]]]]", expected: "[7,[6,[5,[7,0]]]]" },
    { original: "[[6,[5,[4,[3,2]]]],1]", expected: "[[6,[5,[7,0]]],3]" },
    {
      original: "[[3,[2,[1,[7,3]]]],[6,[5,[4,[3,2]]]]]",
      expected: "[[3,[2,[8,0]]],[9,[5,[4,[3,2]]]]]",
    },
    {
      original: "[[3,[2,[8,0]]],[9,[5,[4,[3,2]]]]]",
      expected: "[[3,[2,[8,0]]],[9,[5,[7,0]]]]",
    },
  ];

  for (const test of explodeTests) {
    const pair = parse(test.original);
    const expectedPair = parse(test.expected);
    const didExplode = explode(pair);
    assert(didExplode);
    assert.deepEqual(pair, expectedPair);
  }
}

{
  const splitTests = [
    {
      original: "[[[[0,7],4],[15,[0,13]]],[1,1]]",
      expected: "[[[[0,7],4],[[7,8],[0,13]]],[1,1]]",
    },
    {
      original: "[[[[0,7],4],[[7,8],[0,13]]],[1,1]]",
      expected: "[[[[0,7],4],[[7,8],[0,[6,7]]]],[1,1]]",
    },
  ];

  for (const test of splitTests) {
    const pair = parse(test.original);
    const expectedPair = parse(test.expected);
    const didSplit = split(pair);
    assert(didSplit);
    assert.deepEqual(pair, expectedPair);
  }
}

{
  const pair = parse("[[[[[4,3],4],4],[7,[[8,4],9]]],[1,1]]");
  const expectedPair = parse("[[[[0,7],4],[[7,8],[6,0]]],[8,1]]");
  reduce(pair);
  assert.deepEqual(pair, expectedPair);
}

{
  const pair1 = parse("[[[[4,3],4],4],[7,[[8,4],9]]]");
  const pair2 = parse("[1,1]");
  const expectedPair = parse("[[[[0,7],4],[[7,8],[6,0]]],[8,1]]");
  const newPair = add(pair1, pair2);
  assert.deepEqual(newPair, expectedPair);
}

{
  const pair1 = parse("[[2,[[7,7],7]],[[5,8],[[9,3],[0,2]]]]");
  const pair2 = parse("[[[0,[5,8]],[[1,7],[9,6]]],[[4,[1,2]],[[1,4],2]]]");
  const expectedPair = parse(
    "[[[[7,8],[6,6]],[[6,0],[7,7]]],[[[7,8],[8,8]],[[7,9],[0,6]]]]"
  );
  const newPair = add(pair1, pair2);
  assert.deepEqual(newPair, expectedPair);
  assert.equal(newPair.magnitude(), 3993);
}

{
  const pair = parse("[[1,2],[[3,4],5]]");
  assert.equal(pair.magnitude(), 143);
}
