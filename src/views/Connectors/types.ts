export type ConnectorTypes = "source" | "destination" | "model";

export type DatasourceType = {
  icon: string;
  name: string;
};

export type ApiResponse<T> = {
  success: boolean;
  data: T;
};
