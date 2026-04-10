/**
 * Task tool extension for pi.
 *
 * Provides a `task` tool that spawns an isolated pi process
 * to run an agent. Optionally appends a named agent's .md file
 * to the system prompt. Without an agent name, spawns a generic
 * agent that discovers and uses available skills on its own.
 */

import * as fs from "node:fs";
import * as path from "node:path";
import type { ExtensionAPI } from "@mariozechner/pi-coding-agent";
import { Type } from "@sinclair/typebox";
import { resolveAgent, buildPiArgs, runSubagent } from "./task-runner.mjs";

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
      "Delegate work to a specialized agent. Spawns an isolated pi process. " +
      "Can be used with a named agent (subagent_type) for a specific workflow, " +
      "or with just a prompt to spawn a generic agent that will discover and use " +
      "available skills on its own.",
    parameters: Type.Object({
      subagent_type: Type.Optional(Type.String({
        description: "Agent name, e.g. micro-tdd-agent. If omitted, spawns a generic agent.",
      })),
      prompt: Type.String({
        description: "Task description to send to the agent",
      }),
    }),

    async execute(_toolCallId, params, signal, _onUpdate, ctx) {
      const { subagent_type: agentName, prompt } = params;

      const { agentPath, error } = resolveAgent(agentName, findAgentsDir());
      if (error) {
        return { content: [{ type: "text", text: error }], isError: true };
      }

      const args = buildPiArgs(agentPath, prompt);
      const result = await runSubagent("pi", args, ctx.cwd, signal);

      if (result.aborted) {
        return { content: [{ type: "text", text: "Task aborted." }], isError: true };
      }

      if (result.exitCode !== 0) {
        const errorText = result.error || result.output || "(no output)";
        return {
          content: [{ type: "text", text: `Task failed (exit ${result.exitCode}):\n${errorText}` }],
          isError: true,
        };
      }

      return { content: [{ type: "text", text: result.output || "(no output)" }] };
    },
  });
}
