import { DiscoverResponse } from "@/views/Syncs/types";
import { multiwovenFetch } from "./common";

export const getCatalog = (connectorId: string): Promise<DiscoverResponse> =>
  multiwovenFetch<null, DiscoverResponse>({
    method: "get",
    url: `/connectors/${connectorId}/discover`,
  });
