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
    url: "/syncs",
    data: payload,
  });

export const fetchSyncs = (): Promise<ApiResponse<CreateSyncResponse[]>> =>
  multiwovenFetch<null, ApiResponse<CreateSyncResponse[]>>({
    method: "get",
    url: `/syncs`,
  });

export const getSyncById = (
  id: string
): Promise<ApiResponse<CreateSyncResponse>> =>
  multiwovenFetch<null, ApiResponse<CreateSyncResponse>>({
    method: "get",
    url: `/syncs/${id}`,
  });
