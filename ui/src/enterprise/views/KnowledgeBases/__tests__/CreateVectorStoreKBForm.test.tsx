import { render, screen, fireEvent, waitFor } from '@testing-library/react';
import { expect } from '@jest/globals';
import '@testing-library/jest-dom/jest-globals';
import '@testing-library/jest-dom';
import { ChakraProvider } from '@chakra-ui/react';
import { QueryClient, QueryClientProvider } from '@tanstack/react-query';
import CreateVectorStoreKBForm from '../CreateAndViewKBDrawer/CreateVectorStoreKBForm';
import { CreateKnowledgeBasePayload } from '@/enterprise/services/knowledge-base';
import { EmbeddingConfigurationType } from '@/enterprise/services/types';

const queryClient = new QueryClient({
  defaultOptions: {
    queries: {
      retry: false,
    },
  },
});

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

const mockConnectors = [
  {
    id: '1',
    attributes: {
      name: 'Vector Store 1',
      in_host: true,
    },
  },
  {
    id: '2',
    attributes: {
      name: 'Vector Store 2',
      in_host: false,
    },
  },
];

const mockCatalog = {
  attributes: {
    catalog: {
      streams: [
        {
          name: 'embeddings_table',
          json_schema: {
            properties: {
              id: { type: 'integer' },
              text_content: { type: 'string' },
              embedding_vector: { type: 'array' },
              metadata: { type: 'object' },
            },
          },
        },
        {
          name: 'documents_table',
          json_schema: {
            properties: {
              doc_id: { type: 'integer' },
              content: { type: 'string' },
              vector: { type: 'array' },
            },
          },
        },
      ],
    },
  },
};

jest.mock('@/hooks/useQueryWrapper', () => ({
  __esModule: true,
  default: jest.fn((queryKey) => {
    if (queryKey[0] === 'embedding_providers') {
      return {
        data: {
          data: mockEmbeddingProviders,
        },
        isLoading: false,
      };
    }
    if (queryKey[0] === 'connectors') {
      return {
        data: {
          data: mockConnectors,
        },
        isLoading: false,
      };
    }
    if (queryKey[0] === 'catalog') {
      return {
        data: {
          data: mockCatalog,
        },
        isLoading: false,
      };
    }
    return {
      data: { data: [] },
      isLoading: false,
    };
  }),
}));

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

