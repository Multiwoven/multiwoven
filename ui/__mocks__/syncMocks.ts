/**
 * Sync mocks
 * Mock functions and constants for sync-related tests
 */

import {
  CreateSyncResponse,
  SyncRunsResponse,
  SyncRecordResponse,
  SyncRecordStatus,
} from '@/views/Activate/Syncs/types';
import { LinksType } from '@/services/common';

// Mock sync data
export const mockSyncData = {
  id: '123',
  attributes: {
    name: 'Test Sync',
    status: 'enabled',
    updated_at: '2024-01-01T00:00:00Z',
    model: {
      id: '1',
      name: 'Test Model',
      connector: {
        name: 'PostgreSQL',
        icon: 'postgres-icon',
        configuration: {
          data_type: 'structured',
        },
      },
    },
    destination: {
      id: '2',
      name: 'Snowflake',
      icon: 'snowflake-icon',
    },
    stream_name: 'test_stream',
    sync_mode: 'full_refresh',
    sync_interval: 0,
    sync_interval_unit: 'minutes',
    schedule_type: 'interval',
    cron_expression: '',
    configuration: [],
  },
};

// Helper function to create mock sync data
const createMockSync = (
  id: string,
  overrides: {
    name: string;
    status: string;
    date: string;
    destinationId: number;
    modelId: number;
    sourceId: string;
    streamName: string;
    modelName: string;
    connectorName: string;
    connectorId: number;
    connectorIcon: string;
    destinationName: string;
    destinationConnectorName: string;
    destinationIcon: string;
    sourceName: string;
    sourceConnectorName: string;
    sourceIcon: string;
  },
): CreateSyncResponse => ({
  id,
  type: 'syncs',
  attributes: {
    name: overrides.name,
    status: overrides.status,
    created_at: new Date(overrides.date),
    updated_at: new Date(overrides.date),
    configuration: {},
    destination_id: overrides.destinationId,
    model_id: overrides.modelId,
    schedule_type: 'interval',
    cron_expression: '',
    source_id: overrides.sourceId,
    stream_name: overrides.streamName,
    sync_interval: 0,
    sync_interval_unit: 'minutes',
    sync_mode: 'full_refresh',
    cursor_field: '',
    model: {
      id: overrides.modelId.toString(),
      name: overrides.modelName,
      description: null,
      created_at: overrides.date,
      updated_at: overrides.date,
      query: '',
      query_type: 'raw_sql',
      icon: overrides.connectorIcon,
      connector: {
        id: overrides.connectorId,
        name: overrides.connectorName,
        description: null,
        connector_type: 'source' as const,
        workspace_id: 1,
        created_at: overrides.date,
        updated_at: overrides.date,
        configuration: {},
        connector_name: overrides.connectorName.toLowerCase(),
        icon: overrides.connectorIcon,
      },
    },
    destination: {
      id: overrides.destinationId.toString(),
      name: overrides.destinationName,
      connector_name: overrides.destinationConnectorName,
      icon: overrides.destinationIcon,
    },
    source: {
      id: overrides.sourceId,
      name: overrides.sourceName,
      connector_name: overrides.sourceConnectorName,
      icon: overrides.sourceIcon,
    },
  },
});

export const mockSyncsList: CreateSyncResponse[] = [
  createMockSync('1', {
    name: 'Sync 1',
    status: 'enabled',
    date: '2024-01-01T00:00:00Z',
    destinationId: 2,
    modelId: 1,
    sourceId: '1',
    streamName: 'stream1',
    modelName: 'Model 1',
    connectorName: 'PostgreSQL',
    connectorId: 1,
    connectorIcon: 'postgres-icon',
    destinationName: 'Snowflake',
    destinationConnectorName: 'snowflake',
    destinationIcon: 'snowflake-icon',
    sourceName: 'PostgreSQL',
    sourceConnectorName: 'postgresql',
    sourceIcon: 'postgres-icon',
  }),
  createMockSync('2', {
    name: 'Sync 2',
    status: 'disabled',
    date: '2024-01-02T00:00:00Z',
    destinationId: 3,
    modelId: 2,
    sourceId: '2',
    streamName: 'stream2',
    modelName: 'Model 2',
    connectorName: 'MySQL',
    connectorId: 2,
    connectorIcon: 'mysql-icon',
    destinationName: 'BigQuery',
    destinationConnectorName: 'bigquery',
    destinationIcon: 'bigquery-icon',
    sourceName: 'MySQL',
    sourceConnectorName: 'mysql',
    sourceIcon: 'mysql-icon',
  }),
] as CreateSyncResponse[];

