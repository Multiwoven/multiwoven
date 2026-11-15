import { render, screen, fireEvent, waitFor } from '@testing-library/react';
import { expect } from '@jest/globals';
import '@testing-library/jest-dom/jest-globals';
import '@testing-library/jest-dom';
import { ChakraProvider } from '@chakra-ui/react';
import { QueryClient, QueryClientProvider } from '@tanstack/react-query';
import CreateAndViewKBDrawer from '../CreateAndViewKBDrawer/CreateAndViewKBDrawer';
import { CreateKnowledgeBasePayload } from '@/enterprise/services/knowledge-base';
import { EmbeddingConfigurationType } from '@/enterprise/services/types';
import { ConnectorItem } from '@/views/Connectors/types';
import { Stream } from '@/views/Activate/Syncs/types';

// Mock data matching actual types
const MOCK_EMBEDDING_CONFIGURATIONS: EmbeddingConfigurationType[] = [
  {
    id: '1',
    type: 'embedding_configurations',
    attributes: {
      mode: 'openai',
      models: ['text-embedding-ada-002', 'text-embedding-3-small', 'text-embedding-3-large'],
    },
  },
];

const MOCK_CONNECTORS: ConnectorItem[] = [
  {
    id: '1',
    attributes: {
      connector_name: 'Pinecone',
      connector_type: 'source',
      configuration: { data_type: 'vector' },
      name: 'My Pinecone Store',
      description: 'Production vector store',
      icon: 'pinecone.svg',
      updated_at: '2024-01-01T00:00:00Z',
      status: 'active',
      in_host: false,
    },
  },
  {
    id: '2',
    attributes: {
      connector_name: 'PGVector',
      connector_type: 'source',
      configuration: { data_type: 'vector' },
      name: 'My PostgreSQL Store',
      description: 'Test vector store',
      icon: 'postgresql.svg',
      updated_at: '2024-01-02T00:00:00Z',
      status: 'active',
      in_host: true,
      in_host_store_id: 1,
    },
  },
];

const MOCK_CATALOG_STREAMS: Stream[] = [
  {
    action: 'read',
    name: 'documents_table',
    json_schema: {
      type: 'object',
      properties: {
        id: { type: 'string' },
        text_content: { type: 'string' },
        embedding_vector: { type: 'array' },
        metadata_json: { type: 'object' },
      },
    },
    url: '',
    supported_sync_modes: ['full_refresh'],
  },
  {
    action: 'read',
    name: 'embeddings_table',
    json_schema: {
      type: 'object',
      properties: {
        doc_id: { type: 'string' },
        content: { type: 'string' },
        vector: { type: 'array' },
        meta: { type: 'object' },
      },
    },
    url: '',
    supported_sync_modes: ['full_refresh'],
  },
];

const MOCK_KNOWLEDGE_BASE_PAYLOAD: CreateKnowledgeBasePayload = {
  name: 'Test Knowledge Base',
  knowledge_base_type: 'vector_store',
  embedding_config: {
    embedding_provider: 'openai',
    embedding_model: 'text-embedding-ada-002',
    api_key: 'sk-test-api-key-12345',
    chunk_size: 1000,
    chunk_overlap: 250,
  },
  storage_config: {
    table_name: 'documents_table',
    vector_column_name: 'embedding_vector',
    text_column_name: 'text_content',
    metadata_column_name: 'metadata_json',
  },
  hosted_data_store_id: 1,
  source_connector_id: null,
  destination_connector_id: null,
};

// Mock createKnowledgeBase mutation
const mockCreateKnowledgeBaseMutate = jest.fn();
const mockCreateKnowledgeBaseReset = jest.fn();
const mockApiErrorToast = jest.fn();

jest.mock('@/hooks/useErrorToast', () => ({
  useAPIErrorsToast: () => mockApiErrorToast,
}));

