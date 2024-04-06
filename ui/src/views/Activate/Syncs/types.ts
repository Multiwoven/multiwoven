import { ModelEntity } from '@/views/Models/types';
import { RJSFSchema } from '@rjsf/utils';
import { FieldMap as FieldMapType } from '@/views/Activate/Syncs/types';

export type Stream = {
  action: string;
  name: string;
  json_schema: RJSFSchema;
  url: string;
};

export type DiscoverResponse = {
  data: {
    attributes: {
      catalog: {
        streams: Stream[];
        catalog_hash: string;
        connector_id: number;
        workspace_id: number;
      };
    };
    id: string;
    type: 'catalogs';
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
          variable: Record<string, string>;
        };
      };
    };
  };
};

export type ConfigSync = {
  source_id: string;
  destination_id: string;
  model_id: string;
  schedule_type: 'automated';
  configuration: FieldMapType[];
  stream_name: string;
};

export interface SyncEntity extends ConfigSync {
  sync_mode: string;
  sync_interval: number;
  sync_interval_unit: string;
}

export type CreateSyncPayload = {
  sync: SyncEntity;
};

export type ErrorResponse = {
  errors: { detail: string }[];
};

export type CreateSyncResponse = {
  attributes: {
    created_at: Date;
    updated_at: Date;
    configuration: Record<string, string>;
    destination_id: number;
    model_id: number;
    schedule_type: 'automated';
    source_id: string;
    status: string;
    stream_name: string;
    sync_interval: number;
    sync_interval_unit: 'minutes';
    sync_mode: 'full_refresh';
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

export type SyncColumnFields = 'model' | 'destination' | 'lastUpdated' | 'status';

export type SyncColumnEntity = {
  key: SyncColumnFields;
  name: string;
};

export type FinalizeSyncFormFields = {
  description?: string;
  sync_mode: 'full_refresh';
  sync_interval: number;
  sync_interval_unit: 'minutes';
  schedule_type: 'automated';
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
    total_rows: number;
    successful_rows: number;
    failed_rows: number;
    error: ErrorResponse | null;
  };
  id: string;
  type: 'sync_runs';
};

export type SyncRunsColumnFields =
  | 'status'
  | 'start_time'
  | 'duration'
  | 'rows_queried'
  | 'results';

export type SyncRunsColumnEntity = {
  key: SyncRunsColumnFields;
  name: string;
};

export type SyncRecordResponse = {
  id: string;
  type: 'sync_records';
  attributes: {
    sync_id: string;
    sync_run_id: string;
    record: Record<string, string | null>;
    status: string;
    action: 'destination_insert' | 'destination_update' | 'destination_delete';
    error: null;
    created_at: string;
    updated_at: string;
  };
};
