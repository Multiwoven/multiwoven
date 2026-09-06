import React from 'react';
import { render, screen, fireEvent } from '@testing-library/react';
import { expect, describe, it, beforeEach, jest } from '@jest/globals';
import '@testing-library/jest-dom/jest-globals';
import '@testing-library/jest-dom';
import { MemoryRouter } from 'react-router-dom';
import { ChakraProvider } from '@chakra-ui/react';
import { QueryClient, QueryClientProvider } from '@tanstack/react-query';
import SyncRuns from '..';
import { useStore } from '@/stores';
import {
  mockSyncRuns,
  mockUseSyncRuns,
  createMockUseSyncRuns,
} from '../../../../../../__mocks__/syncMocks';
import { mockNavigate } from '../../../../../../__mocks__/navigationMocks';
import { mockStoreImplementation } from '../../../../../../__mocks__/commonMocks';

const createQueryClient = () =>
  new QueryClient({
    defaultOptions: {
      queries: {
        retry: false,
      },
    },
  });

jest.mock('react-router-dom', () => {
  const actual = jest.requireActual<typeof import('react-router-dom')>('react-router-dom');
  return {
    ...actual,
    useParams: () => ({ syncId: '123' }),
  };
});

jest.mock('@/hooks/syncs/useSyncRuns', () => ({
  __esModule: true,
  default: () => mockUseSyncRuns(),
}));

const mockUpdateFilters = jest.fn();
const mockSyncRunsFilters: Record<string, string | null> = { page: '1' };
jest.mock('@/hooks/useFilters', () => ({
  __esModule: true,
  default: () => ({ filters: mockSyncRunsFilters, updateFilters: mockUpdateFilters }),
}));

jest.mock('@/stores', () => ({
  useStore: jest.fn(),
}));

jest.mock('@/enterprise/hooks/useProtectedNavigate', () => ({
  __esModule: true,
  default: () => mockNavigate,
}));

jest.mock('@/components/Loader', () => ({
  __esModule: true,
  default: () => <div data-testid='loader'>Loading...</div>,
}));

type MockColumn = {
  header: string | (() => string);
  cell?: (info: { getValue: () => unknown }) => React.ReactNode;
  accessorKey?: string;
};
type MockRow = { attributes?: Record<string, unknown>; [key: string]: unknown };

jest.mock('@/components/DataTable', () => ({
  __esModule: true,
  default: ({
    data,
    columns,
    onRowClick,
  }: {
    data?: MockRow[];
    columns?: MockColumn[];
    onRowClick?: (row: { original: MockRow }) => void;
  }) => (
    <table data-testid='data-table'>
      <thead>
        <tr>
          {columns?.map((col: MockColumn, idx: number) => (
            <th key={idx}>{typeof col.header === 'function' ? col.header() : col.header}</th>
          ))}
        </tr>
      </thead>
      <tbody>
        {data?.map((row: MockRow, idx: number) => (
          <tr key={idx} onClick={() => onRowClick?.({ original: row })} data-testid={`row-${idx}`}>
            {columns?.map((col: MockColumn, colIdx: number) => {
              const cellInfo = {
                getValue: () => {
                  const key = col.accessorKey as string;
                  if (!key) return undefined;
                  if (key === 'attributes') {
                    return row.attributes;
                  }
                  if (key.includes('.')) {
                    const parts = key.split('.');
                    let value: unknown = row;
                    for (const part of parts) {
                      value = (value as Record<string, unknown>)?.[part];
                    }
                    return value;
                  }
                  return row[key as keyof typeof row];
                },
                row: { original: row },
              };
              try {
                const cellContent = typeof col.cell === 'function' ? col.cell(cellInfo) : null;
                return <td key={colIdx}>{cellContent}</td>;
              } catch (e) {
                return <td key={colIdx}></td>;
              }
            })}
          </tr>
        ))}
      </tbody>
    </table>
  ),
}));

jest.mock('@/components/DataTable/RowsNotFound', () => ({
  __esModule: true,
  default: () => <div data-testid='rows-not-found'>No rows found</div>,
}));

