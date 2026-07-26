import React from 'react';
import { render, screen, fireEvent, waitFor } from '@testing-library/react';
import { expect, describe, it, beforeEach, jest } from '@jest/globals';
import '@testing-library/jest-dom/jest-globals';
import '@testing-library/jest-dom';
import { MemoryRouter } from 'react-router-dom';
import { ChakraProvider } from '@chakra-ui/react';
import { QueryClient, QueryClientProvider } from '@tanstack/react-query';
import ViewSync from '..';
import { useStore } from '@/stores';
import { useSyncStore } from '@/stores/useSyncStore';
import {
  mockSyncData,
  mockUseGetSyncById,
  mockUseTestSync,
  createMockUseGetSyncById,
  createMockUseTestSync,
} from '../../../../../../__mocks__/syncMocks';
import {
  mockApiErrorToast,
  mockErrorToast,
  mockStoreImplementation,
} from '../../../../../../__mocks__/commonMocks';
import * as syncsService from '@/services/syncs';

type ChangeSyncStatusResult = Awaited<ReturnType<typeof syncsService.changeSyncStatus>>;
const mockChangeSyncStatus = syncsService.changeSyncStatus as jest.MockedFunction<
  typeof syncsService.changeSyncStatus
>;

const createQueryClient = () =>
  new QueryClient({
    defaultOptions: {
      queries: {
        retry: false,
      },
    },
  });

const mockToast = jest.fn();
const mockSetSelectedSync = jest.fn();

jest.mock('react-router-dom', () => {
  const actual = jest.requireActual<typeof import('react-router-dom')>('react-router-dom');
  return {
    ...actual,
    useParams: () => ({ syncId: '123' }),
  };
});

jest.mock('@/hooks/syncs/useGetSyncById', () => ({
  __esModule: true,
  default: () => mockUseGetSyncById(),
}));

jest.mock('@/hooks/syncs/useTestSync', () => ({
  __esModule: true,
  default: () => mockUseTestSync(),
}));

jest.mock('@/services/syncs', () => ({
  changeSyncStatus: jest.fn(),
}));

jest.mock('@/stores', () => ({
  useStore: jest.fn(),
}));

jest.mock('@/stores/useSyncStore', () => ({
  useSyncStore: jest.fn(),
}));

jest.mock('@/hooks/useCustomToast', () => ({
  __esModule: true,
  default: () => mockToast,
}));

jest.mock('@/hooks/useErrorToast', () => ({
  useErrorToast: () => mockErrorToast,
  useAPIErrorsToast: () => mockApiErrorToast,
}));

// Mock child components but allow them to render
jest.mock('../../SyncRuns/SyncRuns', () => ({
  __esModule: true,
  default: jest.fn(() => <div data-testid='sync-runs'>SyncRuns</div>),
}));

jest.mock('../../EditSync/EditSync', () => ({
  __esModule: true,
  default: jest.fn(() => <div data-testid='edit-sync'>EditSync</div>),
}));

jest.mock('@/components/Loader', () => ({
  __esModule: true,
  default: () => <div data-testid='loader'>Loading...</div>,
}));

jest.mock('@/components/TopBar', () => ({
  __esModule: true,
  default: ({ name, extra }: { name: string; extra?: React.ReactNode }) => (
    <div data-testid='top-bar'>
      <div data-testid='top-bar-name'>{name}</div>
      {extra}
    </div>
  ),
}));

jest.mock('@/components/ContentContainer', () => ({
  __esModule: true,
  default: ({ children }: { children: React.ReactNode }) => (
    <div data-testid='content-container'>{children}</div>
  ),
}));

jest.mock('@/enterprise/components/RoleAccess', () => ({
  __esModule: true,
  default: ({ children }: { children: React.ReactNode }) => <>{children}</>,
}));

jest.mock('@/components/BaseButton', () => ({
  __esModule: true,
  default: ({ text, onClick }: { text: string; onClick: () => void }) => (
    <button data-testid={`base-button-${text}`} onClick={onClick}>
      {text}
    </button>
  ),
}));

jest.mock('../../EditSync/SyncActions', () => ({
  __esModule: true,
  default: () => <div data-testid='sync-actions'>SyncActions</div>,
}));

jest.mock('@/components/TabItem', () => ({
  __esModule: true,
  default: ({ text, action }: { text: string; action?: () => void }) => (
    <button data-testid={`tab-item-${text}`} onClick={action} role='tab'>
      {text}
    </button>
  ),
}));

jest.mock('@/components/TabsWrapper', () => {
  const React = jest.requireActual<typeof import('react')>('react');
  const chakraUI = jest.requireActual<typeof import('@chakra-ui/react')>('@chakra-ui/react');
  return {
    __esModule: true,
    default: ({ children }: { children: React.ReactNode }) =>
      React.createElement(
        chakraUI.Tabs,
        { 'data-testid': 'tabs-wrapper' } as never,
        children,
        React.createElement(chakraUI.TabIndicator),
      ),
  };
});

const mockedUseStore = useStore as jest.MockedFunction<typeof useStore>;
const mockedUseSyncStore = useSyncStore as jest.MockedFunction<typeof useSyncStore>;

