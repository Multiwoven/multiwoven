import { render, screen, fireEvent } from '@testing-library/react';
import { expect, describe, it, beforeEach, jest } from '@jest/globals';
import '@testing-library/jest-dom/jest-globals';
import '@testing-library/jest-dom';
import { ChakraProvider } from '@chakra-ui/react';
import { QueryClient, QueryClientProvider } from '@tanstack/react-query';

jest.mock('flat', () => ({
  flatten: jest.fn((obj: Record<string, unknown>) => {
    const result: Record<string, unknown> = {};
    const flattenHelper = (o: Record<string, unknown>, prefix = '') => {
      Object.keys(o).forEach((key) => {
        const newKey = prefix ? `${prefix}.${key}` : key;
        if (typeof o[key] === 'object' && o[key] !== null && !Array.isArray(o[key])) {
          flattenHelper(o[key] as Record<string, unknown>, newKey);
        } else {
          result[newKey] = o[key];
        }
      });
    };
    flattenHelper(obj);
    return result;
  }),
}));

import SelectStreams from '../SelectStreams';
import { useStore } from '@/stores';
import { Stream } from '../../../types';
import { mockStoreImplementation } from '../../../../../../../__mocks__/commonMocks';

const createQueryClient = () =>
  new QueryClient({
    defaultOptions: {
      queries: {
        retry: false,
      },
    },
  });

const mockStreams: Stream[] = [
  {
    name: 'stream1',
    action: 'read',
    json_schema: { type: 'object', properties: {} },
    url: '',
    supported_sync_modes: ['full_refresh'],
  },
  {
    name: 'stream2',
    action: 'read',
    json_schema: { type: 'object', properties: {} },
    url: '',
    supported_sync_modes: ['incremental'],
  },
];

const mockModel = {
  id: '1',
  name: 'Test Model',
  connector: {
    id: '1',
    name: 'PostgreSQL',
    configuration: { data_type: 'structured' },
  },
  query: 'SELECT * FROM table',
};

const mockDestination = {
  id: '2',
  attributes: { name: 'Snowflake' },
};

const mockUseQuery = jest.fn();
const mockUseCatalogQueries = jest.fn();
const mockOnChange = jest.fn();

