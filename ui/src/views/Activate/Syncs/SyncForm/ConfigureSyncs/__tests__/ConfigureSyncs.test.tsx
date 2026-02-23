import React from 'react';
import { render, screen, fireEvent, act } from '@testing-library/react';
import { expect, describe, it, beforeEach, jest } from '@jest/globals';
import '@testing-library/jest-dom/jest-globals';
import '@testing-library/jest-dom';
import { MemoryRouter } from 'react-router-dom';
import { ChakraProvider } from '@chakra-ui/react';
import { QueryClient, QueryClientProvider } from '@tanstack/react-query';
import ConfigureSyncs from '..';
import { useStore } from '@/stores';
import { SchemaMode } from '../../../types';
import { mockStoreImplementation } from '../../../../../../../__mocks__/commonMocks';

const createQueryClient = () =>
  new QueryClient({
    defaultOptions: {
      queries: {
        retry: false,
      },
    },
  });

const mockForms = [
  {
    stepKey: 'selectModel',
    data: {
      selectModel: {
        id: '1',
        name: 'Test Model',
        connector: { id: '1', name: 'PostgreSQL' },
      },
    },
  },
  {
    stepKey: 'selectDestination',
    data: {
      selectDestination: {
        id: '2',
        attributes: { name: 'Snowflake' },
      },
    },
  },
];

const mockUseSteppedForm = {
  forms: mockForms,
  stepInfo: { formKey: 'configureSyncs' },
  handleMoveForward: jest.fn(),
};

const mockUseCatalogQueries = jest.fn();

jest.mock('@/stores/useSteppedForm', () => ({
  __esModule: true,
  default: () => mockUseSteppedForm,
}));

jest.mock('@/stores', () => ({
  useStore: jest.fn(),
}));

jest.mock('@/hooks/queries/useCatalogQueries', () => ({
  useCatalogQueries: () => mockUseCatalogQueries(),
}));

jest.mock('@/components/ContentContainer', () => ({
  __esModule: true,
  default: ({ children }: { children: React.ReactNode }) => (
    <div data-testid='content-container'>{children}</div>
  ),
}));

jest.mock('@/components/Loader', () => ({
  __esModule: true,
  default: () => <div data-testid='loader'>Loading...</div>,
}));

jest.mock('../SelectStreams', () => ({
  __esModule: true,
  default: ({ onChange }: { onChange: (stream: { name: string }) => void }) => (
    <div data-testid='select-streams'>
      <button onClick={() => onChange({ name: 'stream1' })}>Select Stream</button>
    </div>
  ),
}));

const mockCapturedOnConfigChange: { current: ((config: unknown[]) => void) | null } = {
  current: null,
};

jest.mock('../MapFields', () => ({
  __esModule: true,
  default: ({ handleOnConfigChange }: { handleOnConfigChange: (config: unknown[]) => void }) => {
    mockCapturedOnConfigChange.current = handleOnConfigChange;
    return (
      <div data-testid='map-fields'>
        <button onClick={() => handleOnConfigChange([])}>Update Config</button>
      </div>
    );
  },
}));

// Mock MapCustomFields to avoid infinite re-render from setSchemaMode
jest.mock('../MapCustomFields', () => ({
  __esModule: true,
  default: jest.fn(() => <div data-testid='map-custom-fields'>MapCustomFields</div>),
}));

jest.mock('@/components/FormFooter', () => ({
  __esModule: true,
  default: ({ ctaName, isCtaDisabled }: { ctaName: string; isCtaDisabled?: boolean }) => (
    <button data-testid='form-footer' data-disabled={isCtaDisabled}>
      {ctaName}
    </button>
  ),
}));

const mockedUseStore = useStore as jest.MockedFunction<typeof useStore>;

const renderComponent = () => {
  const queryClient = createQueryClient();
  return render(
    <QueryClientProvider client={queryClient}>
      <ChakraProvider>
        <MemoryRouter>
          <ConfigureSyncs />
        </MemoryRouter>
      </ChakraProvider>
    </QueryClientProvider>,
  );
};

