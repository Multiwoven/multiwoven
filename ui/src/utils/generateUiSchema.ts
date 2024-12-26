export const generateUiSchema = (
  schemaProperties: object,
  uiSchema: Record<string, any> = {},
  path: string[] = [],
): Record<string, string> => {
  Object.entries(schemaProperties).forEach(([key, value]) => {
    if (key === 'properties' && typeof value === 'object' && value !== null) {
      generateUiSchema(value, uiSchema, path);
    } else if (typeof value === 'object' && value !== null) {
      const nestedObject = key === 'properties' ? path : path.concat(key);
      generateUiSchema(value, uiSchema, nestedObject);
    } else if (key === 'multiwoven_secret' && value === true) {
      let current = uiSchema;
      path.forEach((schemaPath, index) => {
        if (index === path.length - 1) {
          current[schemaPath] = { 'ui:widget': 'password' };
        } else {
          current[schemaPath] = current[schemaPath] || {};
        }
        current = current[schemaPath];
      });
    } else if (key === 'x-request-format') {
      let current = uiSchema;
      path.forEach((schemaPath, index) => {
        if (index === path.length - 1) {
          current[schemaPath] = { 'ui:widget': 'requestFormat' };
        } else {
          current[schemaPath] = current[schemaPath] || {};
        }
        current = current[schemaPath];
      });
    } else if (key === 'x-response-format') {
      let current = uiSchema;
      path.forEach((schemaPath, index) => {
        if (index === path.length - 1) {
          current[schemaPath] = { 'ui:widget': 'responseFormat' };
        } else {
          current[schemaPath] = current[schemaPath] || {};
        }
        current = current[schemaPath];
      });
    }
  });

  return uiSchema;
};