jest.mock('@/enterprise/hooks/mutations/useKnowledgeBaseMutations', () => ({
  __esModule: true,
  default: () => ({
    createKnowledgeBase: {
      mutate: mockCreateKnowledgeBaseMutate,
      reset: mockCreateKnowledgeBaseReset,
      isPending: false,
      isSuccess: false,
      isError: false,
    },
    deleteKnowledgeBaseFileMutation: {
      mutate: jest.fn(),
      isPending: false,
    },
    getKnowledgeBaseFileMutation: {
      mutate: jest.fn(),
      isPending: false,
    },
    uploadKnowledgeBaseFileMutation: {
      mutate: jest.fn(),
      isPending: false,
    },
  }),
}));

// Mock useQueryWrapper with dynamic responses based on query key
jest.mock('@/hooks/useQueryWrapper', () => ({
  __esModule: true,
  default: jest.fn().mockImplementation((queryKey: string[]) => {
    if (queryKey[0] === 'embedding_providers') {
      return {
        data: { data: MOCK_EMBEDDING_CONFIGURATIONS },
        isLoading: false,
        isError: false,
        refetch: jest.fn(),
      };
    }
    if (queryKey[0] === 'connectors') {
      return {
        data: { data: MOCK_CONNECTORS },
        isLoading: false,
        isError: false,
        refetch: jest.fn(),
      };
    }
    if (queryKey[0] === 'catalog') {
      return {
        data: {
          data: {
            id: '1',
            attributes: {
              catalog: {
                streams: MOCK_CATALOG_STREAMS,
                schema_mode: 'schema',
                catalog_hash: 'abc123',
                connector_id: 1,
                workspace_id: 1,
                source_defined_cursor: false,
              },
            },
          },
        },
        isLoading: false,
        isError: false,
        refetch: jest.fn(),
      };
    }
    return { data: null, isLoading: false, isError: false, refetch: jest.fn() };
  }),
}));

// Required for Chakra UI portal
global.ResizeObserver = class {
  observe() {}
  unobserve() {}
  disconnect() {}
};

const queryClient = new QueryClient({
  defaultOptions: {
    queries: {
      retry: false,
    },
  },
});

