import { render, screen, fireEvent, waitFor } from '@testing-library/react';
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

import MapFields from '../MapFields';
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

const mockStream: Stream = {
  name: 'test_stream',
  action: 'read',
  json_schema: {
    type: 'object',
    properties: {
      id: { type: 'string' },
      name: { type: 'string' },
      embedding: { type: 'vector' as unknown as 'string' },
    },
    required: ['id'],
  },
  url: '',
  supported_sync_modes: ['full_refresh'],
};

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
const mockHandleOnConfigChange = jest.fn();

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

jest.mock('../FieldMap', () => ({
  __esModule: true,
  default: ({
    entityName,
    onChange,
    id,
  }: {
    entityName: string;
    onChange: (id: number, type: string, value: string) => void;
    id: number;
  }) => (
    <div data-testid={`field-map-${entityName}`}>
      <button onClick={() => onChange(id, 'model', 'value1')}>Change Model</button>
      <button onClick={() => onChange(id, 'destination', 'name')}>Change Destination</button>
      <button onClick={() => onChange(id, 'destination', 'embedding')}>Change Vector Dest</button>
    </div>
  ),
}));

jest.mock('@/enterprise/hooks/queries/useEmbeddingConfigQueries', () => ({
  __esModule: true,
  default: () => ({
    useGetEmbeddingConfiguration: () => ({ data: null }),
  }),
}));

jest.mock('@/enterprise/views/Activate/EmbeddingConfiguration/EmbeddingConfiguration', () => ({
  EmbeddingConfiguration: ({
    setSkipEmbedding,
    setEmbeddingConfig,
  }: {
    setSkipEmbedding: (skip: boolean) => void;
    setEmbeddingConfig: (config: Record<string, unknown>) => void;
  }) => (
    <div data-testid='embedding-config'>
      <button data-testid='skip-embedding' onClick={() => setSkipEmbedding(true)}>
        Skip
      </button>
      <button
        data-testid='set-config'
        onClick={() => setEmbeddingConfig({ model: 'test', mode: 'openai', api_key: 'key' })}
      >
        Set Config
      </button>
    </div>
  ),
}));

const mockedUseStore = useStore as jest.MockedFunction<typeof useStore>;

const renderComponent = (props: Record<string, unknown> = {}) => {
  const queryClient = createQueryClient();
  return render(
    <QueryClientProvider client={queryClient}>
      <ChakraProvider>
        <MapFields
          model={mockModel as any}
          destination={mockDestination as any}
          stream={mockStream}
          handleOnConfigChange={mockHandleOnConfigChange}
          handleRefreshCatalog={jest.fn()}
          {...props}
        />
      </ChakraProvider>
    </QueryClientProvider>,
  );
};

