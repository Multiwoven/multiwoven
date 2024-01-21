import { TestConnectionPayload } from "./types";

export const processConnectorConfigData = (
  formData: unknown,
  selectedDataSource: string
): TestConnectionPayload | null => {
  if (!formData) return null;

  return {
    connection_spec: formData,
    type: "source",
    name: selectedDataSource,
  };
};
