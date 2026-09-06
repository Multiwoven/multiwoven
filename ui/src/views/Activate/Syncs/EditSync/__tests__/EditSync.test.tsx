import React from 'react';
import { render, screen, fireEvent, waitFor } from '@testing-library/react';
import { expect, describe, it, beforeEach, jest } from '@jest/globals';
import '@testing-library/jest-dom/jest-globals';
import '@testing-library/jest-dom';
import { MemoryRouter } from 'react-router-dom';
import { ChakraProvider } from '@chakra-ui/react';

import { QueryClient, QueryClientProvider } from '@tanstack/react-query';
// Use manual mock from __mocks__/react.js
jest.mock('react');
import EditSync from '../EditSync';
import { useStore } from '@/stores';
import { mockSyncData } from '../../../../../../__mocks__/syncMocks';
import * as connectorsService from '@/services/connectors';
import type { ConnectorInfoResponse } from '@/views/Connectors/types';
import { mockStoreImplementation } from '../../../../../../__mocks__/commonMocks';

const createQueryClient = () =>
  new QueryClient({
    defaultOptions: {
      queries: {
        retry: false,
      },
    },
  });

const mockUseGetSyncById = jest.fn();
const mockUseEditSync = jest.fn();
const mockUseManualSync = jest.fn();
const mockUseSyncRuns = jest.fn();
const mockUseCatalogQueries = jest.fn();
const mockToast = jest.fn();
const mockApiErrorToast = jest.fn();

// Ensure React is properly available - don't mock it, just ensure it's available
// React should work fine in tests without mocking

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

jest.mock('@/hooks/syncs/useEditSync', () => ({
  __esModule: true,
  default: () => mockUseEditSync(),
}));

jest.mock('@/hooks/syncs/useManualSync', () => ({
  __esModule: true,
  default: () => mockUseManualSync(),
}));

jest.mock('@/hooks/syncs/useSyncRuns', () => ({
  __esModule: true,
  default: () => mockUseSyncRuns(),
}));

jest.mock('@/hooks/queries/useCatalogQueries', () => ({
  useCatalogQueries: () => mockUseCatalogQueries(),
}));

jest.mock('@/services/connectors', () => ({
  getConnectorInfo: jest.fn(),
}));

jest.mock('@/stores', () => ({
  useStore: jest.fn(),
}));

const mockUseQuery = jest.fn();
jest.mock('@tanstack/react-query', () => ({
  ...(jest.requireActual('@tanstack/react-query') as Record<string, unknown>),
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
}));

jest.mock('@/hooks/useCustomToast', () => ({
  __esModule: true,
  default: () => mockToast,
}));

jest.mock('@/hooks/useErrorToast', () => ({
  useAPIErrorsToast: () => mockApiErrorToast,
}));

jest.mock('@/components/Loader', () => ({
  __esModule: true,
  default: () => <div data-testid='loader'>Loading...</div>,
}));

jest.mock('../ScheduleForm', () => ({
  __esModule: true,
  default: () => <div data-testid='schedule-form'>ScheduleForm</div>,
}));

jest.mock('../../SyncForm/ConfigureSyncs/SelectStreams', () => ({
  __esModule: true,
  default: ({ onChange }: { onChange: (stream: { name: string }) => void }) => (
    <div data-testid='select-streams'>
      <button onClick={() => onChange({ name: 'stream1' })}>Select Stream</button>
    </div>
  ),
}));

jest.mock('../../SyncForm/ConfigureSyncs/MapFields', () => ({
  __esModule: true,
  default: ({ handleOnConfigChange }: { handleOnConfigChange: (config: unknown[]) => void }) => (
    <div data-testid='map-fields'>
      <button onClick={() => handleOnConfigChange([])}>Update Config</button>
    </div>
  ),
}));

jest.mock('../../SyncForm/ConfigureSyncs/MapCustomFields', () => ({
  __esModule: true,
  default: () => <div data-testid='map-custom-fields'>MapCustomFields</div>,
}));

jest.mock('@/components/FormFooter', () => ({
  __esModule: true,
  default: ({
    ctaName,
    extra,
    isCtaDisabled,
  }: {
    ctaName: string;
    extra?: React.ReactNode;
    isCtaDisabled?: boolean;
  }) => (
    <div data-testid='form-footer' data-disabled={isCtaDisabled}>
      <span>{ctaName}</span>
      {extra}
    </div>
  ),
}));

