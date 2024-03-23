export type ConnectorTypes = 'source' | 'destination' | 'model';

export type DatasourceType = {
  icon: string;
  name: string;
};

type LinksType = {
  first: string;
  last: string;
  next: string;
  prev: string;
  self: string;
};

export type ApiResponse<T> = {
  success: boolean;
  data: T;
  links?: LinksType;
};

export type TestConnectionPayload = {
  type: string;
  name: string;
  connection_spec: unknown;
};

export type TestConnectionResponse = {
  type: 'connection_status';
  connection_status: {
    status: 'failed' | 'succeeded';
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
  status: 'failed' | 'success' | 'loading';
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
    connector_type: 'source' | 'destination';
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

export type ConnectorAttributes = {
  connector_name: string;
  connector_type: string;
  configuration: unknown;
  name: string;
  description: string;
  icon: string;
  updated_at: string;
  status: string;
};

export type ConnectorItem = {
  attributes: ConnectorAttributes;
  id: string;
};

export type ConnectorInfoResponse = {
  data: ConnectorItem;
};

export type ConnectorListResponse = {
  data: ConnectorItem[];
};

export type ConnectorTableColumnFields =
  | 'connector_name'
  | 'icon'
  | 'updated_at'
  | 'status'
  | 'name';

export type SourceListColumnType = {
  key: ConnectorTableColumnFields;
  name: string;
};

export type Connector = {
  icon: string;
  name: string;
  title: string;
  category: string;
  connector_spec: Record<string, unknown>;
};
