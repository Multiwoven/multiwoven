import { TestConnectionPayload } from "./types";

export const processConnectorConfigData = (
  formData: unknown
): TestConnectionPayload | null => {
  if (!formData) return null;

  return {
    connection_spec: formData,
    type: "source",
    name: "Snowflake",
  };
};
