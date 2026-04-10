#!/usr/bin/env node

/**
 * Manage pi settings.json - add or remove the prompts path for agent templates.
 *
 * Usage:
 *   node pi_settings.js install
 *   node pi_settings.js uninstall
 */

const fs = require("fs");
const path = require("path");

const settingsPath =
  process.env.PI_SETTINGS_PATH ||
  path.join(process.env.HOME, ".pi", "agent", "settings.json");

const promptsEntry =
  process.env.PI_AGENTS_PROMPTS_PATH ||
  "~/.pi/agent/prompts/agents/generic";

const action = process.argv[2];

if (!action || !["install", "uninstall"].includes(action)) {
  console.error("Usage: node pi_settings.js <install|uninstall>");
  process.exit(1);
}

// Read existing settings or start fresh
let settings = {};
if (fs.existsSync(settingsPath)) {
  try {
    settings = JSON.parse(fs.readFileSync(settingsPath, "utf8"));
  } catch (err) {
    console.error(`Error reading ${settingsPath}: ${err.message}`);
    process.exit(1);
  }
}

if (action === "install") {
  settings.prompts = settings.prompts || [];
  if (!settings.prompts.includes(promptsEntry)) {
    settings.prompts.push(promptsEntry);
    console.log(`Added "${promptsEntry}" to prompts in ${settingsPath}`);
  } else {
    console.log(`"${promptsEntry}" already present in prompts`);
  }
} else {
  if (Array.isArray(settings.prompts)) {
    const before = settings.prompts.length;
    settings.prompts = settings.prompts.filter((p) => p !== promptsEntry);
    if (settings.prompts.length === 0) {
      delete settings.prompts;
    }
    if (before !== (settings.prompts?.length ?? 0)) {
      console.log(`Removed "${promptsEntry}" from prompts in ${settingsPath}`);
    } else {
      console.log(`"${promptsEntry}" not found in prompts`);
    }
  } else {
    console.log("No prompts array in settings, nothing to remove");
  }
}

// Write back
fs.mkdirSync(path.dirname(settingsPath), { recursive: true });
fs.writeFileSync(settingsPath, JSON.stringify(settings, null, 2) + "\n");
