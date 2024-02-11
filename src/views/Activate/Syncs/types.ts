import { ModelEntity } from "@/views/Models/types";
import { RJSFSchema } from "@rjsf/utils";

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
    type: "catalogs";
  };
};

export type FieldMap = {
  model: string;
  destination: string;
};

export type ConfigSync = {
  source_id: number;
  destination_id: number;
  model_id: number;
  schedule_type: "automated";
  configuration: Record<string, unknown>;
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

export type CreateSyncResponse = {
  attributes: {
    created_at: Date;
    updated_at: Date;
    configuration: Record<string, string>;
    destination_id: number;
    model_id: number;
    schedule_type: "automated";
    source_id: number;
    status: string;
    stream_name: string;
    sync_interval: number;
    sync_interval_unit: "minutes";
    sync_mode: "full_refresh";
    source: {
      connector_name: string;
      icon: string;
      name: string;
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
  type: "syncs";
};

export type SyncColumnFields =
  | "model"
  | "destination"
  | "lastUpdated"
  | "status";

export type SyncColumnEntity = {
  key: SyncColumnFields;
  name: string;
};

export type FinalizeSyncFormFields = {
  description?: string;
  sync_mode: "full_refresh";
  sync_interval: number;
  sync_interval_unit: "minutes";
  schedule_type: "automated";
};
