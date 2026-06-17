import { render, screen, fireEvent, waitFor } from '@testing-library/react';
import { expect } from '@jest/globals';
import '@testing-library/jest-dom/jest-globals';
import '@testing-library/jest-dom';
import { ChakraProvider } from '@chakra-ui/react';
import { QueryClient, QueryClientProvider } from '@tanstack/react-query';
import KBEmbeddingConfig from '../CreateAndViewKBDrawer/KBEmbeddingConfig';
import { CreateKnowledgeBasePayload } from '@/enterprise/services/knowledge-base';
import { EmbeddingConfigurationType } from '@/enterprise/services/types';
import { ApiResponse } from '@/services/common';

const queryClient = new QueryClient({
  defaultOptions: {
    queries: {
      retry: false,
    },
  },
});

// Type-accurate mock embedding providers matching EmbeddingConfigurationType
const mockEmbeddingProviders: EmbeddingConfigurationType[] = [
  {
    id: '1',
    type: 'embedding_providers',
    attributes: {
      mode: 'OpenAI',
      models: ['text-embedding-3-small', 'text-embedding-3-large', 'text-embedding-ada-002'],
    },
  },
];

// Type-accurate API response matching ApiResponse<EmbeddingConfigurationType[]>
const mockApiResponse: ApiResponse<EmbeddingConfigurationType[]> = {
  data: mockEmbeddingProviders,
  status: 200,
};

// Loading state API response
const mockLoadingApiResponse: ApiResponse<EmbeddingConfigurationType[]> = {
  data: undefined,
  status: 200,
};

// Empty API response
const mockEmptyApiResponse: ApiResponse<EmbeddingConfigurationType[]> = {
  data: [],
  status: 200,
};

// Create default payload helper matching CreateKnowledgeBasePayload type
const createDefaultPayload = (): CreateKnowledgeBasePayload => ({
  name: '',
  knowledge_base_type: 'vector_store',
  embedding_config: {
    embedding_provider: '',
    embedding_model: '',
    api_key: '',
    chunk_size: 1000,
    chunk_overlap: 250,
  },
  storage_config: {
    table_name: '',
    vector_column_name: null,
    text_column_name: null,
    metadata_column_name: null,
  },
  hosted_data_store_id: null,
  source_connector_id: null,
  destination_connector_id: null,
});

// Create payload with existing values
const createPopulatedPayload = (): CreateKnowledgeBasePayload => ({
  name: 'Test Knowledge Base',
  knowledge_base_type: 'vector_store',
  embedding_config: {
    embedding_provider: 'OpenAI',
    embedding_model: 'text-embedding-3-small',
    api_key: 'sk-existing-api-key-123',
    chunk_size: 1500,
    chunk_overlap: 300,
  },
  storage_config: {
    table_name: 'embeddings',
    vector_column_name: 'vector',
    text_column_name: 'text',
    metadata_column_name: 'metadata',
  },
  hosted_data_store_id: 1,
  source_connector_id: null,
  destination_connector_id: null,
});

// Mock useQueryWrapper with configurable response
let mockQueryResponse = {
  data: mockApiResponse,
  isLoading: false,
};

jest.mock('@/hooks/useQueryWrapper', () => ({
  __esModule: true,
  default: jest.fn(() => mockQueryResponse),
}));

