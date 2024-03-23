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
  },
  {
    key: 'results',
    name: 'Results',
  },
];

export const SYNCS_LIST_QUERY_KEY = ['activate', 'syncs-list'];
