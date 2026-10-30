import { mergeAttributes, normalizePartCode } from "./normalize";

export interface PartRecord {
  code: string;
  name: string;
  attributes: Record<string, string>;
}

export interface PartSource {
  fetchPart(code: string): Promise<PartRecord | undefined>;
  searchParts(query: string): Promise<PartRecord[] | undefined>;
}

interface CacheEntry {
  record: PartRecord;
  expiresAt: number;
}

const DEFAULT_TTL_MS = 300_000;

export class PartIndex {
  private readonly entries = new Map<string, CacheEntry>();

  constructor(
    private readonly source: PartSource,
    private readonly ttlMs: number = DEFAULT_TTL_MS,
    private readonly now: () => number = Date.now,
  ) {}

  async getByCatalogId(rawCode: string): Promise<PartRecord | undefined> {
    const partCode = normalizePartCode(rawCode);
    const cached = this.entries.get(partCode);
    if (cached && cached.expiresAt > this.now()) {
      return cached.record;
    }
    const record = await this.source.fetchPart(partCode);
    if (record) {
      this.entries.set(partCode, {
        record,
        expiresAt: this.now() + this.ttlMs,
      });
    }
    return record;
  }

  async search(query: string): Promise<PartRecord[] | undefined> {
    return this.source.searchParts(query);
  }

  withAttributes(
    record: PartRecord,
    updates: Record<string, string>,
  ): PartRecord {
    return { ...record, attributes: mergeAttributes(record.attributes, updates) };
  }
}
