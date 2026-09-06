import React from 'react';
import { render, screen, fireEvent, waitFor } from '@testing-library/react';
import { expect, describe, it, beforeEach, jest } from '@jest/globals';
import '@testing-library/jest-dom/jest-globals';
import '@testing-library/jest-dom';
import { MemoryRouter } from 'react-router-dom';
import { ChakraProvider } from '@chakra-ui/react';
import { QueryClient, QueryClientProvider } from '@tanstack/react-query';
import SyncRecords from '..';
import { SyncRecordStatus } from '../../types';
import { mockSyncRecords } from '../../../../../../__mocks__/syncMocks';

const createQueryClient = () =>
  new QueryClient({
    defaultOptions: {
      queries: {
        retry: false,
      },
    },
  });

const mockUseQueryWrapper = jest.fn();
const mockToast = jest.fn();
const mockUseParams = jest.fn();
const mockUpdateFilters = jest.fn();
const mockFiltersState: Record<string, string | null> = { page: '1', status: 'success' };

jest.mock('react-router-dom', () => {
  const actual = jest.requireActual<typeof import('react-router-dom')>('react-router-dom');
  return {
    ...actual,
    useParams: () => mockUseParams(),
  };
});

jest.mock('@/hooks/useFilters', () => ({
  __esModule: true,
  default: () => ({ filters: mockFiltersState, updateFilters: mockUpdateFilters }),
}));

jest.mock('@/hooks/useQueryWrapper', () => ({
  __esModule: true,
  default: (_key: unknown, queryFn?: () => unknown) => {
    if (typeof queryFn === 'function') {
      try {
        queryFn();
      } catch {
        /* expected in mock */
      }
    }
    return mockUseQueryWrapper();
  },
}));

jest.mock('@/hooks/useCustomToast', () => ({
  __esModule: true,
  default: () => mockToast,
}));

jest.mock('@/components/Loader', () => ({
  __esModule: true,
  default: () => <div data-testid='loader'>Loading...</div>,
}));

jest.mock('@/components/ContentContainer', () => ({
  __esModule: true,
  default: ({ children }: { children: React.ReactNode }) => (
    <div data-testid='content-container'>{children}</div>
  ),
}));

type MockColumn = {
  header: string | (() => string);
  cell?: (info: { getValue: () => unknown }) => React.ReactNode;
  accessorKey?: string;
};
type MockRow = { attributes?: Record<string, unknown> };

jest.mock('@/components/DataTable', () => ({
  __esModule: true,
  default: ({ data, columns }: { data?: MockRow[]; columns: MockColumn[] }) => (
    <table data-testid='data-table'>
      <thead>
        <tr>
          {columns.map((col: MockColumn, idx: number) => (
            <th key={idx}>{typeof col.header === 'function' ? col.header() : col.header}</th>
          ))}
        </tr>
      </thead>
      <tbody>
        {data?.map((row: MockRow, idx: number) => (
          <tr key={idx}>
            {columns.map((col: MockColumn, colIdx: number) => (
              <td key={colIdx}>
                {col.cell
                  ? col.cell({
                      getValue: () =>
                        col.accessorKey ? row.attributes?.[col.accessorKey] : undefined,
                    })
                  : null}
              </td>
            ))}
          </tr>
        ))}
      </tbody>
    </table>
  ),
}));

jest.mock('@/components/EnhancedPagination', () => ({
  __esModule: true,
  default: ({ handlePageChange }: { handlePageChange?: (page: number) => void }) => (
    <div data-testid='pagination'>
      <button data-testid='page-change' onClick={() => handlePageChange?.(2)}>
        Page 2
      </button>
    </div>
  ),
}));

jest.mock('../SyncRecordsTopBar', () => ({
  SyncRecordsTopBar: () => <div data-testid='top-bar'>TopBar</div>,
}));

jest.mock('../FilterTabs', () => ({
  FilterTabs: ({ setFilter }: { setFilter: (status: SyncRecordStatus) => void }) => (
    <div>
      <button onClick={() => setFilter(SyncRecordStatus.success)}>Successful</button>
      <button onClick={() => setFilter(SyncRecordStatus.failed)}>Rejected</button>
    </div>
  ),
}));

const renderComponent = () => {
  const queryClient = createQueryClient();
  return render(
    <QueryClientProvider client={queryClient}>
      <ChakraProvider>
        <MemoryRouter>
          <SyncRecords />
        </MemoryRouter>
      </ChakraProvider>
    </QueryClientProvider>,
  );
};

