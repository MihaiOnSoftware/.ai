/**
 * Task tool extension for pi.
 *
 * Provides a `task` tool that spawns an isolated pi process
 * to run an agent via prompt template invocation.
 */

import type { ExtensionAPI } from "@mariozechner/pi-coding-agent";
import { Type } from "@sinclair/typebox";
import { buildPiArgs, runSubagent } from "./task-runner.mjs";

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
      const args = buildPiArgs(agentName, prompt);
      const piCommand = "pi";

      const result = await runSubagent(piCommand, args, ctx.cwd, signal);

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