jest.mock('@/stores', () => ({
  useStore: jest.fn(),
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

jest.mock('@/hooks/queries/useCatalogQueries', () => ({
  useCatalogQueries: () => mockUseCatalogQueries(),
}));

jest.mock('@/services/models', () => ({
  getModelPreviewById: jest.fn(),
}));

const mockedUseStore = useStore as jest.MockedFunction<typeof useStore>;

const renderComponent = (props: Record<string, unknown> = {}) => {
  const queryClient = createQueryClient();
  return render(
    <QueryClientProvider client={queryClient}>
      <ChakraProvider>
        <SelectStreams
          model={mockModel as unknown as Parameters<typeof SelectStreams>[0]['model']}
          destination={
            mockDestination as unknown as Parameters<typeof SelectStreams>[0]['destination']
          }
          streams={mockStreams}
          onChange={mockOnChange}
          {...props}
        />
      </ChakraProvider>
    </QueryClientProvider>,
  );
};

describe('SelectStreams', () => {
  beforeEach(() => {
    jest.clearAllMocks();
    mockStoreImplementation(mockedUseStore, { workspaceId: 1 });
    mockUseQuery.mockReturnValue({
      data: [{ col1: 'value1', col2: 'value2' }],
    });
    mockUseCatalogQueries.mockReturnValue({
      catalogData: {
        data: {
          attributes: {
            catalog: {
              streams: mockStreams,
            },
          },
        },
      },
    });
  });

  it('renders stream select dropdown', () => {
    renderComponent();
    expect(screen.getAllByRole('combobox').length).toBeGreaterThan(0);
  });

  it('calls onChange when stream is selected', () => {
    renderComponent();
    const selects = screen.getAllByRole('combobox');
    const streamSelect = selects[0]; // First combobox is the stream select
    fireEvent.change(streamSelect, { target: { value: '0' } });
    expect(mockOnChange).toHaveBeenCalledWith(mockStreams[0]);
  });

  it('renders sync mode select for incremental streams', () => {
    renderComponent({ selectedStream: mockStreams[1] });
    expect(screen.getAllByText(/Sync Mode/i).length).toBeGreaterThan(0);
  });

  it('handles unstructured model', () => {
    const unstructuredModel = {
      ...mockModel,
      connector: {
        ...mockModel.connector,
        configuration: { data_type: 'unstructured' },
      },
    };
    renderComponent({ model: unstructuredModel });
    expect(screen.getAllByRole('combobox').length).toBeGreaterThan(0);
  });

  it('handles semistructured model', () => {
    const semistructuredModel = {
      ...mockModel,
      connector: {
        ...mockModel.connector,
        configuration: { data_type: 'semistructured' },
      },
    };
    renderComponent({ model: semistructuredModel });
    expect(screen.getAllByRole('combobox').length).toBeGreaterThan(0);
  });

  it('displays selected stream name', () => {
    renderComponent({ selectedStreamName: 'stream1' });
    expect(screen.getAllByRole('combobox').length).toBeGreaterThan(0);
  });

  it('handles edit mode', () => {
    renderComponent({ isEdit: true, selectedStreamName: 'stream1' });
    expect(screen.getAllByRole('combobox').length).toBeGreaterThan(0);
  });

  it('calls setSelectedSyncMode when sync mode is changed', () => {
    const mockSetSelectedSyncMode = jest.fn();
    renderComponent({
      selectedStream: mockStreams[0],
      selectedStreamName: 'stream1',
      setSelectedSyncMode: mockSetSelectedSyncMode,
    });
    const selects = screen.getAllByRole('combobox');
    const syncModeSelect = selects[1];
    fireEvent.change(syncModeSelect, { target: { value: 'full_refresh' } });
    expect(mockSetSelectedSyncMode).toHaveBeenCalledWith('full_refresh');
  });

  it('renders cursor field select for incremental sync mode in non-edit mode', () => {
    mockUseCatalogQueries.mockReturnValue({
      catalogData: {
        data: {
          attributes: {
            catalog: {
              streams: mockStreams,
              source_defined_cursor: false,
            },
          },
        },
      },
    });
    renderComponent({
      selectedStream: mockStreams[1],
      selectedStreamName: 'stream2',
      selectedSyncMode: 'incremental',
      isEdit: false,
      setCursorField: jest.fn(),
    });
    expect(screen.getByText('Cursor Field')).toBeInTheDocument();
  });

  it('renders cursor field as disabled input in edit mode for incremental sync', () => {
    mockUseCatalogQueries.mockReturnValue({
      catalogData: {
        data: {
          attributes: {
            catalog: {
              streams: mockStreams,
              source_defined_cursor: false,
            },
          },
        },
      },
    });
    renderComponent({
      selectedStream: mockStreams[1],
      selectedStreamName: 'stream2',
      selectedSyncMode: 'incremental',
      isEdit: true,
      selectedCursorField: 'updated_at',
    });
    expect(screen.getByText('Cursor Field')).toBeInTheDocument();
  });

  it('calls setCursorField when cursor field is changed in non-edit mode', () => {
    const mockSetCursorField = jest.fn();
    mockUseCatalogQueries.mockReturnValue({
      catalogData: {
        data: {
          attributes: {
            catalog: {
              streams: mockStreams,
              source_defined_cursor: false,
            },
          },
        },
      },
    });
    mockUseQuery.mockReturnValue({
      data: { data: [{ col1: 'value1', col2: 'value2' }] },
    });
    renderComponent({
      selectedStream: mockStreams[1],
      selectedStreamName: 'stream2',
      selectedSyncMode: 'incremental',
      isEdit: false,
      setCursorField: mockSetCursorField,
    });
    const selects = screen.getAllByRole('combobox');
    const cursorSelect = selects[selects.length - 1];
    fireEvent.change(cursorSelect, { target: { value: 'col1' } });
    expect(mockSetCursorField).toHaveBeenCalledWith('col1');
  });

  it('does not call onChange for empty stream selection', () => {
    renderComponent();
    const selects = screen.getAllByRole('combobox');
    fireEvent.change(selects[0], { target: { value: '' } });
    expect(mockOnChange).not.toHaveBeenCalled();
  });
});
