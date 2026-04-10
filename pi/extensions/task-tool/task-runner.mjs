/**
 * Core logic for the task tool - no pi dependencies.
 */

import { spawn } from "node:child_process";
import path from "node:path";

export function buildPiArgs(agentName, task, agentsDir) {
  const agentPath = path.join(agentsDir, `${agentName}.md`);
  return ["-p", "--no-session", "--append-system-prompt", agentPath, task];
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

    proc.on("close", (code) => {
      resolve({
        exitCode: code ?? 1,
        output: stdout,
        error: stderr,
        aborted,
      });
    });

    proc.on("error", (err) => {
      resolve({
        exitCode: 1,
        output: stdout,
        error: err.message,
        aborted,
      });
    });

    if (signal) {
      const kill = () => {
        aborted = true;
        proc.kill("SIGTERM");
      };
      if (signal.aborted) {
        kill();
      } else {
        signal.addEventListener("abort", kill, { once: true });
      }
    }
  });
}
