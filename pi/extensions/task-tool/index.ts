/**
 * Task tool extension for pi.
 *
 * Provides a `task` tool that spawns an isolated pi process
 * to run an agent. The agent .md file is appended to the system
 * prompt, and the task is passed as the user message — mirroring
 * how Claude Code's Task tool works.
 */

import * as fs from "node:fs";
import * as path from "node:path";
import type { ExtensionAPI } from "@mariozechner/pi-coding-agent";
import { Type } from "@sinclair/typebox";
import { buildPiArgs, runSubagent } from "./task-runner.mjs";

function findAgentsDir(): string | null {
  const candidates = [
    path.join(process.env.HOME || "", ".pi", "agent", "agents", "generic"),
    path.join(process.env.HOME || "", ".pi", "agent", "agents"),
  ];
  for (const dir of candidates) {
    if (fs.existsSync(dir)) return dir;
  }
  return null;
}

export default function (pi: ExtensionAPI) {
  pi.registerTool({
    name: "task",
    label: "Task",
    description:
      "Delegate work to a specialized agent. Spawns an isolated pi process " +
      "that runs the named agent via prompt template. Use when instructions say " +
      '"Use Task tool (subagent_type=X)".',
    parameters: Type.Object({
      subagent_type: Type.String({
        description: "Agent name, e.g. micro-tdd-agent",
      }),
      prompt: Type.String({
        description: "Task description to send to the agent",
      }),
    }),

    async execute(_toolCallId, params, signal, _onUpdate, ctx) {
      const { subagent_type: agentName, prompt } = params;

      const agentsDir = findAgentsDir();
      if (!agentsDir) {
        return {
          content: [
            {
              type: "text",
              text: "No agents directory found. Run the install script.",
            },
          ],
          isError: true,
        };
      }

      const agentFile = path.join(agentsDir, `${agentName}.md`);
      if (!fs.existsSync(agentFile)) {
        const available = fs.readdirSync(agentsDir)
          .filter((f) => f.endsWith(".md"))
          .map((f) => f.replace(/\.md$/, ""));
        return {
          content: [
            {
              type: "text",
              text: `Agent "${agentName}" not found. Available: ${available.join(", ") || "none"}`,
            },
          ],
          isError: true,
        };
      }

      const args = buildPiArgs(agentName, prompt, agentsDir);
      const result = await runSubagent("pi", args, ctx.cwd, signal);

      if (result.aborted) {
        return {
          content: [{ type: "text", text: "Task aborted." }],
          isError: true,
        };
      }

      if (result.exitCode !== 0) {
        const errorText = result.error || result.output || "(no output)";
        return {
          content: [
            {
              type: "text",
              text: `Agent "${agentName}" failed (exit ${result.exitCode}):\n${errorText}`,
            },
          ],
          isError: true,
        };
      }

      return {
        content: [
          { type: "text", text: result.output || "(no output)" },
        ],
      };
    },
  });
}
