import {
  CreateSyncPayload,
  CreateSyncResponse,
  DiscoverResponse,
  SyncRecordResponse,
  SyncsConfigurationForTemplateMapping,
  SyncRunsResponse,
  TriggerManualSyncPayload,
  ChangeSyncStatusPayload,
} from '@/views/Activate/Syncs/types';
import { multiwovenFetch, ApiResponse, APIRequestMethod } from './common';
<<<<<<< HEAD
=======
import { enterpriseMultiwovenFetch } from '@/enterprise/services/axios';
import { MessageResponse } from './authentication';
import { buildUrlWithParams } from './utils';
>>>>>>> 9bfb0995 (refactor(CE): lists filtering and query params building (#860))

export const getCatalog = (
  connectorId: string,
  refresh: boolean = false,
): Promise<ApiResponse<DiscoverResponse>> =>
  multiwovenFetch<null, ApiResponse<DiscoverResponse>>({
    method: 'get',
    url: `/connectors/${connectorId}/discover?refresh=${refresh}`,
  });

export const createSync = (payload: CreateSyncPayload): Promise<ApiResponse<CreateSyncResponse>> =>
  multiwovenFetch<CreateSyncPayload, ApiResponse<CreateSyncResponse>>({
    method: 'post',
    url: '/syncs',
    data: payload,
  });

export const fetchSyncs = (): Promise<ApiResponse<CreateSyncResponse[]>> =>
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
  isFiltered: boolean = false,
  status: string = 'success',
): Promise<ApiResponse<Array<SyncRecordResponse>>> =>
  multiwovenFetch<null, ApiResponse<Array<SyncRecordResponse>>>({
    method: 'get',
    url: buildUrlWithParams(`/syncs/${syncId}/sync_runs/${runId}/sync_records`, {
      page,
      per_page: '10',
      status: isFiltered ? status : undefined,
    }),
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

export const triggerManualSync = (
  payload: TriggerManualSyncPayload,
  method: APIRequestMethod,
): Promise<ApiResponse<CreateSyncResponse>> =>
  multiwovenFetch<TriggerManualSyncPayload, ApiResponse<CreateSyncResponse>>({
    method,
    url: '/schedule_syncs',
    data: payload,
  });

export const cancelManualSyncSchedule = (id: string): Promise<ApiResponse<CreateSyncResponse>> =>
  multiwovenFetch<null, ApiResponse<CreateSyncResponse>>({
    method: 'delete',
    url: `/schedule_syncs/${id}`,
  });

export const changeSyncStatus = (
  id: string,
  payload: ChangeSyncStatusPayload,
): Promise<ApiResponse<CreateSyncResponse>> =>
  multiwovenFetch<ChangeSyncStatusPayload, ApiResponse<CreateSyncResponse>>({
    method: 'patch',
    url: `/syncs/${id}/enable`,
    data: payload,
  });