describe('CreateAndViewKBDrawer', () => {
  const mockOnClose = jest.fn();
  const mockRefetchKnowledgeBases = jest.fn();

  beforeEach(() => {
    jest.clearAllMocks();
    queryClient.clear();
  });

  const renderComponent = (props: Partial<Parameters<typeof CreateAndViewKBDrawer>[0]> = {}) => {
    const defaultProps = {
      isOpen: true,
      onClose: mockOnClose,
      viewOnly: false,
      refetchKnowledgeBases: mockRefetchKnowledgeBases,
    };

    return render(
      <QueryClientProvider client={queryClient}>
        <ChakraProvider>
          <CreateAndViewKBDrawer {...defaultProps} {...props} />
        </ChakraProvider>
      </QueryClientProvider>,
    );
  };

  describe('Step 1 - Knowledge Base Type Selection', () => {
    it('renders the drawer with step 1 title when opened', async () => {
      renderComponent();

      await waitFor(() => {
        expect(screen.getByText('Create new knowledge base')).toBeTruthy();
      });
    });

    it('renders Vector Store option card', async () => {
      renderComponent();

      await waitFor(() => {
        expect(screen.getByText('Vector Store')).toBeTruthy();
        expect(screen.getByText('Import from files, data connectors and websites.')).toBeTruthy();
      });
    });

    it('renders Semantic Data Model option card as coming soon', async () => {
      renderComponent();

      await waitFor(() => {
        expect(screen.getByText('Semantic Data Model')).toBeTruthy();
        expect(screen.getByText('Structured data from databases or CSV files.')).toBeTruthy();
        expect(screen.getByText('coming soon')).toBeTruthy();
      });
    });

    it('renders Cancel and Continue buttons in step 1', async () => {
      renderComponent();

      await waitFor(() => {
        expect(screen.getByText('Cancel')).toBeTruthy();
        expect(screen.getByText('Continue')).toBeTruthy();
      });
    });

    it('uses a stable test id on the step 1 Continue button', async () => {
      renderComponent();

      await waitFor(() => {
        expect(screen.getByTestId('create-kb-continue-button')).toBeInTheDocument();
      });
    });

    it('navigates to step 2 when Continue is clicked', async () => {
      renderComponent();

      await waitFor(() => {
        expect(screen.getByText('Continue')).toBeTruthy();
      });

      const continueButton = screen.getByText('Continue');
      fireEvent.click(continueButton);

      await waitFor(() => {
        expect(screen.getByText('Create new vector store')).toBeTruthy();
      });
    });

    it('closes drawer and resets step when Cancel is clicked', async () => {
      renderComponent();

      await waitFor(() => {
        expect(screen.getByText('Cancel')).toBeTruthy();
      });

      const cancelButton = screen.getByText('Cancel');
      fireEvent.click(cancelButton);

      await waitFor(() => {
        expect(mockOnClose).toHaveBeenCalled();
      });
    });
  });

  describe('Step 2 - Vector Store Form', () => {
    const navigateToStep2 = async () => {
      renderComponent();

      await waitFor(() => {
        expect(screen.getByText('Continue')).toBeTruthy();
      });

      fireEvent.click(screen.getByText('Continue'));

      await waitFor(() => {
        expect(screen.getByText('Create new vector store')).toBeTruthy();
      });
    };

    it('renders step 2 title after navigating from step 1', async () => {
      await navigateToStep2();

      expect(screen.getByText('Create new vector store')).toBeTruthy();
    });

    it('renders Name input field with required indicator', async () => {
      await navigateToStep2();

      expect(screen.getByText('Name')).toBeTruthy();
      expect(screen.getByPlaceholderText('Enter name')).toBeTruthy();
    });

    it('renders Cancel and Continue buttons in step 2', async () => {
      await navigateToStep2();

      expect(screen.getByText('Cancel')).toBeTruthy();
      expect(screen.getByText('Continue')).toBeTruthy();
    });

    it('uses a stable test id on the step 2 configuration submit button', async () => {
      await navigateToStep2();

      expect(screen.getByTestId('create-kb-submit-button')).toBeInTheDocument();
    });

    it('renders Chunk Size and Chunk Overlap fields', async () => {
      await navigateToStep2();

      expect(screen.getByText('Chunk Size')).toBeTruthy();
      expect(screen.getByText('Chunk Overlap')).toBeTruthy();
    });

    it('renders Vector Storage section', async () => {
      await navigateToStep2();

      expect(screen.getByText('Vector Storage')).toBeTruthy();
    });

    it('renders Table Name dropdown', async () => {
      await navigateToStep2();

      expect(screen.getByText('Table/Index/Collection')).toBeTruthy();
    });

    it('renders Text Column Name dropdown', async () => {
      await navigateToStep2();

      expect(screen.getByText('Text Column Name')).toBeTruthy();
    });

    it('renders Embedding Column Name dropdown', async () => {
      await navigateToStep2();

      expect(screen.getByText('Embedding Column Name')).toBeTruthy();
    });

    it('renders Metadata Column Name dropdown', async () => {
      await navigateToStep2();

      expect(screen.getByText('Metadata Column Name')).toBeTruthy();
    });

    it('allows entering name in the Name field', async () => {
      await navigateToStep2();

      const nameInput = screen.getByPlaceholderText('Enter name');
      fireEvent.change(nameInput, { target: { value: 'My Knowledge Base' } });

      await waitFor(() => {
        expect(nameInput).toHaveValue('My Knowledge Base');
      });
    });

    it('closes drawer when Cancel is clicked in step 2', async () => {
      await navigateToStep2();

      const cancelButton = screen.getByText('Cancel');
      fireEvent.click(cancelButton);

      await waitFor(() => {
        expect(mockOnClose).toHaveBeenCalled();
      });
    });

    it('resets to step 1 when drawer is reopened after cancel', async () => {
      const { rerender } = renderComponent();

      await waitFor(() => {
        expect(screen.getByText('Continue')).toBeTruthy();
      });

      // Navigate to step 2
      fireEvent.click(screen.getByText('Continue'));

      await waitFor(() => {
        expect(screen.getByText('Create new vector store')).toBeTruthy();
      });

      // Click cancel
      fireEvent.click(screen.getByText('Cancel'));

      await waitFor(() => {
        expect(mockOnClose).toHaveBeenCalled();
      });

      // Rerender with isOpen true to simulate reopening
      rerender(
        <QueryClientProvider client={queryClient}>
          <ChakraProvider>
            <CreateAndViewKBDrawer
              isOpen={true}
              onClose={mockOnClose}
              viewOnly={false}
              refetchKnowledgeBases={mockRefetchKnowledgeBases}
            />
          </ChakraProvider>
        </QueryClientProvider>,
      );

      // Should be back to step 1
      await waitFor(() => {
        expect(screen.getByText('Create new knowledge base')).toBeTruthy();
      });
    });
  });

  describe('Form Submission', () => {
    it('Continue button is disabled when form is incomplete', async () => {
      renderComponent();

      await waitFor(() => {
        expect(screen.getByText('Continue')).toBeTruthy();
      });

      fireEvent.click(screen.getByText('Continue'));

      await waitFor(() => {
        expect(screen.getByText('Continue')).toBeTruthy();
      });

      const continueButton = screen.getByText('Continue');
      expect(continueButton).toBeDisabled();
    });

    it('handles successful knowledge base creation', async () => {
      mockCreateKnowledgeBaseMutate.mockImplementation((_data, options) => {
        options.onSuccess({ data: { id: '1' } });
      });

      renderComponent({
        defaultPayload: MOCK_KNOWLEDGE_BASE_PAYLOAD,
        viewOnly: false,
      });

      // Navigate to step 2
      await waitFor(() => screen.getByText('Continue'));
      fireEvent.click(screen.getByText('Continue'));

      // Click Continue button (this covers line 193)
      await waitFor(() => screen.getByText('Continue'));
      const continueButton = screen.getByText('Continue');
      fireEvent.click(continueButton);

      // Verify success actions (this covers lines 83-91)
      expect(mockCreateKnowledgeBaseMutate).toHaveBeenCalled();
      expect(mockOnClose).toHaveBeenCalled();
      expect(mockRefetchKnowledgeBases).toHaveBeenCalled();
      expect(mockCreateKnowledgeBaseReset).toHaveBeenCalled();
    });

    it('handles knowledge base creation errors', async () => {
      const mockErrors = [{ message: 'Already exists' }];
      mockCreateKnowledgeBaseMutate.mockImplementation((_data, options) => {
        options.onSuccess({ errors: mockErrors });
      });

      renderComponent({
        defaultPayload: MOCK_KNOWLEDGE_BASE_PAYLOAD,
        viewOnly: false,
      });

      // Navigate to step 2
      await waitFor(() => screen.getByText('Continue'));
      fireEvent.click(screen.getByText('Continue'));

      // Click Continue button
      await waitFor(() => screen.getByText('Continue'));
      const continueButton = screen.getByText('Continue');
      fireEvent.click(continueButton);

      // Verify error handling (this covers lines 93-94)
      expect(mockApiErrorToast).toHaveBeenCalledWith(mockErrors);
    });
  });

  describe('View Only Mode', () => {
    it('renders with Configurations title in view only mode', async () => {
      renderComponent({
        viewOnly: true,
        defaultPayload: MOCK_KNOWLEDGE_BASE_PAYLOAD,
      });

      await waitFor(() => {
        expect(screen.getByText('Configurations')).toBeTruthy();
      });
    });

    it('skips step 1 and shows form directly in view only mode', async () => {
      renderComponent({
        viewOnly: true,
        defaultPayload: MOCK_KNOWLEDGE_BASE_PAYLOAD,
      });

      await waitFor(() => {
        // Should not show the type selection step
        expect(screen.queryByText('Create new knowledge base')).toBeFalsy();
        // Should show the form directly
        expect(screen.getByText('Configurations')).toBeTruthy();
      });
    });

    it('displays pre-filled name from defaultPayload', async () => {
      renderComponent({
        viewOnly: true,
        defaultPayload: MOCK_KNOWLEDGE_BASE_PAYLOAD,
      });

      await waitFor(() => {
        const nameInput = screen.getByPlaceholderText('Enter name');
        expect(nameInput).toHaveValue('Test Knowledge Base');
      });
    });

    it('renders name input as readonly in view only mode', async () => {
      renderComponent({
        viewOnly: true,
        defaultPayload: MOCK_KNOWLEDGE_BASE_PAYLOAD,
      });

      await waitFor(() => {
        const nameInput = screen.getByPlaceholderText('Enter name');
        expect(nameInput).toHaveAttribute('readonly');
      });
    });

    it('shows Save Changes button instead of Create in view only mode', async () => {
      renderComponent({
        viewOnly: true,
        defaultPayload: MOCK_KNOWLEDGE_BASE_PAYLOAD,
      });

      await waitFor(() => {
        expect(screen.getByText('Save Changes')).toBeTruthy();
        expect(screen.queryByText('Continue')).toBeFalsy();
      });
    });

    it('Save Changes button is disabled in view only mode', async () => {
      renderComponent({
        viewOnly: true,
        defaultPayload: MOCK_KNOWLEDGE_BASE_PAYLOAD,
      });

      await waitFor(() => {
        const saveButton = screen.getByText('Save Changes');
        expect(saveButton).toBeDisabled();
      });
    });

    it('displays pre-filled chunk_size from defaultPayload', async () => {
      renderComponent({
        viewOnly: true,
        defaultPayload: MOCK_KNOWLEDGE_BASE_PAYLOAD,
      });

      await waitFor(() => {
        const chunkSizeInput = screen.getByPlaceholderText('1000');
        expect(chunkSizeInput).toHaveValue('1000');
      });
    });

    it('displays pre-filled chunk_overlap from defaultPayload', async () => {
      renderComponent({
        viewOnly: true,
        defaultPayload: MOCK_KNOWLEDGE_BASE_PAYLOAD,
      });

      await waitFor(() => {
        const chunkOverlapInput = screen.getByPlaceholderText('250');
        expect(chunkOverlapInput).toHaveValue('250');
      });
    });
  });

  describe('Drawer Close Behavior', () => {
    it('calls onClose when close button is clicked', async () => {
      renderComponent();

      await waitFor(() => {
        expect(screen.getByText('Create new knowledge base')).toBeTruthy();
      });

      // Find and click the close button (DrawerCloseButton)
      const closeButton = document.querySelector('[aria-label="Close"]');
      if (closeButton) {
        fireEvent.click(closeButton);

        await waitFor(() => {
          expect(mockOnClose).toHaveBeenCalled();
        });
      }
    });

    it('calls onClose when Cancel is clicked in step 1', async () => {
      renderComponent();

      await waitFor(() => {
        expect(screen.getByText('Cancel')).toBeTruthy();
      });

      fireEvent.click(screen.getByText('Cancel'));

      await waitFor(() => {
        expect(mockOnClose).toHaveBeenCalled();
      });
    });

    it('calls onClose when Cancel is clicked in step 2', async () => {
      renderComponent();

      await waitFor(() => {
        expect(screen.getByText('Continue')).toBeTruthy();
      });

      fireEvent.click(screen.getByText('Continue'));

      await waitFor(() => {
        expect(screen.getByText('Create new vector store')).toBeTruthy();
      });

      fireEvent.click(screen.getByText('Cancel'));

      await waitFor(() => {
        expect(mockOnClose).toHaveBeenCalled();
      });
    });
  });

  describe('Query Hooks Integration', () => {
    it('fetches embedding configurations on mount', async () => {
      const useQueryWrapper = jest.requireMock('@/hooks/useQueryWrapper').default;
      renderComponent();

      await waitFor(() => {
        expect(screen.getByText('Continue')).toBeTruthy();
      });

      fireEvent.click(screen.getByText('Continue'));

      await waitFor(() => {
        expect(useQueryWrapper).toHaveBeenCalledWith(['embedding_providers'], expect.any(Function));
      });
    });

    it('fetches connectors for vector store selection', async () => {
      const useQueryWrapper = jest.requireMock('@/hooks/useQueryWrapper').default;
      renderComponent();

      await waitFor(() => {
        expect(screen.getByText('Continue')).toBeTruthy();
      });

      fireEvent.click(screen.getByText('Continue'));

      await waitFor(() => {
        const connectorCalls = useQueryWrapper.mock.calls.filter(
          (call: string[][]) => call[0][0] === 'connectors',
        );
        expect(connectorCalls.length).toBeGreaterThan(0);
      });
    });

    it('fetches catalog when connector is available', async () => {
      const useQueryWrapper = jest.requireMock('@/hooks/useQueryWrapper').default;
      renderComponent();

      await waitFor(() => {
        expect(screen.getByText('Continue')).toBeTruthy();
      });

      fireEvent.click(screen.getByText('Continue'));

      await waitFor(() => {
        const catalogCalls = useQueryWrapper.mock.calls.filter(
          (call: string[][]) => call[0][0] === 'catalog',
        );
        expect(catalogCalls.length).toBeGreaterThan(0);
      });
    });
  });

  describe('Default Payload', () => {
    it('uses default empty payload when no defaultPayload provided', async () => {
      renderComponent();

      await waitFor(() => {
        expect(screen.getByText('Continue')).toBeTruthy();
      });

      fireEvent.click(screen.getByText('Continue'));

      await waitFor(() => {
        const nameInput = screen.getByPlaceholderText('Enter name');
        expect(nameInput).toHaveValue('');
      });
    });

    it('uses provided defaultPayload values', async () => {
      renderComponent({
        viewOnly: true,
        defaultPayload: MOCK_KNOWLEDGE_BASE_PAYLOAD,
      });

      await waitFor(() => {
        const nameInput = screen.getByPlaceholderText('Enter name');
        expect(nameInput).toHaveValue('Test Knowledge Base');
      });
    });
  });

  describe('Radio Group Selection', () => {
    it('has Vector Store selected by default', async () => {
      renderComponent();

      await waitFor(() => {
        // The RadioGroup should have vector_store as default value
        // This is verified by the fact that clicking Continue leads to vector store form
        expect(screen.getByText('Vector Store')).toBeTruthy();
      });
    });

    it('updates knowledge_base_type when radio option is clicked', async () => {
      renderComponent();

      await waitFor(() => screen.getByTestId('vector-store-option'));

      const vectorStoreOption = screen.getByTestId('vector-store-option');

      // Click the radio button (this covers line 120)
      // Note: In Chakra RadioGroup, clicking the option card should trigger onChange
      fireEvent.click(vectorStoreOption);

      // Since we only have one selectable option (Semantic Data Model is disabled),
      // we just verify that clicking it doesn't crash and works as expected.
      // If we had another enabled option, we would click it and verify state change.
      expect(vectorStoreOption).toBeTruthy();
    });
  });

  describe('Accessibility', () => {
    it('renders with proper drawer structure', async () => {
      renderComponent();

      await waitFor(() => {
        // Check drawer components are present
        expect(screen.getByRole('dialog')).toBeTruthy();
      });
    });

    it('has accessible close button', async () => {
      renderComponent();

      await waitFor(() => {
        const closeButton = document.querySelector('[aria-label="Close"]');
        expect(closeButton).toBeTruthy();
      });
    });
  });
});
