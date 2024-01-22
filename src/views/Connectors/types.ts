export type ConnectorTypes = "source" | "destination" | "model";

export type DatasourceType = {
  icon: string;
  name: string;
};

export type ApiResponse<T> = {
  success: boolean;
  data: T;
};

export type TestConnectionPayload = {
  type: string;
  name: string;
  connection_spec: unknown;
};

export type TestConnectionResponse = {
  type: "connection_status";
  connection_status: {
    status: "failed" | "succeeded";
    message: string;
  };
};

export type ConnectionStatusProps = {
  data: TestConnectionResponse | undefined;
  isLoading: boolean;
  configFormData: unknown;
  datasource: string;
};

export type ConnectionStatusMetaData = {
  status: "failed" | "success" | "loading";
  text: string;
};

export type ConnectionStatus = {
  name: string;
  status: ({
    data,
    isLoading,
    configFormData,
    datasource,
  }: ConnectionStatusProps) => ConnectionStatusMetaData;
};

export type CreateConnectorPayload = {
  connector: {
    configuration: unknown;
    name: string;
    connector_type: "source" | "destination";
    connector_name: string;
    description: string;
  };
};

export type CreateConnectorResponse = {
  data: {
    attributes: unknown;
    id: string;
    type: string;
  };
};
