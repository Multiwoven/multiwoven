import { ALL_DESTINATIONS_CATEGORY } from './constant';
import { Connector, ConnectorTypes, TestConnectionPayload } from './types';

export const processConnectorConfigData = (
  formData: unknown,
  selectedDataSource: string,
  type: ConnectorTypes,
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

export const processFormData = (data: any) => {
  try {
    // If data is already an object (not FormData), just return it
    if (!(data instanceof FormData)) {
      return data;
    }
    
    // Convert FormData to a regular object
    const formObject: Record<string, any> = {};
    
    // Iterate through all entries in the FormData
    for (const [key, value] of data.entries()) {
      formObject[key] = value;
    }
    
    return formObject;
  } catch (error) {
    // Return an empty object as fallback
    return {};
  }
};