describe('ConfigureSyncs', () => {
  beforeEach(() => {
    jest.clearAllMocks();
    mockStoreImplementation(mockedUseStore, { workspaceId: 1 });
    mockUseCatalogQueries.mockReturnValue({
      catalogData: {
        data: {
          attributes: {
            catalog: {
              schema_mode: SchemaMode.schema,
              streams: [{ name: 'stream1' }],
            },
          },
        },
      },
      handleRefreshCatalog: jest.fn(),
      isRefreshingCatalog: false,
    });
  });

  it('renders loader when catalog data is not available', () => {
    mockUseCatalogQueries.mockReturnValue({
      catalogData: {
        data: {
          attributes: {
            catalog: {
              schema_mode: null,
            },
          },
        },
      },
      handleRefreshCatalog: jest.fn(),
      isRefreshingCatalog: false,
    });
    renderComponent();
    expect(screen.getByTestId('loader')).toBeInTheDocument();
  });

  it('renders SelectStreams component', () => {
    renderComponent();
    expect(screen.getByTestId('select-streams')).toBeInTheDocument();
  });

  it('renders MapFields when stream is selected', () => {
    renderComponent();
    const selectButton = screen.getByText('Select Stream');
    fireEvent.click(selectButton);
    expect(screen.getByTestId('map-fields')).toBeInTheDocument();
  });

  it('calls handleMoveForward on form submit', () => {
    renderComponent();
    const selectButton = screen.getByText('Select Stream');
    fireEvent.click(selectButton);
    const updateButton = screen.getByText('Update Config');
    fireEvent.click(updateButton);
    const formFooter = screen.getByTestId('form-footer');
    fireEvent.click(formFooter);
    expect(mockUseSteppedForm.handleMoveForward).toHaveBeenCalled();
  });

  it('renders form footer', () => {
    renderComponent();
    expect(screen.getByTestId('form-footer')).toBeInTheDocument();
  });

  it('renders MapCustomFields for schemaless mode', () => {
    mockUseCatalogQueries.mockReturnValue({
      catalogData: {
        data: {
          attributes: {
            catalog: {
              schema_mode: SchemaMode.schemaless,
              streams: [{ name: 'stream1' }],
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

  it('calls handleMoveForward with correct payload on form submit', () => {
    renderComponent();
    fireEvent.click(screen.getByText('Select Stream'));
    fireEvent.click(screen.getByText('Update Config'));
    fireEvent.click(screen.getByTestId('form-footer'));
    expect(mockUseSteppedForm.handleMoveForward).toHaveBeenCalledWith(
      'configureSyncs',
      expect.objectContaining({
        stream_name: 'stream1',
      }),
    );
  });

  it('disables submit when vector field has incomplete embedding config', () => {
    renderComponent();
    fireEvent.click(screen.getByText('Select Stream'));
    act(() => {
      mockCapturedOnConfigChange.current!([
        {
          from: 'source_field',
          to: 'dest_field',
          mapping_type: 'standard',
          field_type: 'vector',
          hide_embedding: false,
          embedding_config: {},
        },
      ]);
    });
    expect(screen.getByTestId('form-footer')).toHaveAttribute('data-disabled', 'true');
  });

  it('does not disable submit when vector field has hide_embedding true', () => {
    renderComponent();
    fireEvent.click(screen.getByText('Select Stream'));
    act(() => {
      mockCapturedOnConfigChange.current!([
        {
          from: 'source_field',
          to: 'dest_field',
          mapping_type: 'standard',
          field_type: 'vector',
          hide_embedding: true,
          embedding_config: {},
        },
      ]);
    });
    expect(screen.getByTestId('form-footer')).toHaveAttribute('data-disabled', 'false');
  });

  it('does not disable submit when vector field has complete embedding config', () => {
    renderComponent();
    fireEvent.click(screen.getByText('Select Stream'));
    act(() => {
      mockCapturedOnConfigChange.current!([
        {
          from: 'source_field',
          to: 'dest_field',
          mapping_type: 'standard',
          field_type: 'vector',
          hide_embedding: false,
          embedding_config: { api_key: 'key123', mode: 'openai', model: 'text-embedding-3-small' },
        },
      ]);
    });
    expect(screen.getByTestId('form-footer')).toHaveAttribute('data-disabled', 'false');
  });

  it('does not disable submit when configuration has no vector fields', () => {
    renderComponent();
    fireEvent.click(screen.getByText('Select Stream'));
    act(() => {
      mockCapturedOnConfigChange.current!([
        {
          from: 'source_field',
          to: 'dest_field',
          mapping_type: 'standard',
          field_type: 'string',
        },
      ]);
    });
    expect(screen.getByTestId('form-footer')).toHaveAttribute('data-disabled', 'false');
  });
});