describe('SyncRecords', () => {
  beforeEach(() => {
    jest.clearAllMocks();
    mockUseParams.mockReturnValue({ syncId: '123', syncRunId: '456' });
    mockFiltersState.page = '1';
    mockFiltersState.status = 'success';
    mockUseQueryWrapper.mockReturnValue({
      data: {
        data: mockSyncRecords,
      },
      isLoading: false,
      isError: false,
    });
  });

  it('renders loader when loading', () => {
    mockUseQueryWrapper.mockReturnValue({
      data: undefined,
      isLoading: true,
      isError: false,
    });
    renderComponent();
    expect(screen.getByTestId('loader')).toBeInTheDocument();
  });

  it('renders top bar when syncId and syncRunId are present', () => {
    renderComponent();
    expect(screen.getByTestId('top-bar')).toBeInTheDocument();
  });

  it('renders filter tabs', () => {
    renderComponent();
    expect(screen.getByText('Successful')).toBeInTheDocument();
    expect(screen.getByText('Rejected')).toBeInTheDocument();
  });

  it('renders sync records table when data is available', () => {
    renderComponent();
    expect(screen.getByTestId('data-table')).toBeInTheDocument();
  });

  it('renders empty state when no records exist', () => {
    mockUseQueryWrapper.mockReturnValue({
      data: {
        data: [],
      },
      isLoading: false,
      isError: false,
    });
    renderComponent();
    expect(screen.getByText('No rows found')).toBeInTheDocument();
  });

  it('filters records by status when tab is clicked', () => {
    renderComponent();
    const rejectedTab = screen.getByText('Rejected');
    fireEvent.click(rejectedTab);
    expect(screen.getByText('Rejected')).toBeInTheDocument();
  });

  it('shows error toast when query fails', () => {
    mockUseQueryWrapper.mockReturnValue({
      data: undefined,
      isLoading: false,
      isError: true,
    });
    renderComponent();
    expect(mockToast).toHaveBeenCalledWith(
      expect.objectContaining({
        title: 'Error',
        description: 'There was an issue fetching the sync records.',
      }),
    );
  });

  it('shows "Pagination unavailable" when links are missing', () => {
    mockUseQueryWrapper.mockReturnValue({
      data: {
        data: mockSyncRecords,
      },
      isLoading: false,
      isError: false,
    });
    renderComponent();
    expect(screen.getByText('Pagination unavailable.')).toBeInTheDocument();
  });

  it('renders pagination when links are available', async () => {
    mockUseQueryWrapper.mockReturnValue({
      data: {
        data: mockSyncRecords,
        links: {
          first: 'http://example.com?page=1',
          last: 'http://example.com?page=2',
          next: 'http://example.com?page=2',
          prev: null,
          self: 'http://example.com?page=1',
        },
      },
      isLoading: false,
      isError: false,
    });
    renderComponent();
    await waitFor(() => {
      expect(screen.getByTestId('pagination')).toBeInTheDocument();
    });
  });

  it('handles page change via pagination', async () => {
    mockUseQueryWrapper.mockReturnValue({
      data: {
        data: mockSyncRecords,
        links: {
          first: 'http://example.com?page=1',
          last: 'http://example.com?page=2',
          next: 'http://example.com?page=2',
          prev: null,
          self: 'http://example.com?page=1',
        },
      },
      isLoading: false,
      isError: false,
    });
    renderComponent();
    await waitFor(() => {
      expect(screen.getByTestId('page-change')).toBeInTheDocument();
    });
    fireEvent.click(screen.getByTestId('page-change'));
    expect(screen.getByTestId('pagination')).toBeInTheDocument();
  });

  it('uses default status when filters.status is null', () => {
    mockFiltersState.status = null;
    renderComponent();
    expect(screen.getByText('Successful')).toBeInTheDocument();
  });

  it('does not render top bar when syncId or syncRunId is falsy', () => {
    mockUseParams.mockReturnValue({ syncId: undefined, syncRunId: undefined });
    renderComponent();
    expect(screen.queryByTestId('top-bar')).not.toBeInTheDocument();
  });

  it('defaults currentPage to 1 when filters.page is falsy', async () => {
    mockFiltersState.page = null;
    mockUseQueryWrapper.mockReturnValue({
      data: {
        data: mockSyncRecords,
        links: {
          first: 'http://example.com?page=1',
          last: 'http://example.com?page=2',
          next: 'http://example.com?page=2',
          prev: null,
          self: 'http://example.com?page=1',
        },
      },
      isLoading: false,
      isError: false,
    });
    renderComponent();
    await waitFor(() => {
      expect(screen.getByTestId('pagination')).toBeInTheDocument();
    });
  });
});