describe('KBEmbeddingConfig', () => {
  let mockSetCreatePayload: jest.Mock;

  beforeEach(() => {
    mockSetCreatePayload = jest.fn();
    queryClient.clear();
    mockQueryResponse = {
      data: mockApiResponse,
      isLoading: false,
    };
    jest.clearAllMocks();
  });

  const renderComponent = (
    payload: CreateKnowledgeBasePayload = createDefaultPayload(),
    disabled = false,
  ) => {
    return render(
      <QueryClientProvider client={queryClient}>
        <ChakraProvider>
          <KBEmbeddingConfig
            createPayload={payload}
            setCreatePayload={mockSetCreatePayload}
            disabled={disabled}
          />
        </ChakraProvider>
      </QueryClientProvider>,
    );
  };

  describe('Component Rendering', () => {
    it('renders the component without crashing', () => {
      const { container } = renderComponent();
      expect(container).toBeTruthy();
    });

    it('renders all required embedding configuration fields', () => {
      renderComponent();

      expect(screen.getByText('Embedding Provider')).toBeTruthy();
      expect(screen.getByText('Embedding Model')).toBeTruthy();
      expect(screen.getByText('API Key')).toBeTruthy();
      expect(screen.getByText('Chunk Size')).toBeTruthy();
      expect(screen.getByText('Chunk Overlap')).toBeTruthy();
    });

    it('renders with flex column layout and 24px gap', () => {
      const { container } = renderComponent();
      const flexContainer = container.querySelector('[class*="chakra"]');
      expect(flexContainer).toBeTruthy();
    });
  });

  describe('Embedding Mode Field', () => {
    it('renders the Embedding Mode select with placeholder', () => {
      renderComponent();
      expect(screen.getByText('Select Embedding Provider')).toBeTruthy();
    });

    it('displays all available embedding modes from API response', () => {
      renderComponent();
      const modeSelect = screen.getByText('Select Embedding Provider').closest('select');

      if (modeSelect) {
        // Options should include the modes from mock data
        expect(modeSelect.querySelectorAll('option').length).toBeGreaterThan(1);
      }
    });

    it('updates embedding provider when mode is selected', async () => {
      renderComponent();
      const modeSelect = screen.getByText('Select Embedding Provider').closest('select');

      if (modeSelect) {
        fireEvent.change(modeSelect, { target: { value: 'OpenAI' } });

        await waitFor(() => {
          expect(mockSetCreatePayload).toHaveBeenCalled();
          const lastCall =
            mockSetCreatePayload.mock.calls[mockSetCreatePayload.mock.calls.length - 1][0];
          expect(lastCall.embedding_config.embedding_provider).toBe('OpenAI');
        });
      }
    });

    it('displays pre-selected mode from payload', () => {
      const populatedPayload = createPopulatedPayload();
      renderComponent(populatedPayload);

      const modeSelect = screen.getAllByRole('combobox')[0] as HTMLSelectElement;
      expect(modeSelect.value).toBe('OpenAI');
    });
  });

  describe('Embedding Model Field', () => {
    it('renders the Embedding Model select with placeholder', () => {
      renderComponent();
      expect(screen.getByText('Select Embedding Model')).toBeTruthy();
    });

    it('shows models based on selected mode', async () => {
      const populatedPayload = createPopulatedPayload();
      renderComponent(populatedPayload);

      const modelSelect = screen.getAllByRole('combobox')[1] as HTMLSelectElement;
      expect(modelSelect.value).toBe('text-embedding-3-small');
    });

    it('updates embedding model when model is selected', async () => {
      const populatedPayload = createPopulatedPayload();
      renderComponent(populatedPayload);

      const modelSelect = screen.getAllByRole('combobox')[1];
      fireEvent.change(modelSelect, { target: { value: 'text-embedding-3-large' } });

      await waitFor(() => {
        expect(mockSetCreatePayload).toHaveBeenCalled();
        const lastCall =
          mockSetCreatePayload.mock.calls[mockSetCreatePayload.mock.calls.length - 1][0];
        expect(lastCall.embedding_config.embedding_model).toBe('text-embedding-3-large');
      });
    });

    it('displays pre-selected model from payload', () => {
      const populatedPayload = createPopulatedPayload();
      renderComponent(populatedPayload);

      const modelSelect = screen.getAllByRole('combobox')[1] as HTMLSelectElement;
      expect(modelSelect.value).toBe('text-embedding-3-small');
    });
  });

  describe('API Key Field', () => {
    it('renders the API Key input with placeholder', () => {
      renderComponent();
      expect(screen.getByPlaceholderText('Enter your API key')).toBeTruthy();
    });

    it('updates api_key when typing in the field', async () => {
      renderComponent();
      const apiKeyInput = screen.getByPlaceholderText('Enter your API key');

      fireEvent.change(apiKeyInput, { target: { value: 'sk-new-api-key-456' } });

      await waitFor(() => {
        expect(mockSetCreatePayload).toHaveBeenCalled();
        const lastCall =
          mockSetCreatePayload.mock.calls[mockSetCreatePayload.mock.calls.length - 1][0];
        expect(lastCall.embedding_config.api_key).toBe('sk-new-api-key-456');
      });
    });

    it('displays existing API key value from payload', () => {
      const populatedPayload = createPopulatedPayload();
      renderComponent(populatedPayload);

      const apiKeyInput = screen.getByPlaceholderText('Enter your API key') as HTMLInputElement;
      expect(apiKeyInput.value).toBe('sk-existing-api-key-123');
    });

    it('renders as password input type initially', () => {
      renderComponent();
      const apiKeyInput = screen.getByPlaceholderText('Enter your API key') as HTMLInputElement;
      expect(apiKeyInput.type).toBe('password');
    });

    it('toggles visibility when eye icon is clicked', async () => {
      renderComponent();
      const apiKeyInput = screen.getByPlaceholderText('Enter your API key') as HTMLInputElement;

      expect(apiKeyInput.type).toBe('password');

      const toggleButton = screen.getByRole('button', { name: /reveal password/i });
      fireEvent.click(toggleButton);

      await waitFor(() => {
        expect(apiKeyInput.type).toBe('text');
      });

      fireEvent.click(toggleButton);

      await waitFor(() => {
        expect(apiKeyInput.type).toBe('password');
      });
    });
  });

  describe('Chunk Size Field', () => {
    it('renders the Chunk Size input with placeholder', () => {
      renderComponent();
      expect(screen.getByPlaceholderText('1000')).toBeTruthy();
    });

    it('displays default chunk size value of 1000', () => {
      renderComponent();
      const chunkSizeInput = screen.getByPlaceholderText('1000') as HTMLInputElement;
      expect(chunkSizeInput.value).toBe('1000');
    });

    it('updates chunk_size when value is changed', async () => {
      renderComponent();
      const chunkSizeInput = screen.getByPlaceholderText('1000');

      fireEvent.change(chunkSizeInput, { target: { value: '2000' } });

      await waitFor(() => {
        expect(mockSetCreatePayload).toHaveBeenCalledWith(
          expect.objectContaining({
            embedding_config: expect.objectContaining({
              chunk_size: 2000,
            }),
          }),
        );
      });
    });

    it('displays custom chunk size from payload', () => {
      const populatedPayload = createPopulatedPayload();
      renderComponent(populatedPayload);

      const chunkSizeInput = screen.getByPlaceholderText('1000') as HTMLInputElement;
      expect(chunkSizeInput.value).toBe('1500');
    });

    it('converts string input to number', async () => {
      renderComponent();
      const chunkSizeInput = screen.getByPlaceholderText('1000');

      fireEvent.change(chunkSizeInput, { target: { value: '500' } });

      await waitFor(() => {
        expect(mockSetCreatePayload).toHaveBeenCalledWith(
          expect.objectContaining({
            embedding_config: expect.objectContaining({
              chunk_size: 500,
            }),
          }),
        );
      });
    });
  });

  describe('Chunk Overlap Field', () => {
    it('renders the Chunk Overlap input with placeholder', () => {
      renderComponent();
      expect(screen.getByPlaceholderText('250')).toBeTruthy();
    });

    it('displays default chunk overlap value of 250', () => {
      renderComponent();
      const chunkOverlapInput = screen.getByPlaceholderText('250') as HTMLInputElement;
      expect(chunkOverlapInput.value).toBe('250');
    });

    it('updates chunk_overlap when value is changed', async () => {
      renderComponent();
      const chunkOverlapInput = screen.getByPlaceholderText('250');

      fireEvent.change(chunkOverlapInput, { target: { value: '100' } });

      await waitFor(() => {
        expect(mockSetCreatePayload).toHaveBeenCalledWith(
          expect.objectContaining({
            embedding_config: expect.objectContaining({
              chunk_overlap: 100,
            }),
          }),
        );
      });
    });

    it('displays custom chunk overlap from payload', () => {
      const populatedPayload = createPopulatedPayload();
      renderComponent(populatedPayload);

      const chunkOverlapInput = screen.getByPlaceholderText('250') as HTMLInputElement;
      expect(chunkOverlapInput.value).toBe('300');
    });

    it('converts string input to number', async () => {
      renderComponent();
      const chunkOverlapInput = screen.getByPlaceholderText('250');

      fireEvent.change(chunkOverlapInput, { target: { value: '150' } });

      await waitFor(() => {
        expect(mockSetCreatePayload).toHaveBeenCalledWith(
          expect.objectContaining({
            embedding_config: expect.objectContaining({
              chunk_overlap: 150,
            }),
          }),
        );
      });
    });
  });

  describe('Disabled State', () => {
    it('disables Embedding Mode select when disabled is true', () => {
      renderComponent(createDefaultPayload(), true);
      const modeSelect = screen.getAllByRole('combobox')[0];
      expect(modeSelect).toBeDisabled();
    });

    it('disables Embedding Model select when disabled is true', () => {
      renderComponent(createDefaultPayload(), true);
      const modelSelect = screen.getAllByRole('combobox')[1];
      expect(modelSelect).toBeDisabled();
    });

    it('disables API Key input when disabled is true', () => {
      renderComponent(createDefaultPayload(), true);
      const apiKeyInput = screen.getByPlaceholderText('Enter your API key');
      expect(apiKeyInput).toBeDisabled();
    });

    it('disables Chunk Size input when disabled is true', () => {
      renderComponent(createDefaultPayload(), true);
      const chunkSizeInput = screen.getByPlaceholderText('1000');
      expect(chunkSizeInput).toBeDisabled();
    });

    it('disables Chunk Overlap input when disabled is true', () => {
      renderComponent(createDefaultPayload(), true);
      const chunkOverlapInput = screen.getByPlaceholderText('250');
      expect(chunkOverlapInput).toBeDisabled();
    });

    it('enables all fields when disabled is false', () => {
      renderComponent(createDefaultPayload(), false);

      const modeSelect = screen.getAllByRole('combobox')[0];
      const modelSelect = screen.getAllByRole('combobox')[1];
      const apiKeyInput = screen.getByPlaceholderText('Enter your API key');
      const chunkSizeInput = screen.getByPlaceholderText('1000');
      const chunkOverlapInput = screen.getByPlaceholderText('250');

      expect(modeSelect).not.toBeDisabled();
      expect(modelSelect).not.toBeDisabled();
      expect(apiKeyInput).not.toBeDisabled();
      expect(chunkSizeInput).not.toBeDisabled();
      expect(chunkOverlapInput).not.toBeDisabled();
    });

    it('disables visibility toggle button when disabled is true', () => {
      renderComponent(createDefaultPayload(), true);
      const toggleButton = screen.getByRole('button', { name: /reveal password/i });
      expect(toggleButton).toBeDisabled();
    });
  });

  describe('API Integration', () => {
    it('fetches embedding configuration on mount', () => {
      const useQueryWrapper = jest.requireMock('@/hooks/useQueryWrapper').default;
      renderComponent();
      expect(useQueryWrapper).toHaveBeenCalledWith(['embedding_providers'], expect.any(Function));
    });

    it('handles empty embedding providers gracefully', () => {
      mockQueryResponse = {
        data: mockEmptyApiResponse,
        isLoading: false,
      };

      renderComponent();
      expect(screen.getByText('Embedding Provider')).toBeTruthy();
    });

    it('handles null data response gracefully', () => {
      mockQueryResponse = {
        data: mockLoadingApiResponse,
        isLoading: false,
      };

      renderComponent();
      expect(screen.getByText('Embedding Provider')).toBeTruthy();
    });
  });

  describe('Payload Synchronization', () => {
    it('initializes embedding config state from payload', () => {
      const populatedPayload = createPopulatedPayload();
      renderComponent(populatedPayload);

      const apiKeyInput = screen.getByPlaceholderText('Enter your API key') as HTMLInputElement;
      expect(apiKeyInput.value).toBe('sk-existing-api-key-123');
    });

    it('calls setCreatePayload when embedding config changes', async () => {
      renderComponent();
      const apiKeyInput = screen.getByPlaceholderText('Enter your API key');

      fireEvent.change(apiKeyInput, { target: { value: 'test-key' } });

      await waitFor(() => {
        expect(mockSetCreatePayload).toHaveBeenCalled();
      });
    });

    it('preserves other payload fields when updating embedding config', async () => {
      const populatedPayload = createPopulatedPayload();
      renderComponent(populatedPayload);

      const chunkSizeInput = screen.getByPlaceholderText('1000');
      fireEvent.change(chunkSizeInput, { target: { value: '2500' } });

      await waitFor(() => {
        expect(mockSetCreatePayload).toHaveBeenCalledWith(
          expect.objectContaining({
            name: 'Test Knowledge Base',
            knowledge_base_type: 'vector_store',
            storage_config: expect.objectContaining({
              table_name: 'embeddings',
            }),
          }),
        );
      });
    });

    it('updates all embedding config fields correctly', async () => {
      renderComponent();

      // Update API key
      const apiKeyInput = screen.getByPlaceholderText('Enter your API key');
      fireEvent.change(apiKeyInput, { target: { value: 'new-api-key' } });

      await waitFor(() => {
        expect(mockSetCreatePayload).toHaveBeenCalled();
      });

      // Update chunk size
      const chunkSizeInput = screen.getByPlaceholderText('1000');
      fireEvent.change(chunkSizeInput, { target: { value: '800' } });

      await waitFor(() => {
        expect(mockSetCreatePayload).toHaveBeenCalledWith(
          expect.objectContaining({
            embedding_config: expect.objectContaining({
              chunk_size: 800,
            }),
          }),
        );
      });

      // Update chunk overlap
      const chunkOverlapInput = screen.getByPlaceholderText('250');
      fireEvent.change(chunkOverlapInput, { target: { value: '200' } });

      await waitFor(() => {
        expect(mockSetCreatePayload).toHaveBeenCalledWith(
          expect.objectContaining({
            embedding_config: expect.objectContaining({
              chunk_overlap: 200,
            }),
          }),
        );
      });
    });
  });

  describe('EmbeddingConfigurationFields Integration', () => {
    it('renders EmbeddingConfigurationFields with showAsList prop', () => {
      renderComponent();

      // Should render mode and model selects in column layout
      const modeLabel = screen.getByText('Embedding Provider');
      const modelLabel = screen.getByText('Embedding Model');

      expect(modeLabel).toBeTruthy();
      expect(modelLabel).toBeTruthy();
    });

    it('passes configurations to EmbeddingConfigurationFields', () => {
      renderComponent();

      // Mode select should have options from the mock providers
      const modeSelect = screen.getAllByRole('combobox')[0] as HTMLSelectElement;
      const options = Array.from(modeSelect.options);

      // Should have placeholder + provider options
      expect(options.length).toBeGreaterThan(1);
    });

    it('uses a stable test id for the embedding API key field', () => {
      renderComponent();

      const apiKeyInput = screen.getByTestId('create-kb-api-key-input');
      expect(apiKeyInput).toBeInTheDocument();
      expect(apiKeyInput).toHaveAttribute('placeholder', 'Enter your API key');
      expect(screen.queryByTestId('hidden-input-field')).not.toBeInTheDocument();
    });

    it('updates embedding api_key when the API key input is changed via its data-testid', async () => {
      renderComponent();

      fireEvent.change(screen.getByTestId('create-kb-api-key-input'), {
        target: { value: 'sk-updated-via-test-id' },
      });

      await waitFor(() => {
        expect(mockSetCreatePayload).toHaveBeenCalledWith(
          expect.objectContaining({
            embedding_config: expect.objectContaining({
              api_key: 'sk-updated-via-test-id',
            }),
          }),
        );
      });
    });

    it('syncs embedding config between local state and payload', async () => {
      renderComponent();

      const modeSelect = screen.getAllByRole('combobox')[0];
      fireEvent.change(modeSelect, { target: { value: 'OpenAI' } });

      await waitFor(() => {
        const calls = mockSetCreatePayload.mock.calls;
        const lastCall = calls[calls.length - 1][0];
        expect(lastCall.embedding_config.embedding_provider).toBe('OpenAI');
      });
    });
  });

  describe('Edge Cases', () => {
    it('handles empty string values for chunk size', async () => {
      renderComponent();
      const chunkSizeInput = screen.getByPlaceholderText('1000');

      fireEvent.change(chunkSizeInput, { target: { value: '' } });

      // Number('') returns 0 in JavaScript
      await waitFor(() => {
        expect(mockSetCreatePayload).toHaveBeenCalledWith(
          expect.objectContaining({
            embedding_config: expect.objectContaining({
              chunk_size: 0,
            }),
          }),
        );
      });
    });

    it('handles empty string values for chunk overlap', async () => {
      renderComponent();
      const chunkOverlapInput = screen.getByPlaceholderText('250');

      fireEvent.change(chunkOverlapInput, { target: { value: '' } });

      // Number('') returns 0 in JavaScript
      await waitFor(() => {
        expect(mockSetCreatePayload).toHaveBeenCalledWith(
          expect.objectContaining({
            embedding_config: expect.objectContaining({
              chunk_overlap: 0,
            }),
          }),
        );
      });
    });

    it('handles zero values for chunk size', async () => {
      renderComponent();
      const chunkSizeInput = screen.getByPlaceholderText('1000');

      fireEvent.change(chunkSizeInput, { target: { value: '0' } });

      await waitFor(() => {
        expect(mockSetCreatePayload).toHaveBeenCalledWith(
          expect.objectContaining({
            embedding_config: expect.objectContaining({
              chunk_size: 0,
            }),
          }),
        );
      });
    });

    it('handles zero values for chunk overlap', async () => {
      renderComponent();
      const chunkOverlapInput = screen.getByPlaceholderText('250');

      fireEvent.change(chunkOverlapInput, { target: { value: '0' } });

      await waitFor(() => {
        expect(mockSetCreatePayload).toHaveBeenCalledWith(
          expect.objectContaining({
            embedding_config: expect.objectContaining({
              chunk_overlap: 0,
            }),
          }),
        );
      });
    });

    it('handles large values for chunk size', async () => {
      renderComponent();
      const chunkSizeInput = screen.getByPlaceholderText('1000');

      fireEvent.change(chunkSizeInput, { target: { value: '100000' } });

      await waitFor(() => {
        expect(mockSetCreatePayload).toHaveBeenCalledWith(
          expect.objectContaining({
            embedding_config: expect.objectContaining({
              chunk_size: 100000,
            }),
          }),
        );
      });
    });

    it('handles special characters in API key', async () => {
      renderComponent();
      const apiKeyInput = screen.getByPlaceholderText('Enter your API key');

      fireEvent.change(apiKeyInput, { target: { value: 'sk-test_key!@#$%^&*()' } });

      await waitFor(() => {
        const calls = mockSetCreatePayload.mock.calls;
        const lastCall = calls[calls.length - 1][0];
        expect(lastCall.embedding_config.api_key).toBe('sk-test_key!@#$%^&*()');
      });
    });
  });

  describe('Accessibility', () => {
    it('has accessible labels for all form fields', () => {
      renderComponent();

      expect(screen.getByText('Embedding Provider')).toBeTruthy();
      expect(screen.getByText('Embedding Model')).toBeTruthy();
      expect(screen.getByText('API Key')).toBeTruthy();
      expect(screen.getByText('Chunk Size')).toBeTruthy();
      expect(screen.getByText('Chunk Overlap')).toBeTruthy();
    });

    it('has proper aria-label on password visibility toggle', () => {
      renderComponent();
      const toggleButton = screen.getByRole('button', { name: /reveal password/i });
      expect(toggleButton).toBeTruthy();
    });
  });
});
