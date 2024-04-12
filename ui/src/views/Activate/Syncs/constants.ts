import { SyncColumnEntity, SyncRunsColumnEntity } from './types';

export const SYNC_TABLE_COLUMS: SyncColumnEntity[] = [
  {
    key: 'model',
    name: 'Model',
  },
  {
    key: 'destination',
    name: 'Destination',
  },
  {
    key: 'lastUpdated',
    name: 'Last Updated',
  },
  {
    key: 'status',
    name: 'Status',
  },
];

export const SYNC_RUNS_COLUMNS: SyncRunsColumnEntity[] = [
  {
    key: 'status',
    name: 'status',
  },
  {
    key: 'start_time',
    name: 'start_time',
  },
  {
    key: 'duration',
    name: 'Duration',
  },
  {
    key: 'rows_queried',
    name: 'Rows Queried',
    hasHoverText: true,
    hoverText: 'Number of rows your query returned from the Source.',
  },
  {
    key: 'results',
    name: 'Results',
    hasHoverText: true,
    hoverText:
      'Number of successful or failed operations that occurred while processing your sync.',
  },
];

export const SYNCS_LIST_QUERY_KEY = ['activate', 'syncs-list'];
