import assert from "node:assert/strict";
import { test } from "node:test";
import { PartIndex, PartRecord, PartSource } from "../../src/lookup/part_index";

const GASKET: PartRecord = {
  code: "gasket-12",
  name: "Pump gasket",
  attributes: { material: "rubber" },
};

function sourceWith(record: PartRecord | undefined) {
  let fetches = 0;
  const source: PartSource = {
    async fetchPart() {
      fetches += 1;
      return record;
    },
    async searchParts() {
      return record ? [record] : undefined;
    },
  };
  return { source, fetchCount: () => fetches };
}

test("a second lookup is served from the cache", async () => {
  const { source, fetchCount } = sourceWith(GASKET);
  const index = new PartIndex(source);
  await index.getByCatalogId("GASKET-12");
  await index.getByCatalogId("gasket-12");
  assert.equal(fetchCount(), 1);
});

test("an unknown code is fetched again on the next lookup", async () => {
  const { source, fetchCount } = sourceWith(undefined);
  const index = new PartIndex(source);
  await index.getByCatalogId("missing-1");
  await index.getByCatalogId("missing-1");
  assert.equal(fetchCount(), 2);
});

test("an expired record is fetched again", async () => {
  const { source, fetchCount } = sourceWith(GASKET);
  let clock = 0;
  const index = new PartIndex(source, 1000, () => clock);
  await index.getByCatalogId("gasket-12");
  clock = 1001;
  await index.getByCatalogId("gasket-12");
  assert.equal(fetchCount(), 2);
});
