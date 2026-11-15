import { render, screen } from '@testing-library/react';
import { expect, describe, it } from '@jest/globals';
import '@testing-library/jest-dom/jest-globals';
import '@testing-library/jest-dom';
import { ChakraProvider } from '@chakra-ui/react';
import { SyncsListColumns } from '../SyncsListColumns';
import { CreateSyncResponse } from '../../types';

const mockSync: CreateSyncResponse = {
  id: '1',
  type: 'syncs',
  attributes: {
    name: 'Test Sync',
    status: 'enabled',
    created_at: new Date('2024-01-01T00:00:00Z'),
    updated_at: new Date('2024-01-01T00:00:00Z'),
    configuration: {},
    destination_id: 2,
    model_id: 1,
    schedule_type: 'interval',
    cron_expression: '',
    source_id: '1',
    stream_name: 'stream1',
    sync_interval: 0,
    sync_interval_unit: 'minutes',
    sync_mode: 'full_refresh',
    cursor_field: '',
    model: {
      id: '1',
      name: 'Test Model',
      description: null,
      created_at: '2024-01-01T00:00:00Z',
      updated_at: '2024-01-01T00:00:00Z',
      query: 'SELECT * FROM table',
      query_type: 'sql',
      icon: 'postgres-icon',
      connector: {
        id: 1,
        name: 'PostgreSQL',
        description: null,
        connector_type: 'source' as const,
        workspace_id: 1,
        created_at: '2024-01-01T00:00:00Z',
        updated_at: '2024-01-01T00:00:00Z',
        configuration: {},
        connector_name: 'postgresql',
        icon: 'postgres-icon',
      },
    },
    destination: {
      id: '2',
      name: 'Snowflake',
      connector_name: 'snowflake',
      icon: 'snowflake-icon',
    },
    source: {
      id: '1',
      name: 'PostgreSQL',
      connector_name: 'postgresql',
      icon: 'postgres-icon',
    },
  },
};

const renderCell = (column: any, row: CreateSyncResponse) => {
  const cellInfo = {
    getValue: () => {
      const key = column.accessorKey as string;
      if (key && key.includes('.')) {
        const parts = key.split('.');
        let value: any = row;
        for (const part of parts) {
          value = value?.[part];
        }
        return value;
      }
      return row[key as keyof CreateSyncResponse];
    },
    renderValue: () => {
      const key = column.accessorKey as string;
      if (key && key.includes('.')) {
        const parts = key.split('.');
        let value: any = row;
        for (const part of parts) {
          value = value?.[part];
        }
        return value;
      }
      return row[key as keyof CreateSyncResponse];
    },
    row: { original: row },
  };
  const cellContent = typeof column.cell === 'function' ? column.cell(cellInfo as any) : null;
  return render(<ChakraProvider>{cellContent}</ChakraProvider>);
};

describe('SyncsListColumns', () => {
  it('renders name column header', () => {
    const nameColumn = SyncsListColumns.find((col: any) => col.accessorKey === 'attributes.name');
    expect(nameColumn).toBeDefined();
    if (nameColumn && typeof nameColumn.header === 'function') {
      const header = render(<ChakraProvider>{nameColumn.header({} as any)}</ChakraProvider>);
      expect(header.getByText('Name')).toBeInTheDocument();
    }
  });

  it('renders name cell correctly', () => {
    const nameColumn = SyncsListColumns.find((col: any) => col.accessorKey === 'attributes.name');
    if (nameColumn) {
      renderCell(nameColumn, mockSync);
      expect(screen.getByText('Test Sync')).toBeInTheDocument();
    }
  });

  it('renders model column header', () => {
    const modelColumn = SyncsListColumns.find((col: any) => col.accessorKey === 'attributes.model');
    expect(modelColumn).toBeDefined();
  });

  it('renders model cell correctly', () => {
    const modelColumn = SyncsListColumns.find((col: any) => col.accessorKey === 'attributes.model');
    if (modelColumn) {
      renderCell(modelColumn, mockSync);
      expect(screen.getByText('Test Model')).toBeInTheDocument();
    }
  });

  it('renders destination column header', () => {
    const destColumn = SyncsListColumns.find(
      (col: any) => col.accessorKey === 'attributes.destination',
    );
    expect(destColumn).toBeDefined();
  });

  it('renders destination cell correctly', () => {
    const destColumn = SyncsListColumns.find(
      (col: any) => col.accessorKey === 'attributes.destination',
    );
    if (destColumn) {
      renderCell(destColumn, mockSync);
      expect(screen.getByText('Snowflake')).toBeInTheDocument();
    }
  });

  it('renders status column header', () => {
    const statusColumn = SyncsListColumns.find(
      (col: any) => col.accessorKey === 'attributes.status',
    );
    expect(statusColumn).toBeDefined();
  });

  it('renders status cell for enabled sync', () => {
    const statusColumn = SyncsListColumns.find(
      (col: any) => col.accessorKey === 'attributes.status',
    );
    if (statusColumn) {
      renderCell(statusColumn, mockSync);
      expect(screen.getByText('Active')).toBeInTheDocument();
    }
  });

  it('renders status cell for disabled sync', () => {
    const disabledSync = {
      ...mockSync,
      attributes: { ...mockSync.attributes, status: 'disabled' },
    };
    const statusColumn = SyncsListColumns.find(
      (col: any) => col.accessorKey === 'attributes.status',
    );
    if (statusColumn) {
      renderCell(statusColumn, disabledSync);
      expect(screen.getByText('Disabled')).toBeInTheDocument();
    }
  });

  it('renders last updated column header', () => {
    const updatedColumn = SyncsListColumns.find(
      (col: any) => col.accessorKey === 'attributes.updated_at',
    );
    expect(updatedColumn).toBeDefined();
  });

  it('renders last updated cell', () => {
    const updatedColumn = SyncsListColumns.find(
      (col: any) => col.accessorKey === 'attributes.updated_at',
    );
    if (updatedColumn) {
      const { container } = renderCell(updatedColumn, mockSync);
      expect(container).toBeInTheDocument();
    }
  });
});
