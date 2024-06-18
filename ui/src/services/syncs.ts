import {
  CreateSyncPayload,
  CreateSyncResponse,
  DiscoverResponse,
  ErrorResponse,
  SyncRecordResponse,
  SyncsConfigurationForTemplateMapping,
  SyncRunsResponse,
} from '@/views/Activate/Syncs/types';
import { multiwovenFetch, ApiResponse } from './common';

export const getCatalog = (connectorId: string): Promise<DiscoverResponse> =>
  multiwovenFetch<null, DiscoverResponse>({
    method: 'get',
    url: `/connectors/${connectorId}/discover`,
  });

export const createSync = (payload: CreateSyncPayload): Promise<ApiResponse<CreateSyncResponse>> =>
  multiwovenFetch<CreateSyncPayload, ApiResponse<CreateSyncResponse>>({
    method: 'post',
    url: '/syncs',
    data: payload,
  });

export const fetchSyncs = (): Promise<ApiResponse<CreateSyncResponse[] | ErrorResponse>> =>
  multiwovenFetch<null, ApiResponse<CreateSyncResponse[]>>({
    method: 'get',
    url: `/syncs`,
  });

export const getSyncById = (id: string): Promise<ApiResponse<CreateSyncResponse>> =>
  multiwovenFetch<null, ApiResponse<CreateSyncResponse>>({
    method: 'get',
    url: `/syncs/${id}`,
  });

export const getSyncRunsBySyncId = (
  id: string,
  page: string = '1',
): Promise<ApiResponse<Array<SyncRunsResponse>>> =>
  multiwovenFetch<null, ApiResponse<Array<SyncRunsResponse>>>({
    method: 'get',
    url: `/syncs/${id}/sync_runs?page=${page}&per_page=10`,
  });

export const getSyncRunById = (
  syncId: string,
  syncRunId: string,
): Promise<ApiResponse<SyncRunsResponse>> =>
  multiwovenFetch<null, ApiResponse<SyncRunsResponse>>({
    method: 'get',
    url: `/syncs/${syncId}/sync_runs/${syncRunId}`,
  });

export const getSyncRecords = (
  syncId: string,
  runId: string,
  page: string = '1',
): Promise<ApiResponse<Array<SyncRecordResponse>>> =>
  multiwovenFetch<null, ApiResponse<Array<SyncRecordResponse>>>({
    method: 'get',
    url: `/syncs/${syncId}/sync_runs/${runId}/sync_records?page=${page}&per_page=10`,
  });

export const editSync = (
  payload: CreateSyncPayload,
  id: string,
): Promise<ApiResponse<CreateSyncResponse>> =>
  multiwovenFetch<CreateSyncPayload, ApiResponse<CreateSyncResponse>>({
    method: 'put',
    url: `/syncs/${id}`,
    data: payload,
  });

export const deleteSync = (id: string): Promise<ApiResponse<CreateSyncResponse>> =>
  multiwovenFetch<null, ApiResponse<CreateSyncResponse>>({
    method: 'delete',
    url: `/syncs/${id}`,
  });

export const getSyncsConfiguration = (): Promise<SyncsConfigurationForTemplateMapping> =>
  multiwovenFetch<null, SyncsConfigurationForTemplateMapping>({
    method: 'get',
    url: `/syncs/configurations`,
  });
