import { RJSFSchema } from '@rjsf/utils';
import { flatten } from 'flat';

export const convertSchemaToObject = (schema: RJSFSchema): unknown => {
  if (schema?.type === 'object') {
    const result: Record<string, unknown> = {};
    if (schema.properties) {
      Object.keys(schema.properties).forEach((property) => {
        if (schema.properties && schema.properties[property]) {
          const value = convertSchemaToObject(schema.properties[property] as RJSFSchema);

          if (!value || Object.values(value).length > 0) {
            result[property] = value;
          }
        }
      });
    }

    return result;
  } else if (schema?.type === 'array') {
    return [convertSchemaToObject(schema.items as RJSFSchema)];
  } else {
    return null;
  }
};

export const getRequiredProperties = (schema?: RJSFSchema, parentKey = ''): string[] => {
  const requiredProperties: string[] = [];

  if (schema?.type === 'object' && schema.properties) {
    Object.keys(schema.properties).forEach((property) => {
      const propertySchema = schema?.properties?.[property] as RJSFSchema;
      const propertyKey = parentKey ? `${parentKey}.${property}` : property;

      if (schema.required && schema.required.includes(property)) {
        requiredProperties.push(propertyKey);
      }

      if (propertySchema?.type === 'object') {
        const subRequiredProperties = getRequiredProperties(propertySchema, propertyKey);
        requiredProperties.push(...subRequiredProperties);
      }
    });
  }

  return requiredProperties;
};

export const getPathFromObject = (schema?: RJSFSchema) => {
  if (!schema) return [];
  const schemaObject = convertSchemaToObject(schema);
  const flattenedObj = flatten(schemaObject);
  return Object.keys(flattenedObj || {});
};