const renderComponent = () => {
  const queryClient = createQueryClient();
  return render(
    <QueryClientProvider client={queryClient}>
      <ChakraProvider>
        <MemoryRouter>
          <ViewSync />
        </MemoryRouter>
      </ChakraProvider>
    </QueryClientProvider>,
  );
};

describe('ViewSync', () => {
  beforeEach(() => {
    jest.clearAllMocks();
    mockStoreImplementation(mockedUseStore, { workspaceId: 1 });
    mockStoreImplementation(mockedUseSyncStore, { setSelectedSync: mockSetSelectedSync });
    mockUseGetSyncById.mockImplementation(
      createMockUseGetSyncById({ data: mockSyncData, isLoading: false, isError: false }),
    );
    mockUseTestSync.mockImplementation(createMockUseTestSync({ isSubmitting: false }));
    mockChangeSyncStatus.mockResolvedValue({} as ChangeSyncStatusResult);
  });

  it('renders loader when loading', () => {
    mockUseGetSyncById.mockImplementation(createMockUseGetSyncById({ isLoading: true }));
    renderComponent();
    // There may be multiple loaders, use getAllByTestId and check length > 0
    expect(screen.getAllByTestId('loader').length).toBeGreaterThan(0);
  });

  it('renders sync name in top bar', () => {
    renderComponent();
    expect(screen.getByText('Test Sync')).toBeInTheDocument();
  });

  it('renders Sync Runs tab by default', () => {
    renderComponent();
    expect(screen.getByText('Sync Runs')).toBeInTheDocument();
    expect(screen.getByTestId('sync-runs')).toBeInTheDocument();
  });

  it('handles error state', () => {
    mockUseGetSyncById.mockImplementation(createMockUseGetSyncById({ isError: true }));
    renderComponent();
    expect(mockToast).toHaveBeenCalledWith(
      expect.objectContaining({
        title: 'Error!',
        description: 'Something went wrong',
      }),
    );
  });

  it('sets selected sync in store when data loads', () => {
    renderComponent();
    expect(mockSetSelectedSync).toHaveBeenCalledWith({
      syncName: 'Test Sync',
      sourceName: 'PostgreSQL',
      sourceIcon: 'postgres-icon',
      destinationName: 'Snowflake',
      destinationIcon: 'snowflake-icon',
    });
  });

  it('displays sync ID in details', () => {
    renderComponent();
    expect(screen.getByText(/Sync ID/)).toBeInTheDocument();
    expect(screen.getByText('123')).toBeInTheDocument();
  });

  it('displays last updated date', () => {
    renderComponent();
    expect(screen.getByText(/Last updated/)).toBeInTheDocument();
  });

  it('switches to Configuration tab and shows EditSync', () => {
    renderComponent();
    const configTab = screen.getByTestId('tab-item-Configuration');
    fireEvent.click(configTab);
    expect(screen.getByTestId('edit-sync')).toBeInTheDocument();
  });

  it('shows SYNC ENABLED text and switch in config tab', () => {
    renderComponent();
    const configTab = screen.getByTestId('tab-item-Configuration');
    fireEvent.click(configTab);
    expect(screen.getByText(/SYNC ENABLED/)).toBeInTheDocument();
  });

  it('shows Test Sync button in config tab for structured model', () => {
    renderComponent();
    const configTab = screen.getByTestId('tab-item-Configuration');
    fireEvent.click(configTab);
    const testSyncElements = screen.getAllByText('Test Sync');
    expect(testSyncElements.length).toBeGreaterThanOrEqual(1);
  });

  it('toggles sync status when switch is clicked', async () => {
    mockChangeSyncStatus.mockResolvedValue({
      data: { attributes: { status: 'disabled' } },
    } as ChangeSyncStatusResult);
    renderComponent();
    const configTab = screen.getByTestId('tab-item-Configuration');
    fireEvent.click(configTab);
    const switchElement = screen.getByRole('checkbox');
    fireEvent.click(switchElement);
    await waitFor(() => {
      expect(syncsService.changeSyncStatus).toHaveBeenCalledWith('123', { enable: false });
    });
  });

  it('shows error toast when changeSyncStatus fails', async () => {
    mockChangeSyncStatus.mockRejectedValue(new Error('Status change failed'));
    renderComponent();
    const configTab = screen.getByTestId('tab-item-Configuration');
    fireEvent.click(configTab);
    const switchElement = screen.getByRole('checkbox');
    fireEvent.click(switchElement);
    await waitFor(() => {
      expect(mockErrorToast).toHaveBeenCalledWith(
        "Couldn't change sync status. Please try again.",
        true,
        expect.any(Error),
        true,
      );
    });
  });

  it('shows API errors when changeSyncStatus returns errors', async () => {
    mockChangeSyncStatus.mockResolvedValue({
      errors: [{ detail: 'API error' }],
    } as ChangeSyncStatusResult);
    renderComponent();
    const configTab = screen.getByTestId('tab-item-Configuration');
    fireEvent.click(configTab);
    const switchElement = screen.getByRole('checkbox');
    fireEvent.click(switchElement);
    await waitFor(() => {
      expect(mockApiErrorToast).toHaveBeenCalledWith([{ detail: 'API error' }]);
    });
  });

  it('sets sync status to disabled when data shows disabled', () => {
    mockUseGetSyncById.mockImplementation(() => ({
      data: {
        data: {
          ...mockSyncData,
          attributes: {
            ...mockSyncData.attributes,
            status: 'disabled',
          },
        },
      },
      isLoading: false,
      isError: false,
    }));
    renderComponent();
    const configTab = screen.getByTestId('tab-item-Configuration');
    fireEvent.click(configTab);
    expect(screen.getByText(/SYNC DISABLED/)).toBeInTheDocument();
  });

  it('hides Test Sync button for unstructured model', () => {
    mockUseGetSyncById.mockImplementation(() => ({
      data: {
        data: {
          ...mockSyncData,
          attributes: {
            ...mockSyncData.attributes,
            model: {
              ...mockSyncData.attributes.model,
              connector: {
                ...mockSyncData.attributes.model.connector,
                configuration: { data_type: 'unstructured' },
              },
            },
          },
        },
      },
      isLoading: false,
      isError: false,
    }));
    renderComponent();
    const configTab = screen.getByTestId('tab-item-Configuration');
    fireEvent.click(configTab);
    expect(screen.queryByTestId('base-button-Test Sync')).not.toBeInTheDocument();
  });

  it('hides Test Sync button for semistructured model', () => {
    mockUseGetSyncById.mockImplementation(() => ({
      data: {
        data: {
          ...mockSyncData,
          attributes: {
            ...mockSyncData.attributes,
            model: {
              ...mockSyncData.attributes.model,
              connector: {
                ...mockSyncData.attributes.model.connector,
                configuration: { data_type: 'semistructured' },
              },
            },
          },
        },
      },
      isLoading: false,
      isError: false,
    }));
    renderComponent();
    const configTab = screen.getByTestId('tab-item-Configuration');
    fireEvent.click(configTab);
    expect(screen.queryByTestId('base-button-Test Sync')).not.toBeInTheDocument();
  });

  it('switches back to Sync Runs tab from Configuration', () => {
    renderComponent();
    const configTab = screen.getByTestId('tab-item-Configuration');
    fireEvent.click(configTab);
    expect(screen.getByTestId('edit-sync')).toBeInTheDocument();
    const runsTab = screen.getByTestId('tab-item-Sync Runs');
    fireEvent.click(runsTab);
    expect(screen.getByTestId('sync-runs')).toBeInTheDocument();
  });

  it('calls runTestSync when Test Sync button is clicked', () => {
    const mockRunTestSync = jest.fn();
    mockUseTestSync.mockImplementation(() => ({
      runTestSync: mockRunTestSync,
      isSubmitting: false,
    }));
    renderComponent();
    const configTab = screen.getByTestId('tab-item-Configuration');
    fireEvent.click(configTab);
    const testSyncButton = screen.getByTestId('base-button-Test Sync');
    fireEvent.click(testSyncButton);
    expect(mockRunTestSync).toHaveBeenCalled();
  });

  it('shows success toast after toggling sync status successfully', async () => {
    mockChangeSyncStatus.mockResolvedValue({
      data: { attributes: { status: 'disabled' } },
    } as ChangeSyncStatusResult);
    renderComponent();
    const configTab = screen.getByTestId('tab-item-Configuration');
    fireEvent.click(configTab);
    const switchElement = screen.getByRole('checkbox');
    fireEvent.click(switchElement);
    await waitFor(() => {
      expect(mockToast).toHaveBeenCalledWith(
        expect.objectContaining({ title: expect.stringContaining('disabled') }),
      );
    });
  });

  it('shows enabled toast when toggling from disabled to enabled', async () => {
    mockUseGetSyncById.mockImplementation(() => ({
      data: {
        data: {
          ...mockSyncData,
          attributes: {
            ...mockSyncData.attributes,
            status: 'disabled',
          },
        },
      },
      isLoading: false,
      isError: false,
    }));
    mockChangeSyncStatus.mockResolvedValue({
      data: { attributes: { status: 'active' } },
    } as ChangeSyncStatusResult);
    renderComponent();
    const configTab = screen.getByTestId('tab-item-Configuration');
    fireEvent.click(configTab);
    const switchElement = screen.getByRole('checkbox');
    fireEvent.click(switchElement);
    await waitFor(() => {
      expect(mockToast).toHaveBeenCalledWith(
        expect.objectContaining({ title: expect.stringContaining('enabled') }),
      );
    });
  });

  it('uses fallback name when sync name is not available', () => {
    mockUseGetSyncById.mockImplementation(() => ({
      data: {
        data: {
          ...mockSyncData,
          attributes: {
            ...mockSyncData.attributes,
            name: '',
          },
        },
      },
      isLoading: false,
      isError: false,
    }));
    renderComponent();
    expect(screen.getByText('Sync 123')).toBeInTheDocument();
  });
});
