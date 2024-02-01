import { ALL_DESTINATIONS_CATEGORY } from "./constant";
import { Connector, ConnectorTypes, TestConnectionPayload } from "./types";

export const processConnectorConfigData = (
  formData: unknown,
  selectedDataSource: string,
  type: ConnectorTypes
): TestConnectionPayload | null => {
  if (!formData) return null;

  return {
    connection_spec: formData,
    name: selectedDataSource,
    type,
  };
};

export const getDestinationCategories = (data: Connector[]): string[] => [
  ALL_DESTINATIONS_CATEGORY,
  ...new Set(data.map((item) => item.category)),
];
