export type ModelSubmitFormValues = {
  modelName: string;
  description: string;
  primaryKey?: string;
};

export type UpdateModelPayload = {
  model: {
    name: string;
    description: string;
    primary_key: string;
    query: string;
    query_type: string;
    connector_id: string;
  };
};
