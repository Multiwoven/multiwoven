import { Connector, TestConnectionPayload } from "./types";

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

export const getDestinationCategories = (data: Connector[]): string[] => [
  "All Destinations",
  ...new Set(data.map((item) => item.category)),
];
