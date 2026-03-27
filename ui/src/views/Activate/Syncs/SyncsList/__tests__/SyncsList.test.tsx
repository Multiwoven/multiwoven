import React from 'react';
import { render, screen, fireEvent, waitFor } from '@testing-library/react';
import { expect, describe, it, beforeEach, jest } from '@jest/globals';
import '@testing-library/jest-dom/jest-globals';
import '@testing-library/jest-dom';
import { MemoryRouter } from 'react-router-dom';
import { ChakraProvider } from '@chakra-ui/react';
import { QueryClient, QueryClientProvider } from '@tanstack/react-query';
import SyncsList from '..';
import { useStore } from '@/stores';
import { useRoleDataStore } from '@/enterprise/store/useRoleDataStore';
import { hasActionPermission } from '@/enterprise/utils/accessControlPermission';
import { mockSyncsList } from '../../../../../../__mocks__/syncMocks';
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

jest.mock('@/services/syncs', () => ({
  fetchSyncs: jest.fn(),
}));

const mockUseQuery = jest.fn();
jest.mock('@tanstack/react-query', () => {
  const actual =
    jest.requireActual<typeof import('@tanstack/react-query')>('@tanstack/react-query');
  return {
    ...actual,
    useQuery: (opts: { queryFn?: () => unknown; enabled?: boolean; [key: string]: unknown }) => {
      if (opts.enabled !== false && typeof opts.queryFn === 'function') {
        try {
          opts.queryFn();
        } catch {
          /* expected in mock */
        }
      }
      return mockUseQuery();
    },
  };
});

jest.mock('@/stores', () => ({
  useStore: jest.fn(),
}));

jest.mock('@/enterprise/store/useRoleDataStore', () => ({
  useRoleDataStore: jest.fn(),
}));

jest.mock('@/enterprise/utils/accessControlPermission', () => ({
  hasActionPermission: jest.fn(),
}));

jest.mock('@/enterprise/hooks/useProtectedNavigate', () => ({
  __esModule: true,
  default: () => mockNavigate,
}));

const mockUpdateFilters = jest.fn();
const mockSyncsListFilters: Record<string, string | null> = { page: '1' };
jest.mock('@/hooks/useFilters', () => ({
  __esModule: true,
  default: () => ({ filters: mockSyncsListFilters, updateFilters: mockUpdateFilters }),
}));

jest.mock('../../../NoSyncs/NoSyncs', () => ({
  __esModule: true,
  default: () => <div data-testid='no-syncs'>No Syncs</div>,
  ActivationType: { Sync: 'Sync' },
}));

const mockedUseStore = useStore as jest.MockedFunction<typeof useStore>;
const mockedUseRoleDataStore = useRoleDataStore as jest.MockedFunction<typeof useRoleDataStore>;
const mockedHasActionPermission = hasActionPermission as jest.MockedFunction<
  typeof hasActionPermission
>;

jest.mock('@/components/Loader', () => ({
  __esModule: true,
  default: () => <div data-testid='loader'>Loading...</div>,
}));

