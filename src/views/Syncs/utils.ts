import { RJSFSchema } from "@rjsf/utils";
import { flatten } from "flat";

export const convertSchemaToObject = (schema: RJSFSchema): unknown => {
  if (schema?.type === "object") {
    const result: Record<string, unknown> = {};
    if (schema.properties) {
      Object.keys(schema.properties).forEach((property) => {
        if (schema.properties && schema.properties[property]) {
          const value = convertSchemaToObject(
            schema.properties[property] as RJSFSchema
          );

          if (!value || Object.values(value).length > 0) {
            result[property] = value;
          }
        }
      });
    }

    return result;
  } else if (schema?.type === "array") {
    return [convertSchemaToObject(schema.items as RJSFSchema)];
  } else {
    return null;
  }
};

export const getPathFromObject = (schema?: RJSFSchema) => {
  if (!schema) return [];
  const schemaObject = convertSchemaToObject(schema);
  const flattenedObj = flatten(schemaObject);
  return Object.keys(flattenedObj || {});
};
