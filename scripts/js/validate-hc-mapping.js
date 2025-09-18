const fs = require("fs");
const path = require("path");

const deltaDir = "output/force-app/main/default/objects";
const mappingsFile = "heroku-connect/heroku-mappings.json";

const json = JSON.parse(fs.readFileSync(mappingsFile));
const mappings = {};
json.mappings.forEach((m) => {
  mappings[m.object_name] = Object.keys(m.config.fields || {});
});

const changedFields = [];

function walkDir(dir, callback) {
  fs.readdirSync(dir).forEach((file) => {
    const fullPath = path.join(dir, file);
    if (fs.statSync(fullPath).isDirectory()) {
      walkDir(fullPath, callback);
    } else {
      callback(fullPath);
    }
  });
}

walkDir(deltaDir, (filePath) => {
  if (filePath.endsWith("__c.field-meta.xml")) {
    const parts = filePath.split(path.sep);
    const objIndex = parts.indexOf("objects") + 1;
    const objectName = parts[objIndex];
    const fieldName = path.basename(filePath).replace(".field-meta.xml", "");
    changedFields.push({ object: objectName, field: fieldName });
  }
});

const matches = changedFields.filter((f) =>
  mappings[f.object]?.includes(f.field)
);

if (matches.length > 0) {
  const comment =
    `The following fields in this PR are mapped in Heroku Connect:\n` +
    matches.map((m) => `- ${m.object}.${m.field}`).join("\n");
  fs.appendFileSync(
    process.env.GITHUB_OUTPUT,
    `comment<<EOF\n${comment}\nEOF\n`
  );
} else {
  fs.appendFileSync(
    process.env.GITHUB_OUTPUT,
    `comment<<EOF\nNo mapped fields changed.\nEOF\n`
  );
}
