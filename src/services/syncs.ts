import {
  CreateSyncPayload,
  CreateSyncResponse,
  DiscoverResponse,
} from "@/views/Activate/Syncs/types";
import { multiwovenFetch } from "./common";
import { ApiResponse } from "@/views/Connectors/types";

export const getCatalog = (connectorId: string): Promise<DiscoverResponse> =>
  multiwovenFetch<null, DiscoverResponse>({
    method: "get",
    url: `/connectors/${connectorId}/discover`,
  });

export const createSync = (
  payload: CreateSyncPayload
): Promise<ApiResponse<CreateSyncResponse>> =>
  multiwovenFetch<CreateSyncPayload, ApiResponse<CreateSyncResponse>>({
    method: "post",
    url: `/syncs`,
    data: payload,
  });