export const mockSyncRuns: SyncRunsResponse[] = [
  {
    id: '1',
    type: 'sync_runs',
    attributes: {
      sync_id: '123',
      status: 'success',
      source_id: '1',
      destination_id: '2',
      started_at: '2024-01-01T00:00:00Z',
      finished_at: '2024-01-01T00:01:00Z',
      created_at: '2024-01-01T00:00:00Z',
      updated_at: '2024-01-01T00:01:00Z',
      sync_run_type: 'manual',
      duration: 100,
      total_query_rows: 1000,
      skipped_rows: 0,
      total_rows: 1000,
      successful_rows: 1000,
      failed_rows: 0,
      error: null,
    },
  },
];

export const mockSyncRecords: SyncRecordResponse[] = [
  {
    id: '1',
    type: 'sync_records',
    attributes: {
      sync_id: '123',
      sync_run_id: '456',
      record: { id: '1', name: 'Record 1' },
      status: SyncRecordStatus.success,
      action: 'destination_insert',
      logs: {
        request: '{}',
        response: '{}',
        level: 'info',
      },
      created_at: '2024-01-01T00:00:00Z',
      updated_at: '2024-01-01T00:00:00Z',
    },
  },
  {
    id: '2',
    type: 'sync_records',
    attributes: {
      sync_id: '123',
      sync_run_id: '456',
      record: {},
      status: SyncRecordStatus.failed,
      action: 'destination_insert',
      logs: {
        request: '{}',
        response: '{"error": "Error message"}',
        level: 'error',
      },
      created_at: '2024-01-01T00:00:00Z',
      updated_at: '2024-01-01T00:00:00Z',
    },
  },
];

// Mock functions
export const mockUseGetSyncById = jest.fn();
export const mockUseTestSync = jest.fn();
export const mockUseSyncRuns = jest.fn();
export const mockUseEditSync = jest.fn();
export const mockChangeSyncStatus = jest.fn();
export const mockDeleteSync = jest.fn();
export const mockCreateSync = jest.fn();
export const mockFetchSyncs = jest.fn();
export const mockGetSyncRecords = jest.fn();
export const mockSetSelectedSync = jest.fn();

// Mock hook implementations
export const createMockUseGetSyncById = (overrides?: {
  data?: typeof mockSyncData;
  isLoading?: boolean;
  isError?: boolean;
}) => {
  return jest.fn(() => ({
    data: overrides?.data ? { data: overrides.data } : { data: mockSyncData },
    isLoading: overrides?.isLoading ?? false,
    isError: overrides?.isError ?? false,
  }));
};

export const createMockUseTestSync = (overrides?: {
  isSubmitting?: boolean;
  runTestSync?: jest.Mock;
}) => {
  return jest.fn(() => ({
    runTestSync: overrides?.runTestSync || jest.fn(),
    isSubmitting: overrides?.isSubmitting ?? false,
  }));
};

export const createMockUseSyncRuns = (overrides?: {
  data?: typeof mockSyncRuns;
  isLoading?: boolean;
  links?: LinksType;
}) => {
  return jest.fn(() => ({
    data: overrides?.data
      ? { data: overrides.data, links: overrides?.links || {} }
      : { data: mockSyncRuns, links: overrides?.links || {} },
    isLoading: overrides?.isLoading ?? false,
  }));
};
