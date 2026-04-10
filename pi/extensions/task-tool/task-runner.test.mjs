import { describe, it } from "node:test";
import assert from "node:assert/strict";
import { buildPiArgs, runSubagent } from "./task-runner.mjs";

describe("buildPiArgs", () => {
  it("returns pi print mode args with prompt template invocation", () => {
    const args = buildPiArgs("micro-tdd-agent", "implement test for config loading");

    assert.deepStrictEqual(args, [
      "-p",
      "--no-session",
      "/micro-tdd-agent implement test for config loading",
    ]);
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