jest.mock('@/components/EnhancedPagination/Pagination', () => ({
  __esModule: true,
  default: ({ handlePageChange }: { handlePageChange?: (page: number) => void }) => (
    <div data-testid='pagination'>
      <button data-testid='page-change' onClick={() => handlePageChange?.(2)}>
        Page 2
      </button>
    </div>
  ),
}));

jest.mock('@/enterprise/views/Activate/SyncRunsExport/SyncRunsExportModal', () => ({
  __esModule: true,
  default: () => <div data-testid='export-modal'>ExportModal</div>,
}));

const mockedUseStore = useStore as jest.MockedFunction<typeof useStore>;

const renderComponent = () => {
  const queryClient = createQueryClient();
  return render(
    <QueryClientProvider client={queryClient}>
      <ChakraProvider>
        <MemoryRouter>
          <SyncRuns />
        </MemoryRouter>
      </ChakraProvider>
    </QueryClientProvider>,
  );
};

describe('SyncRuns', () => {
  beforeEach(() => {
    jest.clearAllMocks();
    mockSyncRunsFilters.page = '1';
    mockStoreImplementation(mockedUseStore, { workspaceId: 1 });
    mockUseSyncRuns.mockImplementation(
      createMockUseSyncRuns({ data: mockSyncRuns, isLoading: false }),
    );
  });

  it('renders loader when loading', () => {
    mockUseSyncRuns.mockImplementation(() => ({
      data: undefined,
      isLoading: true,
    }));
    renderComponent();
    expect(screen.getByTestId('loader')).toBeInTheDocument();
  });

  it('renders sync runs table when data is available', () => {
    renderComponent();
    expect(screen.getByTestId('data-table')).toBeInTheDocument();
  });

  it('renders export modal', () => {
    renderComponent();
    expect(screen.getByTestId('export-modal')).toBeInTheDocument();
  });

  it('renders empty state when no sync runs exist', () => {
    mockUseSyncRuns.mockImplementation(createMockUseSyncRuns({ data: [], isLoading: false }));
    renderComponent();
    expect(screen.getByTestId('rows-not-found')).toBeInTheDocument();
  });

  it('navigates to sync record when row is clicked', () => {
    renderComponent();
    const row = screen.getByTestId('row-0');
    fireEvent.click(row);
    expect(mockNavigate).toHaveBeenCalledWith({
      to: 'run/1',
      location: 'sync_record',
      action: 'read',
    });
  });

  it('renders pagination when links are available', () => {
    mockUseSyncRuns.mockImplementation(
      createMockUseSyncRuns({
        data: mockSyncRuns,
        isLoading: false,
        links: {
          first: 'http://example.com?page=1',
          last: 'http://example.com?page=2',
          next: 'http://example.com?page=2',
          prev: null,
          self: 'http://example.com?page=1',
        },
      }),
    );
    renderComponent();
    expect(screen.getByTestId('pagination')).toBeInTheDocument();
  });

  it('handles page change via pagination', () => {
    mockUseSyncRuns.mockImplementation(
      createMockUseSyncRuns({
        data: mockSyncRuns,
        isLoading: false,
        links: {
          first: 'http://example.com?page=1',
          last: 'http://example.com?page=2',
          next: 'http://example.com?page=2',
          prev: null,
          self: 'http://example.com?page=1',
        },
      }),
    );
    renderComponent();
    const pageButton = screen.getByTestId('page-change');
    fireEvent.click(pageButton);
    expect(screen.getByTestId('pagination')).toBeInTheDocument();
  });

  it('renders empty state when data is null and not loading', () => {
    mockUseSyncRuns.mockImplementation(() => ({
      data: { data: null },
      isLoading: false,
    }));
    renderComponent();
    expect(screen.getByTestId('rows-not-found')).toBeInTheDocument();
  });

  it('defaults currentPage to 1 when filters.page is falsy', () => {
    mockSyncRunsFilters.page = null;
    mockUseSyncRuns.mockImplementation(
      createMockUseSyncRuns({
        data: mockSyncRuns,
        isLoading: false,
        links: {
          first: 'http://example.com?page=1',
          last: 'http://example.com?page=2',
          next: 'http://example.com?page=2',
          prev: null,
          self: 'http://example.com?page=1',
        },
      }),
    );
    renderComponent();
    expect(screen.getByTestId('pagination')).toBeInTheDocument();
  });
});
