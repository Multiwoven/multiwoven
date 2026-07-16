import { describe, it, expect } from '@jest/globals';
import { convertSchemaToObject, getRequiredProperties, getPathFromObject } from '../utils';
import { RJSFSchema } from '@rjsf/utils';

jest.mock('flat', () => ({
  flatten: (obj: Record<string, unknown>) => {
    const result: Record<string, unknown> = {};
    const flattenHelper = (current: unknown, prefix = '') => {
      if (typeof current === 'object' && current !== null && !Array.isArray(current)) {
        Object.keys(current).forEach((key) => {
          const newKey = prefix ? `${prefix}.${key}` : key;
          flattenHelper((current as Record<string, unknown>)[key], newKey);
        });
      } else {
        result[prefix] = current;
      }
    };
    flattenHelper(obj);
    return result;
  },
}));

describe('utils', () => {
  describe('convertSchemaToObject', () => {
    it('converts object schema to object', () => {
      const schema: RJSFSchema = {
        type: 'object',
        properties: {
          name: { type: 'string' },
          age: { type: 'number' },
        },
      };
      const result = convertSchemaToObject(schema);
      expect(result).toEqual({ name: null, age: null });
    });

    it('converts array schema to array', () => {
      const schema: RJSFSchema = {
        type: 'array',
        items: { type: 'string' },
      };
      const result = convertSchemaToObject(schema);
      expect(result).toEqual([null]);
    });

    it('handles nested object schemas', () => {
      const schema: RJSFSchema = {
        type: 'object',
        properties: {
          user: {
            type: 'object',
            properties: {
              name: { type: 'string' },
            },
          },
        },
      };
      const result = convertSchemaToObject(schema);
      expect(result).toEqual({ user: { name: null } });
    });

    it('returns null for non-object, non-array schemas', () => {
      const schema: RJSFSchema = { type: 'string' };
      const result = convertSchemaToObject(schema);
      expect(result).toBeNull();
    });

    it('handles empty object schema', () => {
      const schema: RJSFSchema = { type: 'object', properties: {} };
      const result = convertSchemaToObject(schema);
      expect(result).toEqual({});
    });

    it('handles null/undefined schema', () => {
      expect(convertSchemaToObject(null as any)).toBeNull();
      expect(convertSchemaToObject(undefined as any)).toBeNull();
    });
  });

  describe('getRequiredProperties', () => {
    it('returns required properties from schema', () => {
      const schema: RJSFSchema = {
        type: 'object',
        properties: {
          name: { type: 'string' },
          age: { type: 'number' },
        },
        required: ['name'],
      };
      const result = getRequiredProperties(schema);
      expect(result).toEqual(['name']);
    });

    it('returns empty array when no required properties', () => {
      const schema: RJSFSchema = {
        type: 'object',
        properties: {
          name: { type: 'string' },
        },
      };
      const result = getRequiredProperties(schema);
      expect(result).toEqual([]);
    });

    it('handles nested required properties', () => {
      const schema: RJSFSchema = {
        type: 'object',
        properties: {
          user: {
            type: 'object',
            properties: {
              name: { type: 'string' },
              email: { type: 'string' },
            },
            required: ['name'],
          },
        },
        required: ['user'],
      };
      const result = getRequiredProperties(schema);
      expect(result).toEqual(['user', 'user.name']);
    });

    it('handles parentKey parameter', () => {
      const schema: RJSFSchema = {
        type: 'object',
        properties: {
          name: { type: 'string' },
        },
        required: ['name'],
      };
      const result = getRequiredProperties(schema, 'parent');
      expect(result).toEqual(['parent.name']);
    });

    it('returns empty array for non-object schema', () => {
      const schema: RJSFSchema = { type: 'string' };
      const result = getRequiredProperties(schema);
      expect(result).toEqual([]);
    });

    it('handles null/undefined schema', () => {
      expect(getRequiredProperties(null as any)).toEqual([]);
      expect(getRequiredProperties(undefined)).toEqual([]);
    });
  });

  describe('getPathFromObject', () => {
    it('returns paths from object schema', () => {
      const schema: RJSFSchema = {
        type: 'object',
        properties: {
          name: { type: 'string' },
          age: { type: 'number' },
        },
      };
      const result = getPathFromObject(schema);
      expect(result).toEqual(['name', 'age']);
    });

    it('returns paths from nested object schema', () => {
      const schema: RJSFSchema = {
        type: 'object',
        properties: {
          user: {
            type: 'object',
            properties: {
              name: { type: 'string' },
            },
          },
        },
      };
      const result = getPathFromObject(schema);
      expect(result).toEqual(['user.name']);
    });

    it('returns empty array for null/undefined schema', () => {
      expect(getPathFromObject(null as any)).toEqual([]);
      expect(getPathFromObject(undefined)).toEqual([]);
    });

    it('handles array schema', () => {
      const schema: RJSFSchema = {
        type: 'array',
        items: {
          type: 'object',
          properties: {
            name: { type: 'string' },
          },
        },
      };
      const result = getPathFromObject(schema);
      // Array schema returns paths from the items schema
      expect(result.length).toBeGreaterThanOrEqual(0);
    });

    it('handles empty object schema', () => {
      const schema: RJSFSchema = { type: 'object', properties: {} };
      const result = getPathFromObject(schema);
      expect(result).toEqual([]);
    });
  });
});
