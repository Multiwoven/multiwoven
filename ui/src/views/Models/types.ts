export type CreateModelPayload = {
  model: {
    connector_id: number;
    name: string;
    description: string;
    query: string;
    query_type: string;
    primary_key: string;
  };
};

export type CreateModelResponse = {
  data: {
    attributes: unknown;
    id: string;
    type: string;
  };
};

export type GetModelByIdResponse = {
  attributes: {
    connector_id: number;
    created_at: string;
    description: string;
    id: string;
    name: string;
    primary_key: string;
    query: string;
    query_type: string;
    updated_at: string;
    connector: {
      [key: string]: string | null;
    };
  };
  id: string;
  type: string;
};

export type ModelEntity = {
  connector: {
    id: number;
    name: string;
    description: string | null;
    connector_type: 'source';
    workspace_id: number;
    created_at: string;
    updated_at: string;
    configuration: Record<string, unknown>;
    connector_name: string;
    icon: string;
  };
  description: null;
  created_at: string;
  query: string;
  query_type: string;
  updated_at: string;
  id: string;
  icon: string;
  name: string;
};

export type ModelColumnFields = 'name' | 'query_type' | 'last_updated';

export type ModelColumnEntity = {
  key: ModelColumnFields;
  name: string;
};
