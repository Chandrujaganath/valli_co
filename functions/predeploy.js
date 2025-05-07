// functions/predeploy.js

const { execSync } = require("child_process");
const path = require("path");

const resourceDir = process.argv[2];

try {
  // Resolve the absolute path to ensure it works on Windows
  const resolvedPath = path.resolve(resourceDir);
  
  // Run npm run lint in the resource directory
  execSync("npm run lint", { cwd: resolvedPath, stdio: "inherit" });
  console.log("Linting passed.");
} catch (error) {
  console.error("Linting failed.");
  process.exit(1);
}