describe('CreateVectorStoreKBForm', () => {
  let mockSetCreatePayload: jest.Mock;
  let defaultPayload: CreateKnowledgeBasePayload;

  beforeEach(() => {
    mockSetCreatePayload = jest.fn();
    defaultPayload = createDefaultPayload();
    queryClient.clear();
  });

  const renderComponent = (
    payload: CreateKnowledgeBasePayload = defaultPayload,
    readonly = false,
  ) => {
    return render(
      <QueryClientProvider client={queryClient}>
        <ChakraProvider>
          <CreateVectorStoreKBForm
            createPayload={payload}
            setCreatePayload={mockSetCreatePayload}
            readonly={readonly}
          />
        </ChakraProvider>
      </QueryClientProvider>,
    );
  };

  describe('Name Field', () => {
    it('exposes a stable test id on the knowledge base name input', () => {
      renderComponent();

      expect(screen.getByTestId('create-kb-name-input')).toBeInTheDocument();
    });

    it('renders the name input field', () => {
      renderComponent();
      expect(screen.getByText('Name')).toBeTruthy();
      expect(screen.getByPlaceholderText('Enter name')).toBeTruthy();
    });

    it('renders the required indicator for name field', () => {
      renderComponent();
      // Check that required indicator exists near the Name label
      const nameLabel = screen.getByText('Name');
      expect(nameLabel).toBeTruthy();
      // There should be at least one required indicator (*) on the page
      const requiredIndicators = screen.getAllByText('*');
      expect(requiredIndicators.length).toBeGreaterThan(0);
    });

    it('allows typing in the name input field', () => {
      renderComponent();
      const nameInput = screen.getByPlaceholderText('Enter name');
      fireEvent.change(nameInput, { target: { value: 'My Knowledge Base' } });

      expect(mockSetCreatePayload).toHaveBeenCalledWith(
        expect.objectContaining({
          name: 'My Knowledge Base',
        }),
      );
    });

    it('displays existing name value from payload', () => {
      const payloadWithName = {
        ...defaultPayload,
        name: 'Existing KB Name',
      };
      renderComponent(payloadWithName);
      const nameInput = screen.getByPlaceholderText('Enter name') as HTMLInputElement;
      expect(nameInput.value).toBe('Existing KB Name');
    });

    it('makes name input readonly when readonly prop is true', () => {
      renderComponent(defaultPayload, true);
      const nameInput = screen.getByPlaceholderText('Enter name');
      expect(nameInput).toHaveAttribute('readonly');
    });
  });

  describe('KBEmbeddingConfig - Embedding Mode', () => {
    it('renders the Embedding Mode select field', () => {
      renderComponent();
      expect(screen.getByText('Embedding Provider')).toBeTruthy();
    });

    it('renders Embedding Mode placeholder', () => {
      renderComponent();
      expect(screen.getByText('Select Embedding Provider')).toBeTruthy();
    });

    it('updates embedding provider when mode is selected', async () => {
      renderComponent();
      const modeSelect = screen.getByText('Select Embedding Provider').closest('select');

      if (modeSelect) {
        fireEvent.change(modeSelect, { target: { value: 'OpenAI' } });

        await waitFor(() => {
          expect(mockSetCreatePayload).toHaveBeenCalled();
        });
      }
    });
  });

  describe('KBEmbeddingConfig - Embedding Model', () => {
    it('renders the Embedding Model select field', () => {
      renderComponent();
      expect(screen.getByText('Embedding Model')).toBeTruthy();
    });

    it('renders Embedding Model placeholder', () => {
      renderComponent();
      expect(screen.getByText('Select Embedding Model')).toBeTruthy();
    });

    it('displays selected embedding model from payload', () => {
      const payloadWithModel = {
        ...defaultPayload,
        embedding_config: {
          ...defaultPayload.embedding_config,
          embedding_provider: 'OpenAI',
          embedding_model: 'text-embedding-3-small',
        },
      };
      renderComponent(payloadWithModel);
      const modelSelect = screen.getAllByRole('combobox')[1] as HTMLSelectElement;
      expect(modelSelect.value).toBe('text-embedding-3-small');
    });
  });

  describe('KBEmbeddingConfig - API Key', () => {
    it('renders the API Key input field', () => {
      renderComponent();
      expect(screen.getByText('API Key')).toBeTruthy();
    });

    it('renders API Key placeholder', () => {
      renderComponent();
      expect(screen.getByPlaceholderText('Enter your API key')).toBeTruthy();
    });

    it('updates api_key when typing in the field', async () => {
      renderComponent();
      const apiKeyInput = screen.getByPlaceholderText('Enter your API key');
      fireEvent.change(apiKeyInput, { target: { value: 'sk-test-key-123' } });

      await waitFor(() => {
        expect(mockSetCreatePayload).toHaveBeenCalled();
      });
    });

    it('displays existing API key value from payload', () => {
      const payloadWithApiKey = {
        ...defaultPayload,
        embedding_config: {
          ...defaultPayload.embedding_config,
          api_key: 'existing-api-key',
        },
      };
      renderComponent(payloadWithApiKey);
      const apiKeyInput = screen.getByPlaceholderText('Enter your API key') as HTMLInputElement;
      expect(apiKeyInput.value).toBe('existing-api-key');
    });
  });

  describe('KBEmbeddingConfig - Chunk Size', () => {
    it('renders the Chunk Size input field', () => {
      renderComponent();
      expect(screen.getByText('Chunk Size')).toBeTruthy();
    });

    it('displays default chunk size value', () => {
      renderComponent();
      const chunkSizeInput = screen.getByPlaceholderText('1000') as HTMLInputElement;
      expect(chunkSizeInput.value).toBe('1000');
    });

    it('updates chunk_size when value is changed', async () => {
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

    it('displays custom chunk size from payload', () => {
      const payloadWithChunkSize = {
        ...defaultPayload,
        embedding_config: {
          ...defaultPayload.embedding_config,
          chunk_size: 2000,
        },
      };
      renderComponent(payloadWithChunkSize);
      const chunkSizeInput = screen.getByPlaceholderText('1000') as HTMLInputElement;
      expect(chunkSizeInput.value).toBe('2000');
    });
  });

  describe('KBEmbeddingConfig - Chunk Overlap', () => {
    it('renders the Chunk Overlap input field', () => {
      renderComponent();
      expect(screen.getByText('Chunk Overlap')).toBeTruthy();
    });

    it('displays default chunk overlap value', () => {
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
      const payloadWithChunkOverlap = {
        ...defaultPayload,
        embedding_config: {
          ...defaultPayload.embedding_config,
          chunk_overlap: 500,
        },
      };
      renderComponent(payloadWithChunkOverlap);
      const chunkOverlapInput = screen.getByPlaceholderText('250') as HTMLInputElement;
      expect(chunkOverlapInput.value).toBe('500');
    });
  });

  describe('VectorStoreConfig', () => {
    it('renders Vector Storage section', () => {
      renderComponent();
      expect(screen.getByText('Vector Storage')).toBeTruthy();
    });

    it('renders Table Name field', () => {
      renderComponent();
      expect(screen.getByText('Table/Index/Collection')).toBeTruthy();
    });

    it('renders Text Column Name field', () => {
      renderComponent();
      expect(screen.getByText('Text Column Name')).toBeTruthy();
    });

    it('renders Embedding Column Name field', () => {
      renderComponent();
      expect(screen.getByText('Embedding Column Name')).toBeTruthy();
    });

    it('renders Metadata Column Name field', () => {
      renderComponent();
      expect(screen.getByText('Metadata Column Name')).toBeTruthy();
    });

    it('renders Default and Custom tabs', () => {
      renderComponent();
      expect(screen.getByText('Default')).toBeTruthy();
      expect(screen.getByText('Custom')).toBeTruthy();
    });
  });

  describe('Readonly Mode', () => {
    it('disables all embedding config fields when readonly is true', () => {
      renderComponent(defaultPayload, true);

      const nameInput = screen.getByPlaceholderText('Enter name');
      expect(nameInput).toHaveAttribute('readonly');

      const apiKeyInput = screen.getByPlaceholderText('Enter your API key');
      expect(apiKeyInput).toBeDisabled();

      const chunkSizeInput = screen.getByPlaceholderText('1000');
      expect(chunkSizeInput).toBeDisabled();

      const chunkOverlapInput = screen.getByPlaceholderText('250');
      expect(chunkOverlapInput).toBeDisabled();
    });
  });

  describe('Form Layout', () => {
    it('renders all major sections', () => {
      renderComponent();

      // Name section
      expect(screen.getByText('Name')).toBeTruthy();

      // Embedding config section
      expect(screen.getByText('Embedding Provider')).toBeTruthy();
      expect(screen.getByText('Embedding Model')).toBeTruthy();
      expect(screen.getByText('API Key')).toBeTruthy();
      expect(screen.getByText('Chunk Size')).toBeTruthy();
      expect(screen.getByText('Chunk Overlap')).toBeTruthy();

      // Vector storage section
      expect(screen.getByText('Vector Storage')).toBeTruthy();
      expect(screen.getByText('Table/Index/Collection')).toBeTruthy();
    });

    it('renders divider lines between sections', () => {
      renderComponent();
      const dividers = screen.getAllByTestId('divider');
      expect(dividers.length).toBeGreaterThan(0);
    });
  });

  describe('Integration with payload', () => {
    it('renders form with fully populated payload', () => {
      const fullPayload: CreateKnowledgeBasePayload = {
        name: 'Test Knowledge Base',
        knowledge_base_type: 'vector_store',
        embedding_config: {
          embedding_provider: 'OpenAI',
          embedding_model: 'text-embedding-3-small',
          api_key: 'sk-test-123',
          chunk_size: 1500,
          chunk_overlap: 300,
        },
        storage_config: {
          table_name: 'embeddings_table',
          vector_column_name: 'embedding_vector',
          text_column_name: 'text_content',
          metadata_column_name: 'metadata',
        },
        hosted_data_store_id: 1,
        source_connector_id: null,
        destination_connector_id: null,
      };

      renderComponent(fullPayload);

      const nameInput = screen.getByPlaceholderText('Enter name') as HTMLInputElement;
      expect(nameInput.value).toBe('Test Knowledge Base');

      const apiKeyInput = screen.getByPlaceholderText('Enter your API key') as HTMLInputElement;
      expect(apiKeyInput.value).toBe('sk-test-123');

      const chunkSizeInput = screen.getByPlaceholderText('1000') as HTMLInputElement;
      expect(chunkSizeInput.value).toBe('1500');

      const chunkOverlapInput = screen.getByPlaceholderText('250') as HTMLInputElement;
      expect(chunkOverlapInput.value).toBe('300');
    });
  });
});
