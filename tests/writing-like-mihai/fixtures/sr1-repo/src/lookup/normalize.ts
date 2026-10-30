export function normalizePartCode(rawCode: string): string {
  return rawCode.trim().toLowerCase();
}

export function mergeAttributes(
  base: Record<string, string>,
  updates: Record<string, string>,
): Record<string, string> {
  const merged: Record<string, string> = { ...base };
  for (const key of Object.keys(updates)) {
    merged[key] = updates[key];
  }
  return merged;
}
