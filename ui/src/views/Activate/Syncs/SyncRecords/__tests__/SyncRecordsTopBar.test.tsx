import React from 'react';
import { render, screen } from '@testing-library/react';
import { expect, describe, it, beforeEach, jest } from '@jest/globals';
import '@testing-library/jest-dom/jest-globals';
import '@testing-library/jest-dom';
import { MemoryRouter } from 'react-router-dom';
import { ChakraProvider } from '@chakra-ui/react';
import { QueryClient, QueryClientProvider } from '@tanstack/react-query';
import { SyncRecordsTopBar } from '../SyncRecordsTopBar';
import { getSyncRunById } from '@/services/syncs';
import { useStore } from '@/stores';
import { useSyncStore } from '@/stores/useSyncStore';
import { mockStoreImplementation } from '../../../../../../__mocks__/commonMocks';

const createQueryClient = () =>
  new QueryClient({
    defaultOptions: {
      queries: {
        retry: false,
      },
    },
  });

const mockSyncRunData = {
  data: {
    id: '456',
    attributes: {
      status: 'success',
      started_at: '2024-01-01T00:00:00Z',
      duration: 120,
    },
  },
};

const mockUseQuery = jest.fn();
const mockToast = jest.fn();
const mockApiErrorToast = jest.fn();
const mockSetSelectedSync = jest.fn();

jest.mock('@/services/syncs', () => ({
  getSyncRunById: jest.fn(),
}));

jest.mock('@/stores', () => ({
  useStore: jest.fn(),
}));

jest.mock('@/stores/useSyncStore', () => ({
  useSyncStore: jest.fn(),
}));

jest.mock('@tanstack/react-query', () => {
  const actual =
    jest.requireActual<typeof import('@tanstack/react-query')>('@tanstack/react-query');
  return {
    ...actual,
    useQuery: (opts: { queryFn?: () => unknown; enabled?: boolean }) => {
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

jest.mock('@/hooks/useCustomToast', () => ({
  __esModule: true,
  default: () => mockToast,
}));

jest.mock('@/hooks/useErrorToast', () => ({
  useAPIErrorsToast: () => mockApiErrorToast,
}));

type BreadcrumbStep = { name: string; url?: string };

jest.mock('@/components/TopBar', () => ({
  __esModule: true,
  default: ({
    name,
    breadcrumbSteps,
    extra,
  }: {
    name: string;
    breadcrumbSteps?: BreadcrumbStep[];
    extra?: React.ReactNode;
  }) => (
    <div data-testid='top-bar'>
      <div data-testid='top-bar-name'>{name}</div>
      <div data-testid='top-bar-breadcrumbs'>
        {breadcrumbSteps?.map((step: BreadcrumbStep, idx: number) => (
          <span key={idx}>{step.name}</span>
        ))}
      </div>
      <div data-testid='top-bar-extra'>{extra}</div>
    </div>
  ),
}));

const mockedUseStore = useStore as jest.MockedFunction<typeof useStore>;
const mockedUseSyncStore = useSyncStore as jest.MockedFunction<typeof useSyncStore>;
const mockedGetSyncRunById = getSyncRunById as jest.MockedFunction<typeof getSyncRunById>;

const renderComponent = () => {
  const queryClient = createQueryClient();
  return render(
    <QueryClientProvider client={queryClient}>
      <ChakraProvider>
        <MemoryRouter>
          <SyncRecordsTopBar syncId='123' syncRunId='456' />
        </MemoryRouter>
      </ChakraProvider>
    </QueryClientProvider>,
  );
};

describe('SyncRecordsTopBar', () => {
  beforeEach(() => {
    jest.clearAllMocks();
    mockStoreImplementation(mockedUseStore, { workspaceId: 1 });
    mockStoreImplementation(mockedUseSyncStore, {
      selectedSync: { syncName: 'Test Sync' },
      setSelectedSync: mockSetSelectedSync,
    });
    mockUseQuery.mockReturnValue({
      data: mockSyncRunData,
      isError: false,
    });
    mockedGetSyncRunById.mockResolvedValue(
      mockSyncRunData as Awaited<ReturnType<typeof getSyncRunById>>,
    );
  });

  it('renders top bar with name', () => {
    renderComponent();
    expect(screen.getByTestId('top-bar-name')).toHaveTextContent('Sync Run');
  });

  it('renders breadcrumbs', () => {
    renderComponent();
    expect(screen.getByText('Syncs')).toBeInTheDocument();
    expect(screen.getByText(/Test Sync|Sync 123/)).toBeInTheDocument();
    expect(screen.getByText('Run 456')).toBeInTheDocument();
  });

  it('displays run ID', () => {
    renderComponent();
    expect(screen.getByText(/Run ID/)).toBeInTheDocument();
    expect(screen.getByText('456')).toBeInTheDocument();
  });

  it('displays start time', () => {
    renderComponent();
    expect(screen.getByText(/Start Time/)).toBeInTheDocument();
  });

  it('displays duration when available', () => {
    renderComponent();
    expect(screen.getByText(/Duration/)).toBeInTheDocument();
  });

  it('handles error state', () => {
    mockUseQuery.mockReturnValue({
      data: undefined,
      isError: true,
    });
    renderComponent();
    expect(mockToast).toHaveBeenCalledWith(
      expect.objectContaining({
        title: 'Error!',
        description: 'Something went wrong',
      }),
    );
  });

  it('shows API errors when present', () => {
    mockUseQuery.mockReturnValue({
      data: { errors: [{ detail: 'Error message' }] },
      isError: false,
    });
    renderComponent();
    expect(mockApiErrorToast).toHaveBeenCalledWith([{ detail: 'Error message' }]);
  });

  it('uses fallback sync name when syncName is empty', () => {
    mockStoreImplementation(mockedUseSyncStore, {
      selectedSync: { syncName: '' },
      setSelectedSync: mockSetSelectedSync,
    });
    renderComponent();
    expect(screen.getByText('Sync 123')).toBeInTheDocument();
  });

  it('hides duration when not available', () => {
    mockUseQuery.mockReturnValue({
      data: {
        data: {
          id: '456',
          attributes: {
            status: 'success',
            started_at: '2024-01-01T00:00:00Z',
            duration: null,
          },
        },
      },
      isError: false,
    });
    renderComponent();
    expect(screen.queryByText(/Duration/)).not.toBeInTheDocument();
  });

  it('does not fetch when workspaceId is 0', () => {
    mockStoreImplementation(mockedUseStore, { workspaceId: 0 });
    mockUseQuery.mockReturnValue({
      data: undefined,
      isError: false,
    });
    renderComponent();
    expect(mockedGetSyncRunById).not.toHaveBeenCalled();
  });
});
