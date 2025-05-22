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
      // If it's an object, process nested private_key
      if (data && typeof data === 'object') {
        const processed = { ...data };
        if (processed.credentials_json?.private_key) {
          processed.credentials_json.private_key = processed.credentials_json.private_key.replace(/\\n/g, '\n');
        }
        return processed;
      }
      return data;
    }
    
    // Convert FormData to a regular object
    const formObject: Record<string, any> = {};
    
    // Iterate through all entries in the FormData
    for (const [key, value] of data.entries()) {
      try {
        // Try to parse JSON values
        const parsedValue = JSON.parse(value as string);
        if (typeof parsedValue === 'object' && parsedValue?.private_key) {
          // Handle private_key in nested objects
          parsedValue.private_key = parsedValue.private_key.replace(/\\n/g, '\n');
        }
        formObject[key] = parsedValue;
      } catch {
        // If parsing fails, use the raw value
        formObject[key] = value;
      }
    }
    
    return formObject;
  } catch (error) {
    console.error('Error processing form data:', error);
    return data;
  }
};