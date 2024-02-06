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
