import { describe, it } from "node:test";
import assert from "node:assert/strict";
import { resolveAgent, buildPiArgs, runSubagent } from "./task-runner.mjs";

describe("buildPiArgs", () => {
  it("builds args with agent path as system prompt and task as message", () => {
    const args = buildPiArgs(
      "/home/user/.pi/agent/agents/generic/micro-tdd-agent.md",
      "implement test for config loading",
    );

    assert.deepStrictEqual(args, [
      "-p",
      "--no-session",
      "--append-system-prompt",
      "/home/user/.pi/agent/agents/generic/micro-tdd-agent.md",
      "implement test for config loading",
    ]);
  });

  it("builds args without agent path for generic invocation", () => {
    const args = buildPiArgs(null, "review this code for bugs");

    assert.deepStrictEqual(args, [
      "-p",
      "--no-session",
      "review this code for bugs",
    ]);
  });
});

describe("resolveAgent", () => {
  it("returns null agentPath when no agent name given", () => {
    const result = resolveAgent(null, "/some/dir");
    assert.deepStrictEqual(result, { agentPath: null });
  });

  it("returns error when agent name given but no agents dir", () => {
    const result = resolveAgent("review", null);
    assert.ok(result.error);
  });

  it("returns error when agent file does not exist", () => {
    const result = resolveAgent("nonexistent", "/tmp");
    assert.ok(result.error);
    assert.match(result.error, /not found/);
  });
});

describe("runSubagent", () => {
  it("captures stdout from a successful process", async () => {
    const result = await runSubagent("echo", ["hello from agent"], process.cwd());

    assert.equal(result.exitCode, 0);
    assert.equal(result.output.trim(), "hello from agent");
    assert.equal(result.error, "");
  });

  it("captures stderr and non-zero exit code on failure", async () => {
    const result = await runSubagent("sh", ["-c", "echo oops >&2; exit 1"], process.cwd());

    assert.equal(result.exitCode, 1);
    assert.equal(result.error.trim(), "oops");
  });

  it("can be aborted via signal", async () => {
    const controller = new AbortController();
    const promise = runSubagent("sleep", ["10"], process.cwd(), controller.signal);

    controller.abort();
    const result = await promise;

    assert.equal(result.aborted, true);
  });
});
