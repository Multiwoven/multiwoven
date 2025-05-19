import { ModelEntity } from '@/views/Models/types';
import { RJSFSchema } from '@rjsf/utils';
import { FieldMap as FieldMapType } from '@/views/Activate/Syncs/types';
import { APIRequestMethod } from '@/services/common';

export type Stream = {
  action: string;
  name: string;
  json_schema: RJSFSchema;
  url: string;
  supported_sync_modes: string[];
};

export type AIStream = {
  action: string;
  name: string;
  url: string;
  supported_sync_modes: string[];
};

export enum SchemaMode {
  schema = 'schema',
  schemaless = 'schemaless',
}

export enum SyncRecordStatus {
  success = 'success',
  failed = 'failed',
}

export type DiscoverResponse = {
  attributes: {
    catalog: {
      streams: Stream[];
      schema_mode: SchemaMode;
      catalog_hash: string;
      connector_id: number;
      workspace_id: number;
      source_defined_cursor: boolean;
    };
  };
  id: string;
};

export type AICatalog = {
  id: string;
  attributes: {
    catalog: {
      streams: AIStream[];
    };
  };
};

export type FieldMap = {
  from: string;
  to: string;
  mapping_type: string;
  isRequired?: boolean;
};

export type SyncsConfigurationForTemplateMapping = {
  data: {
    configurations: {
      catalog_mapping_types: {
        static: Record<string, string>;
        template: {
          filter: Record<string, { description: string }>;
          variable: Record<string, { description: string }>;
        };
      };
    };
  };
};

export type ConfigSync = {
  source_id: string;
  destination_id: string;
  model_id: string;
  schedule_type: string;
  cron_expression: string;
  configuration: FieldMapType[];
  stream_name: string;
};

export interface SyncEntity extends ConfigSync {
  name: string;
  sync_mode: string;
  sync_interval: number;
  sync_interval_unit: string;
  cursor_field?: string;
}

export type CreateSyncPayload = {
  sync: SyncEntity;
};

export type TriggerManualSyncPayload = {
  schedule_sync: {
    sync_id: number;
  };
};

export type ErrorResponse = {
  errors: { detail: string }[];
};

export type CreateSyncResponse = {
  attributes: {
    name: string;
    created_at: Date;
    updated_at: Date;
    configuration: Record<string, string>;
    destination_id: number;
    model_id: number;
    schedule_type: string;
    cron_expression: '';
    source_id: string;
    status: string;
    stream_name: string;
    sync_interval: number;
    sync_interval_unit: 'days';
    sync_mode: 'full_refresh';
    cursor_field: string;
    source: {
      connector_name: string;
      icon: string;
      name: string;
      id: string;
    };
    destination: {
      connector_name: string;
      icon: string;
      name: string;
      id: string;
    };
    model: ModelEntity;
  };
  id: string;
  type: 'syncs';
};

export type SyncColumnFields = 'name' | 'model' | 'destination' | 'lastUpdated' | 'status';

export type SyncColumnEntity = {
  key: SyncColumnFields;
  name: string;
};

export type FinalizeSyncFormFields = {
  name: string;
  description?: string;
  sync_mode: 'full_refresh';
  sync_interval: number;
  sync_interval_unit: 'days';
  schedule_type: string;
  cron_expression: '';
};

export type SyncRunsResponse = {
  attributes: {
    sync_id: string;
    status: string;
    source_id: string;
    destination_id: string;
    started_at: string;
    finished_at: string;
    created_at: string;
    updated_at: string;
    duration: number | null;
    total_query_rows: number;
    skipped_rows: number;
    total_rows: number;
    successful_rows: number;
    failed_rows: number;
    error: ErrorResponse | null;
    sync_run_type: string;
  };
  id: string;
  type: 'sync_runs';
};

export type SyncRunsColumnFields =
  | 'status'
  | 'start_time'
  | 'sync_run_type'
  | 'duration'
  | 'rows_queried'
  | 'skipped_rows'
  | 'results';

export type SyncRunsColumnEntity = {
  key: SyncRunsColumnFields;
  name: string;
  hasHoverText?: boolean;
  hoverText?: string;
};

export type SyncRecordResponse = {
  id: string;
  type: 'sync_records';
  attributes: {
    sync_id: string;
    sync_run_id: string;
    record: Record<string, string | null>;
    status: SyncRecordStatus;
    action: 'destination_insert' | 'destination_update' | 'destination_delete';
    logs: {
      request: string;
      response: string;
      level: string;
    };
    created_at: string;
    updated_at: string;
  };
};

export type TriggerSyncButtonProps = {
  isSubmitting: boolean;
  showCancelSync: boolean;
  onClick: (method: APIRequestMethod) => void;
};

export type ChangeSyncStatusPayload = { enable: boolean };
