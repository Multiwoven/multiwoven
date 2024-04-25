export function generateUiSchema(
  schemaProperties: object,
  uiSchema: Record<string, any> = {},
  path: string[] = [],
): Record<string, string> {
  Object.entries(schemaProperties).forEach(([key, value]) => {
    if (key === 'properties' && typeof value === 'object' && value !== null) {
      generateUiSchema(value, uiSchema, path);
    } else if (typeof value === 'object' && value !== null) {
      const nestedObject = key === 'properties' ? path : path.concat(key);
      generateUiSchema(value, uiSchema, nestedObject);
    } else if (key === 'multiwoven_secret' && value === true) {
      let current = uiSchema;
      path.forEach((p, i) => {
        if (i === path.length - 1) {
          current[p] = { 'ui:widget': 'password' };
        } else {
          current[p] = current[p] || {};
        }
        current = current[p];
      });
    }
  });

  return uiSchema;
}
