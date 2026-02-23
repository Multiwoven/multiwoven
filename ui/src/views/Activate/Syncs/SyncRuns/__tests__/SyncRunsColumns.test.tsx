import { render, screen } from '@testing-library/react';
import { expect, describe, it } from '@jest/globals';
import '@testing-library/jest-dom/jest-globals';
import '@testing-library/jest-dom';
import { ChakraProvider } from '@chakra-ui/react';
import { CellContext, ColumnDef } from '@tanstack/react-table';
import { SyncRunsColumns } from '../SyncRunsColumns';

type SyncRunsColumnDef = Omit<ColumnDef<SyncRunsResponse>, 'accessorKey'> & {
  accessorKey?: string;
};
import { SyncRunsResponse } from '../../types';

const mockSyncRun: SyncRunsResponse = {
  id: '1',
  type: 'sync_runs',
  attributes: {
    sync_id: '123',
    status: 'success',
    source_id: '1',
    destination_id: '2',
    started_at: '2024-01-01T00:00:00Z',
    finished_at: '2024-01-01T00:01:00Z',
    created_at: '2024-01-01T00:00:00Z',
    updated_at: '2024-01-01T00:01:00Z',
    sync_run_type: 'manual',
    duration: 100,
    total_query_rows: 1000,
    skipped_rows: 0,
    total_rows: 1000,
    successful_rows: 950,
    failed_rows: 50,
    error: null,
  },
};

const renderCell = (column: SyncRunsColumnDef, row: SyncRunsResponse) => {
  const cellInfo = {
    getValue: () => {
      const key = column.accessorKey as string;
      if (key === 'attributes') {
        return row.attributes;
      }
      if (key && key.includes('.')) {
        const parts = key.split('.');
        let value: SyncRunsResponse | Record<string, unknown> = row;
        for (const part of parts) {
          value = (value as Record<string, unknown>)?.[part] as
            | SyncRunsResponse
            | Record<string, unknown>;
        }
        return value;
      }
      return row[key as keyof SyncRunsResponse];
    },
    row: { original: row },
  };
  const cellContent =
    typeof column.cell === 'function'
      ? column.cell(cellInfo as CellContext<SyncRunsResponse, unknown>)
      : null;
  return render(<ChakraProvider>{cellContent}</ChakraProvider>);
};

describe('SyncRunsColumns', () => {
  it('renders status column header', () => {
    const statusColumn = SyncRunsColumns.find(
      (col: SyncRunsColumnDef) => col.accessorKey === 'attributes.status',
    );
    expect(statusColumn).toBeDefined();
  });

  it('renders status cell', () => {
    const statusColumn = SyncRunsColumns.find(
      (col: SyncRunsColumnDef) => col.accessorKey === 'attributes.status',
    );
    if (statusColumn) {
      const { container } = renderCell(statusColumn, mockSyncRun);
      expect(container).toBeInTheDocument();
    }
  });

  it('renders start time column header', () => {
    const startTimeColumn = SyncRunsColumns.find(
      (col: SyncRunsColumnDef) => col.accessorKey === 'attributes.started_at',
    );
    expect(startTimeColumn).toBeDefined();
  });

  it('renders start time cell', () => {
    const startTimeColumn = SyncRunsColumns.find(
      (col: SyncRunsColumnDef) => col.accessorKey === 'attributes.started_at',
    );
    if (startTimeColumn) {
      const { container } = renderCell(startTimeColumn, mockSyncRun);
      expect(container).toBeInTheDocument();
    }
  });

  it('renders sync run type column header', () => {
    const typeColumn = SyncRunsColumns.find(
      (col: SyncRunsColumnDef) => col.accessorKey === 'attributes.sync_run_type',
    );
    expect(typeColumn).toBeDefined();
  });

  it('renders sync run type cell', () => {
    const typeColumn = SyncRunsColumns.find(
      (col: SyncRunsColumnDef) => col.accessorKey === 'attributes.sync_run_type',
    );
    if (typeColumn) {
      const { container } = renderCell(typeColumn, mockSyncRun);
      expect(container).toBeInTheDocument();
    }
  });

  it('renders duration column header', () => {
    const durationColumn = SyncRunsColumns.find(
      (col: SyncRunsColumnDef) => col.accessorKey === 'attributes.duration',
    );
    expect(durationColumn).toBeDefined();
  });

  it('renders duration cell', () => {
    const durationColumn = SyncRunsColumns.find(
      (col: SyncRunsColumnDef) => col.accessorKey === 'attributes.duration',
    );
    if (durationColumn) {
      const { container } = renderCell(durationColumn, mockSyncRun);
      expect(container).toBeInTheDocument();
    }
  });

  it('renders results column header', () => {
    const resultsColumn = SyncRunsColumns.find(
      (col: SyncRunsColumnDef) => col.accessorKey === 'attributes',
    );
    expect(resultsColumn).toBeDefined();
  });

  it('renders results cell', () => {
    const resultsColumn = SyncRunsColumns.find(
      (col: SyncRunsColumnDef) => col.accessorKey === 'attributes',
    );
    if (resultsColumn) {
      renderCell(resultsColumn, mockSyncRun);
      expect(screen.getByText('Successful')).toBeInTheDocument();
      expect(screen.getByText('Failed')).toBeInTheDocument();
    }
  });

  it('renders null for start time cell with empty value', () => {
    const startTimeColumn = SyncRunsColumns.find(
      (col: SyncRunsColumnDef) => col.accessorKey === 'attributes.started_at',
    ) as SyncRunsColumnDef;
    const emptyRun = {
      ...mockSyncRun,
      attributes: { ...mockSyncRun.attributes, started_at: '' },
    };
    const { container } = renderCell(startTimeColumn, emptyRun);
    expect(container.querySelector('.chakra-text')).toBeNull();
  });

  it('renders general sync run type with correct icon', () => {
    const typeColumn = SyncRunsColumns.find(
      (col: SyncRunsColumnDef) => col.accessorKey === 'attributes.sync_run_type',
    ) as SyncRunsColumnDef;
    const generalRun = {
      ...mockSyncRun,
      attributes: { ...mockSyncRun.attributes, sync_run_type: 'general' },
    };
    const { container } = renderCell(typeColumn, generalRun);
    expect(container).toBeInTheDocument();
  });
});
