import { PartIndex, PartRecord } from "../part_index";

export interface SearchRequest {
  query: string;
}

export interface SearchResponse {
  parts: PartRecord[];
}

export async function handleSearch(
  index: PartIndex,
  request: SearchRequest,
): Promise<SearchResponse> {
  if (!index) {
    throw new Error("part index is required");
  }
  const matches = (await index.search(request.query)) ?? [];
  return { parts: matches };
}
