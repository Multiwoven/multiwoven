import { describe, it, expect } from '@jest/globals';
import { SYNC_TABLE_COLUMS, SYNC_RUNS_COLUMNS, SYNCS_LIST_QUERY_KEY } from '../constants';

describe('constants', () => {
  describe('SYNC_TABLE_COLUMS', () => {
    it('contains expected column keys', () => {
      const keys = SYNC_TABLE_COLUMS.map((col) => col.key);
      expect(keys).toContain('name');
      expect(keys).toContain('model');
      expect(keys).toContain('destination');
      expect(keys).toContain('lastUpdated');
      expect(keys).toContain('status');
    });

    it('contains expected column names', () => {
      const names = SYNC_TABLE_COLUMS.map((col) => col.name);
      expect(names).toContain('Name');
      expect(names).toContain('Model');
      expect(names).toContain('Destination');
      expect(names).toContain('Last Updated');
      expect(names).toContain('Status');
    });

    it('has correct number of columns', () => {
      expect(SYNC_TABLE_COLUMS.length).toBe(5);
    });
  });

  describe('SYNC_RUNS_COLUMNS', () => {
    it('contains expected column keys', () => {
      const keys = SYNC_RUNS_COLUMNS.map((col) => col.key);
      expect(keys).toContain('status');
      expect(keys).toContain('start_time');
      expect(keys).toContain('sync_run_type');
      expect(keys).toContain('duration');
      expect(keys).toContain('rows_queried');
      expect(keys).toContain('skipped_rows');
      expect(keys).toContain('results');
    });

    it('has hover text for specific columns', () => {
      const rowsQueried = SYNC_RUNS_COLUMNS.find((col) => col.key === 'rows_queried');
      expect(rowsQueried?.hasHoverText).toBe(true);
      expect(rowsQueried?.hoverText).toBeDefined();

      const skippedRows = SYNC_RUNS_COLUMNS.find((col) => col.key === 'skipped_rows');
      expect(skippedRows?.hasHoverText).toBe(true);
      expect(skippedRows?.hoverText).toBeDefined();

      const results = SYNC_RUNS_COLUMNS.find((col) => col.key === 'results');
      expect(results?.hasHoverText).toBe(true);
      expect(results?.hoverText).toBeDefined();
    });

    it('has correct number of columns', () => {
      expect(SYNC_RUNS_COLUMNS.length).toBe(7);
    });
  });

  describe('SYNCS_LIST_QUERY_KEY', () => {
    it('is defined as expected', () => {
      expect(SYNCS_LIST_QUERY_KEY).toEqual(['activate', 'syncs-list']);
    });

    it('is an array', () => {
      expect(Array.isArray(SYNCS_LIST_QUERY_KEY)).toBe(true);
    });
  });
});
