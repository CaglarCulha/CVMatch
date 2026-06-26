import { HttpError } from "../errors/httpError.js";
import type { ProviderResponse } from "./provider.js";

export class ResponseParser {
  parse(response: ProviderResponse): unknown {
    const jsonText = extractJson(response.content);

    try {
      const parsed = JSON.parse(jsonText);
      if (parsed === null || typeof parsed !== "object" || Array.isArray(parsed)) {
        throw new Error("Provider response must be a JSON object.");
      }

      return parsed;
    } catch {
      throw new HttpError(502, "Analysis provider returned invalid JSON.");
    }
  }
}

function extractJson(content: string): string {
  const trimmed = content.trim();
  const fencedJson = trimmed.match(/^```(?:json)?\s*([\s\S]*?)\s*```$/i);
  if (fencedJson?.[1]) {
    return fencedJson[1].trim();
  }

  const objectStart = trimmed.indexOf("{");
  const objectEnd = trimmed.lastIndexOf("}");
  if (objectStart >= 0 && objectEnd > objectStart) {
    return trimmed.slice(objectStart, objectEnd + 1);
  }

  return trimmed;
}
