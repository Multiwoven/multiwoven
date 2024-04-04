import { ConnectionStatus, ConnectorTypes, SourceListColumnType } from './types';

export const CONNECTORS: Record<ConnectorTypes, Record<string, string>> = {
  source: {
    name: 'Source',
    key: 'source',
  },
  destination: {
    name: 'Destination',
    key: 'destination',
  },
  model: {
    name: 'Model',
    key: 'model',
  },
};

export const CONNECTION_STATUS: ConnectionStatus[] = [
  {
    name: 'Establishing Connection',
    status: ({ isLoading }) => {
      if (isLoading) {
        return {
          status: 'loading',
          text: 'Checking network connectivity',
        };
      }
      return {
        status: 'success',
        text: 'Connection Established',
      };
    },
  },
  {
    name: 'Validating Credentials',
    status: ({ data, isLoading, datasource }) => {
      if (isLoading) {
        return {
          status: 'loading',
          text: `Validating ${datasource} credentials`,
        };
      } else if (data?.connection_status?.status !== 'failed') {
        return {
          status: 'success',
          text: `${datasource}  credentials validated`,
        };
      }
      return {
        status: 'failed',
        text: `Failed to validate ${datasource} credentials`,
      };
    },
  },
];

export const SOURCES_LIST_QUERY_KEY = ['connectors', 'source'];
export const DESTINATIONS_LIST_QUERY_KEY = ['connectors', 'destinations'];

export const CONNECTOR_LIST_COLUMNS: SourceListColumnType[] = [
  {
    key: 'name',
    name: 'Name',
  },
  {
    key: 'icon',
    name: 'Type',
  },
  {
    key: 'updated_at',
    name: 'Updated At',
  },
  {
    key: 'status',
    name: 'Status',
  },
];

export const ALL_DESTINATIONS_CATEGORY = 'All Destinations';
