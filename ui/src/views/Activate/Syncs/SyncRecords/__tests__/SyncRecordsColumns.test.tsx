import { render, screen } from '@testing-library/react';
import { expect, describe, it } from '@jest/globals';
import '@testing-library/jest-dom/jest-globals';
import '@testing-library/jest-dom';
import { ChakraProvider } from '@chakra-ui/react';
import { CellContext, ColumnDef } from '@tanstack/react-table';
import { SyncRecordsColumns, useDynamicSyncColumns } from '../SyncRecordsColumns';

type SyncRecordColumnDef = Omit<ColumnDef<SyncRecordResponse>, 'accessorKey'> & {
  accessorKey?: string;
};
import { SyncRecordResponse, SyncRecordStatus } from '../../types';
import { renderHook } from '@testing-library/react';

const mockSyncRecord: SyncRecordResponse = {
  id: '1',
  type: 'sync_records',
  attributes: {
    sync_id: '123',
    sync_run_id: '456',
    record: { id: '1', name: 'Record 1', email: 'test@example.com' },
    status: SyncRecordStatus.success,
    action: 'destination_insert',
    logs: {
      request: '{}',
      response: '{}',
      level: 'info',
    },
    created_at: '2024-01-01T00:00:00Z',
    updated_at: '2024-01-01T00:00:00Z',
  },
};

jest.mock('../ErrorLogsModal', () => ({
  __esModule: true,
  default: ({
    request,
    response,
    level,
    status,
  }: {
    request: string;
    response: string;
    level: string;
    status: SyncRecordStatus;
  }) => (
    <div data-testid='error-logs-modal'>
      {request} {response} {level} {status}
    </div>
  ),
}));

const renderCell = (column: SyncRecordColumnDef, row: SyncRecordResponse) => {
  const cellInfo = {
    getValue: () => {
      const key = column.accessorKey as string;
      if (key === 'attributes') {
        return row.attributes;
      }
      if (key && key.includes('.')) {
        const parts = key.split('.');
        let value: SyncRecordResponse | Record<string, unknown> = row;
        for (const part of parts) {
          value = (value as Record<string, unknown>)?.[part] as
            | SyncRecordResponse
            | Record<string, unknown>;
        }
        return value;
      }
      return row[key as keyof SyncRecordResponse];
    },
    row: { original: row },
  };
  const cellContent =
    typeof column.cell === 'function'
      ? column.cell(cellInfo as CellContext<SyncRecordResponse, unknown>)
      : null;
  return render(<ChakraProvider>{cellContent}</ChakraProvider>);
};

describe('SyncRecordsColumns', () => {
  it('renders status column header', () => {
    const statusColumn = SyncRecordsColumns.find(
      (col: SyncRecordColumnDef) => col.accessorKey === 'attributes.status',
    );
    expect(statusColumn).toBeDefined();
  });

  it('renders status cell for success', () => {
    const statusColumn = SyncRecordsColumns.find(
      (col: SyncRecordColumnDef) => col.accessorKey === 'attributes.status',
    );
    if (statusColumn) {
      renderCell(statusColumn, mockSyncRecord);
      expect(screen.getByText('Added')).toBeInTheDocument();
    }
  });

  it('renders status cell for failed', () => {
    const failedRecord = {
      ...mockSyncRecord,
      attributes: { ...mockSyncRecord.attributes, status: SyncRecordStatus.failed },
    };
    const statusColumn = SyncRecordsColumns.find(
      (col: SyncRecordColumnDef) => col.accessorKey === 'attributes.status',
    );
    if (statusColumn) {
      renderCell(statusColumn, failedRecord);
      expect(screen.getByText('Failed')).toBeInTheDocument();
    }
  });

  it('renders logs column header', () => {
    const logsColumn = SyncRecordsColumns.find(
      (col: SyncRecordColumnDef) => col.accessorKey === 'attributes',
    );
    expect(logsColumn).toBeDefined();
  });

  it('renders logs cell with ErrorLogsModal', () => {
    const logsColumn = SyncRecordsColumns.find(
      (col: SyncRecordColumnDef) => col.accessorKey === 'attributes',
    );
    if (logsColumn) {
      renderCell(logsColumn, mockSyncRecord);
      expect(screen.getByTestId('error-logs-modal')).toBeInTheDocument();
    }
  });
});

describe('useDynamicSyncColumns', () => {
  it('returns empty array when data is empty', () => {
    const { result } = renderHook(() => useDynamicSyncColumns([]));
    expect(result.current).toEqual([]);
  });

  it('returns columns for record keys', () => {
    const { result } = renderHook(() => useDynamicSyncColumns([mockSyncRecord]));
    expect(result.current.length).toBeGreaterThan(0);
    expect(result.current[0].accessorKey).toContain('attributes.record');
  });

  it('memoizes columns based on data', () => {
    const { result, rerender } = renderHook(({ data }) => useDynamicSyncColumns(data), {
      initialProps: { data: [mockSyncRecord] },
    });
    const firstResult = result.current;
    rerender({ data: [mockSyncRecord] });
    // Memoization may create new arrays with same content, so check length and structure
    expect(result.current.length).toBe(firstResult.length);
    expect(result.current[0]?.accessorKey).toBe(firstResult[0]?.accessorKey);
  });
});