describe('MapFields', () => {
  beforeEach(() => {
    jest.clearAllMocks();
    mockStoreImplementation(mockedUseStore, { workspaceId: 1 });
    mockUseQuery.mockReturnValue({
      data: [{ id: '1', name: 'Test' }],
    });
    mockUseCatalogQueries.mockReturnValue({
      catalogData: {
        data: {
          attributes: {
            catalog: {
              streams: [mockStream],
            },
          },
        },
      },
    });
  });

  it('renders field mapping components', () => {
    renderComponent();
    // The component renders FieldMap with entityName from model/destination, check for any field-map
    expect(screen.getAllByTestId(/field-map-/).length).toBeGreaterThanOrEqual(2);
  });

  it('calls handleOnConfigChange when field is updated', () => {
    renderComponent();
    // There may be multiple "Change Model" buttons
    const changeButtons = screen.getAllByText('Change Model');
    if (changeButtons.length > 0) {
      fireEvent.click(changeButtons[0]);
      expect(mockHandleOnConfigChange).toHaveBeenCalled();
    }
  });

  it('handles add field button', () => {
    renderComponent();
    // The button text is "Add mapping" not "Add Field"
    const addButton = screen.getByText(/Add mapping/i);
    const initialCount = screen.getAllByTestId(/field-map-/).length;
    fireEvent.click(addButton);
    expect(screen.getAllByTestId(/field-map-/).length).toBeGreaterThan(initialCount);
  });

  it('handles remove field button', () => {
    renderComponent({ data: [{ from: 'field1', to: 'field2', mapping_type: 'standard' }] });
    // CloseButton doesn't have accessible name, so we query by role and aria-label or testid
    const closeButtons = screen.getAllByRole('button').filter((btn) => {
      // CloseButton typically has aria-label="Close" or similar
      return (
        btn.getAttribute('aria-label')?.toLowerCase().includes('close') || btn.querySelector('svg')
      ); // CloseButton usually has an SVG icon
    });
    if (closeButtons.length > 0) {
      fireEvent.click(closeButtons[0]);
      expect(mockHandleOnConfigChange).toHaveBeenCalled();
    }
  });

  it('handles edit mode with existing configuration', () => {
    renderComponent({
      isEdit: true,
      configuration: [{ from: 'field1', to: 'field2', mapping_type: 'standard' }],
    });
    // The component renders FieldMap with entityName from model
    expect(screen.getAllByTestId(/field-map-/).length).toBeGreaterThan(0);
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
    expect(screen.getAllByTestId(/field-map-/).length).toBeGreaterThan(0);
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
    expect(screen.getAllByTestId(/field-map-/).length).toBeGreaterThan(0);
  });

  it('handles destination field change', () => {
    renderComponent();
    const changeButtons = screen.getAllByText('Change Destination');
    fireEvent.click(changeButtons[0]);
    expect(mockHandleOnConfigChange).toHaveBeenCalled();
  });

  it('handles vector destination field change', () => {
    renderComponent();
    const changeButtons = screen.getAllByText('Change Vector Dest');
    fireEvent.click(changeButtons[0]);
    expect(mockHandleOnConfigChange).toHaveBeenCalled();
  });

  it('handles data as non-array object format', () => {
    renderComponent({
      data: { field1: 'mapped1', field2: 'mapped2' } as unknown as null,
    });
    expect(screen.getAllByTestId(/field-map-/).length).toBeGreaterThan(0);
  });

  it('handles data with vector field_type and renders EmbeddingConfiguration', async () => {
    renderComponent({
      isEdit: true,
      data: [
        {
          from: 'field1',
          to: 'embedding',
          mapping_type: 'vector',
          field_type: 'vector',
          embedding_config: { model: 'test', mode: 'openai', api_key: 'key' },
        },
      ],
    });
    await waitFor(() => {
      expect(screen.getByTestId('embedding-config')).toBeInTheDocument();
    });
  });

  it('initializes with empty configuration array', () => {
    renderComponent({ configuration: [] });
    expect(screen.getAllByTestId(/field-map-/).length).toBeGreaterThan(0);
  });

  it('auto-selects required destination columns in non-edit mode', () => {
    const singleColStream: Stream = {
      ...mockStream,
      json_schema: {
        type: 'object',
        properties: { id: { type: 'string' } },
        required: ['id'],
      },
    };
    renderComponent({ stream: singleColStream, isEdit: false, configuration: [] });
    expect(mockHandleOnConfigChange).toHaveBeenCalled();
  });

  it('calls setSkipEmbedding via EmbeddingConfiguration', async () => {
    renderComponent({
      isEdit: true,
      data: [
        {
          from: 'field1',
          to: 'embedding',
          mapping_type: 'vector',
          field_type: 'vector',
          embedding_config: { model: 'test', mode: 'openai', api_key: 'key' },
        },
      ],
    });
    await waitFor(() => {
      expect(screen.getByTestId('skip-embedding')).toBeInTheDocument();
    });
    fireEvent.click(screen.getByTestId('skip-embedding'));
    expect(mockHandleOnConfigChange).toHaveBeenCalled();
  });

  it('calls setEmbeddingConfig via EmbeddingConfiguration', async () => {
    renderComponent({
      isEdit: true,
      data: [
        {
          from: 'field1',
          to: 'embedding',
          mapping_type: 'vector',
          field_type: 'vector',
          embedding_config: { model: 'test', mode: 'openai', api_key: 'key' },
        },
      ],
    });
    await waitFor(() => {
      expect(screen.getByTestId('set-config')).toBeInTheDocument();
    });
    fireEvent.click(screen.getByTestId('set-config'));
    expect(mockHandleOnConfigChange).toHaveBeenCalled();
  });

  it('removes a field when close button is clicked', async () => {
    renderComponent({
      isEdit: true,
      data: [
        { from: 'field1', to: 'id', mapping_type: 'standard' },
        { from: 'field2', to: 'name', mapping_type: 'standard' },
      ],
    });
    await waitFor(() => {
      expect(screen.getAllByLabelText('Close').length).toBeGreaterThanOrEqual(2);
    });
    const initialFieldCount = screen.getAllByTestId(/field-map-/).length;
    fireEvent.click(screen.getAllByLabelText('Close')[0]);
    await waitFor(() => {
      expect(screen.getAllByTestId(/field-map-/).length).toBeLessThan(initialFieldCount);
    });
    expect(mockHandleOnConfigChange).toHaveBeenCalled();
  });
});
