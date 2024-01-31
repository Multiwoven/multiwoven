import { CreateConnectorResponse } from "../Connectors/types";

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
        [key: string] : string | null;
      }
    };
    id: string;
    type: string;
};