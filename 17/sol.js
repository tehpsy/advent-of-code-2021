function inRange(x, min, max) {
  return x >= min && x <= max;
}

const probeIsInTarget = (probe, target) => {
  return inRange(probe.x, target.minX, target.maxX) 
      && inRange(probe.y, target.minY, target.maxY);
};

const probeHasMissedTarget = (probe, target) => {
  return probe.x > target.maxX || probe.y < target.minY;
};

const tick = (probe) => {
  probe.x += probe.velX;
  probe.y += probe.velY;
  probe.velX = Math.max(probe.velX - 1, 0);
  probe.velY -= 1;
};

const maxHeight = (probe, target) => {
  var maxHeight = 0;
  while (true) {
    tick(probe);
    maxHeight = Math.max(probe.y, maxHeight);
    if (probeIsInTarget(probe, target)) { return maxHeight; }
    if (probeHasMissedTarget(probe, target)) { return undefined; }
  }
};

const probeWillHit = (probe, target) => {
  while (true) {
    tick(probe);
    if (probeIsInTarget(probe, target)) { return true; }
    if (probeHasMissedTarget(probe, target)) { return false; }
  }
};

const makeProbe = (velX, velY) => {
  return {x: 0, y: 0, velX, velY};
};

const makeTarget = (minX, maxX, minY, maxY) => {
  return {minX, maxX, minY, maxY};
};

const greatestHeight = (target) => {
  const greatestInitialYVelocity = -1 * target.minY - 1;
  if (greatestInitialYVelocity <= 0) { return 0; }
  return (greatestInitialYVelocity * (greatestInitialYVelocity + 1))/2;
};

const validInitialVelocities = (target) => {
  let validInitialVelocities = [];
  for (velX = 0; velX <= target.maxX; velX++) {
    for (velY = target.minY; velY < -target.minY; velY++) {
      const probe = makeProbe(parseInt(velX), parseInt(velY));
      if (probeWillHit(probe, target)) {
        validInitialVelocities.push({velX, velY});
      }
    } 
  }
  return validInitialVelocities;
};

const target = makeTarget(185, 221, -122, -74);

console.log("Greatest trick shot height: " + greatestHeight(target));
console.log("Num of valid initial velocities: " + validInitialVelocities(target).length);