jest.mock('@/components/BaseButton', () => ({
  __esModule: true,
  default: ({ text, onClick }: { text: string; onClick: () => void }) => (
    <button data-testid='base-button' onClick={onClick}>
      {text}
    </button>
  ),
}));

jest.mock('@/components/Alerts/Alerts', () => ({
  __esModule: true,
  default: () => <div data-testid='alert-box'>AlertBox</div>,
}));

const mockedUseStore = useStore as jest.MockedFunction<typeof useStore>;

const renderComponent = () => {
  const queryClient = createQueryClient();
  return render(
    <QueryClientProvider client={queryClient}>
      <ChakraProvider>
        <MemoryRouter>
          <EditSync />
        </MemoryRouter>
      </ChakraProvider>
    </QueryClientProvider>,
  );
};

describe('EditSync', () => {
  beforeEach(() => {
    jest.clearAllMocks();
    mockStoreImplementation(mockedUseStore, { workspaceId: 1 });
    // Mock useQuery to return destination data
    mockUseQuery.mockReturnValue({
      data: { data: { attributes: { name: 'Test Destination', id: '2' } } },
      isLoading: false,
      isError: false,
    });
    mockUseGetSyncById.mockReturnValue({
      data: { data: { attributes: mockSyncData.attributes } },
      isLoading: false,
      isError: false,
    });
    mockUseEditSync.mockReturnValue({
      handleSubmit: jest.fn(),
      selectedSyncMode: 'full_refresh',
      setSelectedSyncMode: jest.fn(),
      cursorField: '',
      setCursorField: jest.fn(),
    });
    mockUseManualSync.mockReturnValue({
      isSubmitting: false,
      runSyncNow: jest.fn(),
      showCancelSync: false,
      setShowCancelSync: jest.fn(),
    });
    mockUseSyncRuns.mockReturnValue({
      data: { data: [] },
    });
    mockUseCatalogQueries.mockReturnValue({
      catalogData: {
        data: {
          attributes: {
            catalog: {
              streams: [{ name: 'stream1' }],
            },
          },
        },
      },
      handleRefreshCatalog: jest.fn(),
      isRefreshingCatalog: false,
    });
    (
      connectorsService.getConnectorInfo as jest.MockedFunction<
        typeof connectorsService.getConnectorInfo
      >
    ).mockResolvedValue({
      data: { id: '2' },
    } as ConnectorInfoResponse);
  });

  it('renders loader when loading', () => {
    mockUseGetSyncById.mockReturnValue({
      data: undefined,
      isLoading: true,
      isError: false,
    });
    renderComponent();
    expect(screen.getByTestId('loader')).toBeInTheDocument();
  });

  it('shows error toast on error', () => {
    mockUseGetSyncById.mockReturnValue({
      data: undefined,
      isLoading: false,
      isError: true,
    });
    renderComponent();
    expect(mockToast).toHaveBeenCalled();
  });

  it('triggers syncFetchResponse effect with array configuration', () => {
    mockUseQuery.mockReturnValue({
      data: undefined,
      isLoading: false,
      isError: false,
    });
    mockUseGetSyncById.mockReturnValue({
      data: {
        data: {
          attributes: {
            ...mockSyncData.attributes,
            configuration: [{ from: 'a', to: 'b', mapping_type: 'standard' }],
          },
        },
      },
      isLoading: false,
      isError: false,
    });
    renderComponent();
    expect(screen.getByTestId('form-footer')).toBeInTheDocument();
  });

  it('triggers syncFetchResponse effect with object configuration', () => {
    mockUseQuery.mockReturnValue({
      data: undefined,
      isLoading: false,
      isError: false,
    });
    mockUseGetSyncById.mockReturnValue({
      data: {
        data: {
          attributes: {
            ...mockSyncData.attributes,
            configuration: { field1: 'value1', field2: 'value2' },
          },
        },
      },
      isLoading: false,
      isError: false,
    });
    renderComponent();
    expect(screen.getByTestId('form-footer')).toBeInTheDocument();
  });

  it('shows API errors toast when catalog has errors', () => {
    mockUseQuery.mockReturnValue({
      data: undefined,
      isLoading: false,
      isError: false,
    });
    mockUseCatalogQueries.mockReturnValue({
      catalogData: {
        errors: [{ detail: 'Catalog error' }],
      },
      handleRefreshCatalog: jest.fn(),
      isRefreshingCatalog: false,
    });
    renderComponent();
    expect(mockApiErrorToast).toHaveBeenCalled();
  });

  it('loads streams from catalog data', () => {
    mockUseQuery.mockReturnValue({
      data: undefined,
      isLoading: false,
      isError: false,
    });
    mockUseCatalogQueries.mockReturnValue({
      catalogData: {
        data: {
          attributes: {
            catalog: {
              streams: [{ name: 'test_stream' }],
            },
          },
        },
      },
      handleRefreshCatalog: jest.fn(),
      isRefreshingCatalog: false,
    });
    renderComponent();
    expect(screen.getByTestId('form-footer')).toBeInTheDocument();
  });

  it('sets showCancelSync when latest sync run is in progress', () => {
    const mockSetShowCancelSync = jest.fn();
    mockUseManualSync.mockReturnValue({
      isSubmitting: false,
      runSyncNow: jest.fn(),
      showCancelSync: false,
      setShowCancelSync: mockSetShowCancelSync,
    });
    mockUseSyncRuns.mockReturnValue({
      data: {
        data: [
          {
            attributes: { status: 'in_progress' },
          },
        ],
      },
    });
    mockUseQuery.mockReturnValue({
      data: undefined,
      isLoading: false,
      isError: false,
    });
    renderComponent();
    expect(mockSetShowCancelSync).toHaveBeenCalledWith(true);
  });

  it('does not set showCancelSync for completed sync runs', () => {
    const mockSetShowCancelSync = jest.fn();
    mockUseManualSync.mockReturnValue({
      isSubmitting: false,
      runSyncNow: jest.fn(),
      showCancelSync: false,
      setShowCancelSync: mockSetShowCancelSync,
    });
    mockUseSyncRuns.mockReturnValue({
      data: {
        data: [
          {
            attributes: { status: 'success' },
          },
        ],
      },
    });
    mockUseQuery.mockReturnValue({
      data: undefined,
      isLoading: false,
      isError: false,
    });
    renderComponent();
    expect(mockSetShowCancelSync).not.toHaveBeenCalled();
  });

  it('renders full component with sync data and destination', () => {
    renderComponent();
    expect(screen.getByTestId('select-streams')).toBeInTheDocument();
    expect(screen.getByTestId('map-fields')).toBeInTheDocument();
    expect(screen.getByTestId('schedule-form')).toBeInTheDocument();
  });

  it('renders MapCustomFields for schemaless mode', () => {
    mockUseCatalogQueries.mockReturnValue({
      catalogData: {
        data: {
          attributes: {
            catalog: {
              streams: [{ name: 'stream1' }],
              schema_mode: 'schemaless',
            },
          },
        },
      },
      handleRefreshCatalog: jest.fn(),
      isRefreshingCatalog: false,
    });
    renderComponent();
    expect(screen.getByTestId('map-custom-fields')).toBeInTheDocument();
  });

  it('renders manual schedule with AlertBox and Run Now button', () => {
    mockUseGetSyncById.mockReturnValue({
      data: {
        data: {
          attributes: {
            ...mockSyncData.attributes,
            schedule_type: 'manual',
            sync_interval: 0,
            sync_interval_unit: 'minutes',
          },
        },
      },
      isLoading: false,
      isError: false,
    });
    renderComponent();
    expect(screen.getByTestId('alert-box')).toBeInTheDocument();
    expect(screen.getByText('Run Now')).toBeInTheDocument();
  });

  it('renders Cancel Run button when showCancelSync is true', () => {
    mockUseManualSync.mockReturnValue({
      isSubmitting: false,
      runSyncNow: jest.fn(),
      showCancelSync: true,
      setShowCancelSync: jest.fn(),
    });
    mockUseGetSyncById.mockReturnValue({
      data: {
        data: {
          attributes: {
            ...mockSyncData.attributes,
            schedule_type: 'manual',
          },
        },
      },
      isLoading: false,
      isError: false,
    });
    renderComponent();
    expect(screen.getByText('Cancel Run')).toBeInTheDocument();
  });

  it('calls runSyncNow when Run Now button is clicked', async () => {
    const mockRunSyncNow = jest.fn<() => Promise<void>>().mockResolvedValue(undefined);
    mockUseManualSync.mockReturnValue({
      isSubmitting: false,
      runSyncNow: mockRunSyncNow,
      showCancelSync: false,
      setShowCancelSync: jest.fn(),
    });
    mockUseGetSyncById.mockReturnValue({
      data: {
        data: {
          attributes: {
            ...mockSyncData.attributes,
            schedule_type: 'manual',
          },
        },
      },
      isLoading: false,
      isError: false,
    });
    renderComponent();
    fireEvent.click(screen.getByText('Run Now'));
    await waitFor(() => {
      expect(mockRunSyncNow).toHaveBeenCalledWith('post');
    });
  });

  it('calls handleOnConfigChange via MapFields Update Config button', () => {
    renderComponent();
    const updateButton = screen.getByText('Update Config');
    fireEvent.click(updateButton);
    expect(screen.getByTestId('map-fields')).toBeInTheDocument();
  });

  it('handles streams loaded from catalog with matching stream_name', () => {
    mockUseCatalogQueries.mockReturnValue({
      catalogData: {
        data: {
          attributes: {
            catalog: {
              streams: [{ name: mockSyncData.attributes.stream_name }],
            },
          },
        },
      },
      handleRefreshCatalog: jest.fn(),
      isRefreshingCatalog: false,
    });
    renderComponent();
    expect(screen.getByTestId('select-streams')).toBeInTheDocument();
  });

  it('disables save when vector field has incomplete embedding config', () => {
    mockUseGetSyncById.mockReturnValue({
      data: {
        data: {
          attributes: {
            ...mockSyncData.attributes,
            configuration: [
              {
                from: 'a',
                to: 'b',
                mapping_type: 'standard',
                field_type: 'vector',
                hide_embedding: false,
                embedding_config: { api_key: '', mode: '', model: '' },
              },
            ],
          },
        },
      },
      isLoading: false,
      isError: false,
    });
    renderComponent();
    expect(screen.getByTestId('form-footer')).toHaveAttribute('data-disabled', 'true');
  });

  it('does not disable save when vector field has hide_embedding set', () => {
    mockUseGetSyncById.mockReturnValue({
      data: {
        data: {
          attributes: {
            ...mockSyncData.attributes,
            configuration: [
              {
                from: 'a',
                to: 'b',
                mapping_type: 'standard',
                field_type: 'vector',
                hide_embedding: true,
              },
            ],
          },
        },
      },
      isLoading: false,
      isError: false,
    });
    renderComponent();
    expect(screen.getByTestId('form-footer')).not.toHaveAttribute('data-disabled', 'true');
  });

  it('uses fallback values when sync data attributes are null', () => {
    mockUseGetSyncById.mockReturnValue({
      data: {
        data: {
          attributes: {
            ...mockSyncData.attributes,
            sync_interval: null,
            sync_interval_unit: null,
            sync_mode: null,
            schedule_type: null,
            cron_expression: null,
            configuration: [],
          },
        },
      },
      isLoading: false,
      isError: false,
    });
    renderComponent();
    expect(screen.getByTestId('form-footer')).toBeInTheDocument();
  });

  it('handles null cursor_field in sync data', () => {
    mockUseGetSyncById.mockReturnValue({
      data: {
        data: {
          attributes: {
            ...mockSyncData.attributes,
            cursor_field: null,
          },
        },
      },
      isLoading: false,
      isError: false,
    });
    renderComponent();
    expect(screen.getByTestId('form-footer')).toBeInTheDocument();
  });

  it('handles workspace ID of 0', () => {
    mockStoreImplementation(mockedUseStore, { workspaceId: 0 });
    renderComponent();
    expect(screen.getByTestId('form-footer')).toBeInTheDocument();
  });

  it('shows loader when connector info is loading', () => {
    mockUseQuery.mockReturnValue({
      data: undefined,
      isLoading: true,
      isError: false,
    });
    renderComponent();
    expect(screen.getByTestId('loader')).toBeInTheDocument();
  });

  it('handles null configuration with object fallback', () => {
    mockUseGetSyncById.mockReturnValue({
      data: {
        data: {
          attributes: {
            ...mockSyncData.attributes,
            configuration: null,
          },
        },
      },
      isLoading: false,
      isError: false,
    });
    renderComponent();
    expect(screen.getByTestId('form-footer')).toBeInTheDocument();
  });

  it('handles null syncList data', () => {
    mockUseSyncRuns.mockReturnValue({
      data: null,
    });
    renderComponent();
    expect(screen.getByTestId('form-footer')).toBeInTheDocument();
  });
});