jest.mock('@/components/TopBar', () => ({
  __esModule: true,
  default: ({
    name,
    ctaName,
    onCtaClicked,
    isCtaVisible,
  }: {
    name: string;
    ctaName?: string;
    onCtaClicked?: () => void;
    isCtaVisible?: boolean;
  }) => (
    <div data-testid='top-bar'>
      <div data-testid='top-bar-name'>{name}</div>
      {isCtaVisible && (
        <button data-testid='top-bar-cta-button' onClick={onCtaClicked}>
          {ctaName}
        </button>
      )}
    </div>
  ),
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
type MockRow = { [key: string]: unknown };

jest.mock('@/components/DataTable', () => ({
  __esModule: true,
  default: ({
    data,
    columns,
    onRowClick,
  }: {
    data: MockRow[];
    columns: MockColumn[];
    onRowClick?: (row: { original: MockRow }) => void;
  }) => (
    <table data-testid='data-table'>
      <thead>
        <tr>
          {columns.map((col: MockColumn, idx: number) => (
            <th key={idx}>{typeof col.header === 'function' ? col.header() : col.header}</th>
          ))}
        </tr>
      </thead>
      <tbody>
        {data.map((row: MockRow, idx: number) => (
          <tr key={idx} onClick={() => onRowClick?.({ original: row })}>
            {columns.map((col: MockColumn, colIdx: number) => {
              const cellInfo = {
                getValue: () => {
                  const key = col.accessorKey as string;
                  if (key && key.includes('.')) {
                    const parts = key.split('.');
                    let value: unknown = row;
                    for (const part of parts) {
                      value = (value as Record<string, unknown>)?.[part];
                    }
                    return value;
                  }
                  return row[key as keyof typeof row];
                },
                renderValue: () => {
                  const key = col.accessorKey as string;
                  if (key && key.includes('.')) {
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
              return <td key={colIdx}>{col.cell ? col.cell(cellInfo) : null}</td>;
            })}
          </tr>
        ))}
      </tbody>
    </table>
  ),
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

const renderComponent = () => {
  const queryClient = createQueryClient();
  return render(
    <QueryClientProvider client={queryClient}>
      <ChakraProvider>
        <MemoryRouter>
          <SyncsList />
        </MemoryRouter>
      </ChakraProvider>
    </QueryClientProvider>,
  );
};

describe('SyncsList', () => {
  beforeEach(() => {
    jest.clearAllMocks();
    mockSyncsListFilters.page = '1';
    mockStoreImplementation(mockedUseStore, { workspaceId: 1 });
    mockStoreImplementation(mockedUseRoleDataStore, { activeRole: {} as Record<string, unknown> });
    mockedHasActionPermission.mockReturnValue(true);
    mockUseQuery.mockReturnValue({
      data: { data: mockSyncsList, links: {} },
      isLoading: false,
    });
  });

  it('renders loader when loading', () => {
    mockUseQuery.mockReturnValue({
      data: undefined,
      isLoading: true,
    });
    mockedUseRoleDataStore.mockReturnValue({ activeRole: {} as Record<string, unknown> });
    renderComponent();
    expect(screen.getByTestId('loader')).toBeInTheDocument();
  });

  it('renders syncs list when data is available', async () => {
    mockUseQuery.mockReturnValue({
      data: { data: mockSyncsList, links: {} },
      isLoading: false,
    });
    renderComponent();
    await waitFor(() => {
      expect(screen.getByTestId('top-bar-name')).toHaveTextContent('Syncs');
    });
  });

  it('renders Add Sync button when user has permission', async () => {
    mockedHasActionPermission.mockReturnValue(true);
    renderComponent();
    await waitFor(() => {
      expect(screen.getByTestId('top-bar-cta-button')).toBeInTheDocument();
    });
  });

  it('hides Add Sync button when user lacks permission', async () => {
    mockedHasActionPermission.mockReturnValue(false);
    renderComponent();
    await waitFor(() => {
      expect(screen.queryByTestId('top-bar-cta-button')).not.toBeInTheDocument();
    });
  });

  it('navigates to new sync page when Add Sync is clicked', async () => {
    renderComponent();
    await waitFor(() => {
      const addButton = screen.getByTestId('top-bar-cta-button');
      fireEvent.click(addButton);
      expect(mockNavigate).toHaveBeenCalledWith({
        to: 'new',
        location: 'sync',
        action: expect.any(String),
      });
    });
  });

  it('renders empty state when no syncs exist', async () => {
    mockUseQuery.mockReturnValue({
      data: { data: [], links: {} },
      isLoading: false,
    });
    renderComponent();
    await waitFor(() => {
      expect(screen.getByTestId('no-syncs')).toBeInTheDocument();
    });
  });

  it('handles row click navigation', async () => {
    renderComponent();
    await waitFor(() => {
      expect(screen.getByTestId('data-table')).toBeInTheDocument();
    });
    const rows = screen.getAllByRole('row');
    expect(rows.length).toBeGreaterThan(1);
    fireEvent.click(rows[1]);
    expect(mockNavigate).toHaveBeenCalledWith(
      expect.objectContaining({
        location: 'sync_run',
        action: 'read',
      }),
    );
  });

  it('renders pagination when links are available', async () => {
    mockUseQuery.mockReturnValue({
      data: {
        data: mockSyncsList,
        links: {
          first: 'http://example.com?page=1',
          last: 'http://example.com?page=2',
          next: 'http://example.com?page=2',
          prev: null,
          self: 'http://example.com?page=1',
        },
      },
      isLoading: false,
    });
    renderComponent();
    await waitFor(() => {
      expect(screen.getByTestId('pagination')).toBeInTheDocument();
    });
  });

  it('handles page change via pagination', async () => {
    mockUseQuery.mockReturnValue({
      data: {
        data: mockSyncsList,
        links: {
          first: 'http://example.com?page=1',
          last: 'http://example.com?page=2',
          next: 'http://example.com?page=2',
          prev: null,
          self: 'http://example.com?page=1',
        },
      },
      isLoading: false,
    });
    renderComponent();
    await waitFor(() => {
      expect(screen.getByTestId('page-change')).toBeInTheDocument();
    });
    fireEvent.click(screen.getByTestId('page-change'));
    expect(screen.getByTestId('pagination')).toBeInTheDocument();
  });

  it('renders loader when activeRole is null', () => {
    mockStoreImplementation(mockedUseRoleDataStore, { activeRole: null });
    renderComponent();
    expect(screen.getByTestId('loader')).toBeInTheDocument();
  });

  it('defaults currentPage to 1 and uses fallback page when filters.page is falsy', async () => {
    mockSyncsListFilters.page = null;
    mockUseQuery.mockReturnValue({
      data: {
        data: mockSyncsList,
        links: {
          first: 'http://example.com?page=1',
          last: 'http://example.com?page=2',
          next: 'http://example.com?page=2',
          prev: null,
          self: 'http://example.com?page=1',
        },
      },
      isLoading: false,
    });
    renderComponent();
    await waitFor(() => {
      expect(screen.getByTestId('pagination')).toBeInTheDocument();
    });
  });
});
