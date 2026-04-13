/**
 * Core logic for the task tool - no pi dependencies.
 */

import { spawn } from "node:child_process";
import fs from "node:fs";
import path from "node:path";

export function resolveAgent(agentName, agentsDir) {
  if (!agentName) return { agentPath: null };
  if (!agentsDir) return { error: "No agents directory found." };

  const agentPath = path.join(agentsDir, `${agentName}.md`);
  try {
    fs.accessSync(agentPath);
    return { agentPath };
  } catch {
    const available = fs.readdirSync(agentsDir)
      .filter((f) => f.endsWith(".md"))
      .map((f) => f.replace(/\.md$/, ""));
    return { error: `Agent "${agentName}" not found. Available: ${available.join(", ") || "none"}` };
  }
}

export function buildPiArgs(agentPath, task) {
  const args = ["-p", "--no-session"];
  if (agentPath) {
    args.push("--append-system-prompt", agentPath);
  }
  args.push(task);
  return args;
}

export function runSubagent(command, args, cwd, signal) {
  return new Promise((resolve) => {
    let stdout = "";
    let stderr = "";
    let aborted = false;

    const proc = spawn(command, args, {
      cwd,
      shell: false,
      stdio: ["ignore", "pipe", "pipe"],
    });

    proc.stdout.on("data", (data) => {
      stdout += data.toString();
    });

    proc.stderr.on("data", (data) => {
      stderr += data.toString();
    });

    // 'exit' not 'close' — 'close' waits for all stdio streams to end,
    // which hangs if a grandchild process inherits the pipe file descriptors.
    proc.on("exit", (code) => {
      proc.stdout.destroy();
      proc.stderr.destroy();
      if (cleanupSignal) cleanupSignal();
      resolve({
        exitCode: code ?? 1,
        output: stdout,
        error: stderr,
        aborted,
      });
    });

    proc.on("error", (err) => {
      if (cleanupSignal) cleanupSignal();
      resolve({
        exitCode: 1,
        output: stdout,
        error: err.message,
        aborted,
      });
    });

    let cleanupSignal = null;
    if (signal) {
      const kill = () => {
        aborted = true;
        proc.kill("SIGTERM");
      };
      if (signal.aborted) {
        kill();
      } else {
        signal.addEventListener("abort", kill, { once: true });
        cleanupSignal = () => signal.removeEventListener("abort", kill);
      }
    }
  });
}
