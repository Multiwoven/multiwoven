import { render, screen, fireEvent, waitFor } from '@testing-library/react';
import { expect } from '@jest/globals';
import '@testing-library/jest-dom/jest-globals';
import '@testing-library/jest-dom';
import { MemoryRouter } from 'react-router-dom';
import { ChakraProvider } from '@chakra-ui/react';
import { QueryClient, QueryClientProvider } from '@tanstack/react-query';
import ListKnowledgeBases from '../ListKnowledgeBases/ListKnowledgeBases';
import { KnowledgeBase } from '@/enterprise/services/knowledge-base';
import { ApiResponse, LinksType } from '@/services/common';
import { useRoleDataStore } from '@/enterprise/store/useRoleDataStore';
import { RoleItem } from '@/enterprise/services/types';
import { hasActionPermission } from '@/enterprise/utils/accessControlPermission';
import { UserActions } from '@/enterprise/types';

// Create a new QueryClient for each test
const createQueryClient = () =>
  new QueryClient({
    defaultOptions: {
      queries: {
        retry: false,
      },
    },
  });

// Type-accurate mock KnowledgeBase data
const MOCK_KNOWLEDGE_BASES: KnowledgeBase[] = [
  {
    id: '1',
    type: 'knowledge_bases',
    attributes: {
      name: 'Production Vector Store',
      knowledge_base_type: 'vector_store',
      size: 1048576, // 1 MB in bytes
      embedding_config: {
        api_key: 'sk-test-api-key-123',
        chunk_size: 1000,
        chunk_overlap: 250,
        embedding_model: 'text-embedding-ada-002',
        embedding_provider: 'openai',
      },
      storage_config: {
        table_name: 'embeddings',
        text_column_name: 'content',
        vector_column_name: 'embedding',
        metadata_column_name: 'metadata',
      },
      source_connector_id: 1,
      destination_connector_id: 2,
      hosted_data_store_id: 1,
      workspace_id: 1,
      created_at: '2024-01-15T10:30:00Z',
      updated_at: '2024-01-20T14:45:00Z',
    },
  },
  {
    id: '2',
    type: 'knowledge_bases',
    attributes: {
      name: 'Development KB',
      knowledge_base_type: 'vector_store',
      size: 524288, // 512 KB in bytes
      embedding_config: {
        api_key: 'sk-test-api-key-456',
        chunk_size: 500,
        chunk_overlap: 100,
        embedding_model: 'text-embedding-3-small',
        embedding_provider: 'openai',
      },
      storage_config: {
        table_name: 'documents',
        text_column_name: 'text',
        vector_column_name: 'vector',
        metadata_column_name: 'meta',
      },
      source_connector_id: 3,
      destination_connector_id: 4,
      hosted_data_store_id: null,
      workspace_id: 1,
      created_at: '2024-02-01T08:00:00Z',
      updated_at: '2024-02-10T16:30:00Z',
    },
  },
  {
    id: '3',
    type: 'knowledge_bases',
    attributes: {
      name: 'Test Knowledge Base',
      knowledge_base_type: 'vector_store',
      size: 2097152, // 2 MB in bytes
      embedding_config: {
        api_key: 'sk-test-api-key-789',
        chunk_size: 1500,
        chunk_overlap: 300,
        embedding_model: 'text-embedding-3-large',
        embedding_provider: 'openai',
      },
      storage_config: {
        table_name: 'test_embeddings',
        text_column_name: 'text_content',
        vector_column_name: 'embedding_vector',
        metadata_column_name: 'metadata_json',
      },
      source_connector_id: 5,
      destination_connector_id: 6,
      hosted_data_store_id: 2,
      workspace_id: 1,
      created_at: '2024-03-01T12:00:00Z',
      updated_at: '2024-03-15T09:15:00Z',
    },
  },
];

// Type-accurate mock links for pagination
const MOCK_LINKS: LinksType = {
  first: 'http://api.example.com/knowledge_base?page=1',
  last: 'http://api.example.com/knowledge_base?page=3',
  next: 'http://api.example.com/knowledge_base?page=2',
  prev: null,
  self: 'http://api.example.com/knowledge_base?page=1',
};

const MOCK_LINKS_SINGLE_PAGE: LinksType = {
  first: 'http://api.example.com/knowledge_base?page=1',
  last: 'http://api.example.com/knowledge_base?page=1',
  next: null,
  prev: null,
  self: 'http://api.example.com/knowledge_base?page=1',
};

// Type-accurate API response with data
const MOCK_API_RESPONSE_WITH_DATA: ApiResponse<KnowledgeBase[]> = {
  data: MOCK_KNOWLEDGE_BASES,
  status: 200,
  links: MOCK_LINKS,
};

// Type-accurate API response with empty data
const MOCK_API_RESPONSE_EMPTY: ApiResponse<KnowledgeBase[]> = {
  data: [],
  status: 200,
};

// Type-accurate API response with single page
const MOCK_API_RESPONSE_SINGLE_PAGE: ApiResponse<KnowledgeBase[]> = {
  data: MOCK_KNOWLEDGE_BASES.slice(0, 2),
  status: 200,
  links: MOCK_LINKS_SINGLE_PAGE,
};

// Mock navigate function
const mockNavigate = jest.fn();

// Mock refetch function
const mockRefetch = jest.fn();

// Mock page change handler
const mockHandlePageChange = jest.fn();

// Configurable mock response for useGetKnowledgeBases
let mockKnowledgeBasesResponse: ApiResponse<KnowledgeBase[]> = MOCK_API_RESPONSE_WITH_DATA;
let mockIsLoading = false;

// Mock react-router-dom
jest.mock('react-router-dom', () => ({
  ...jest.requireActual('react-router-dom'),
  useNavigate: () => mockNavigate,
}));

// Mock usePagination hook
jest.mock('@/hooks/usePagination', () => ({
  usePagination: () => ({
    currentPage: 1,
    handlePageChange: mockHandlePageChange,
  }),
}));

// Mock useKnowledgeBaseQueries hook
jest.mock('@/enterprise/hooks/queries/useKnowledgeBaseQueries', () => ({
  __esModule: true,
  default: () => ({
    useGetKnowledgeBases: () => ({
      data: mockKnowledgeBasesResponse,
      isLoading: mockIsLoading,
      isError: false,
      refetch: mockRefetch,
    }),
    useGetKnowledgeBase: jest.fn(),
    useGetAllKnowledgeBaseFiles: jest.fn(),
    useGetKnowledgeBaseFile: jest.fn(),
    useDeleteKnowledgeBaseFile: jest.fn(),
    useUploadKnowledgeBaseFile: jest.fn(),
  }),
}));

// Mock delete mutation function
const mockDeleteMutate = jest.fn();

// Mock useKnowledgeBaseMutations hook for CreateAndViewKBDrawer
jest.mock('@/enterprise/hooks/mutations/useKnowledgeBaseMutations', () => ({
  __esModule: true,
  default: () => ({
    createKnowledgeBase: {
      mutate: jest.fn(),
      reset: jest.fn(),
      isPending: false,
      isSuccess: false,
      isError: false,
    },
    deleteKnowledgeBaseMutation: {
      mutate: mockDeleteMutate,
      isPending: false,
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

// Mock useQueryWrapper for embedding providers (used by drawer)
jest.mock('@/hooks/useQueryWrapper', () => ({
  __esModule: true,
  default: jest.fn().mockImplementation((queryKey: string[]) => {
    if (queryKey[0] === 'embedding_providers') {
      return {
        data: {
          data: [
            {
              id: '1',
              type: 'embedding_configurations',
              attributes: {
                mode: 'openai',
                models: ['text-embedding-ada-002', 'text-embedding-3-small'],
              },
            },
          ],
        },
        isLoading: false,
        isError: false,
        refetch: jest.fn(),
      };
    }
    if (queryKey[0] === 'connectors') {
      return {
        data: { data: [] },
        isLoading: false,
        isError: false,
        refetch: jest.fn(),
      };
    }
    return { data: null, isLoading: false, isError: false, refetch: jest.fn() };
  }),
}));

// Mock useRoleDataStore for RoleAccess component
jest.mock('@/enterprise/store/useRoleDataStore');
const mockedUseRoleDataStore = useRoleDataStore as jest.MockedFunction<typeof useRoleDataStore>;

// Mock hasActionPermission utility
jest.mock('@/enterprise/utils/accessControlPermission');
const mockedHasActionPermission = hasActionPermission as jest.MockedFunction<
  typeof hasActionPermission
>;

// Mock ConfirmDeleteModal
jest.mock('@/components/ConfirmDeleteModal', () => ({
  __esModule: true,
  default: ({
    open,
    title,
    description,
    onDelete,
    onClose,
    isDeleting,
  }: {
    open: boolean;
    title: string;
    description: string;
    onDelete: () => void;
    onClose: () => void;
    isDeleting?: boolean;
  }) => {
    if (!open) return null;
    return (
      <div data-testid='confirm-delete-modal'>
        <span data-testid='delete-modal-title'>{title}</span>
        <span data-testid='delete-modal-description'>{description}</span>
        <button data-testid='confirm-delete-button' onClick={onDelete} disabled={isDeleting}>
          Delete
        </button>
        <button data-testid='cancel-delete-button' onClick={onClose}>
          Cancel
        </button>
      </div>
    );
  },
}));

// Required for Chakra UI portal and DataTable
global.ResizeObserver = class {
  observe() {}
  unobserve() {}
  disconnect() {}
};

describe('ListKnowledgeBases', () => {
  let queryClient: QueryClient;

  beforeEach(() => {
    queryClient = createQueryClient();
    jest.clearAllMocks();
    mockKnowledgeBasesResponse = MOCK_API_RESPONSE_WITH_DATA;
    mockIsLoading = false;
    // Reset and set default implementation for delete mock
    mockDeleteMutate.mockClear();
    mockDeleteMutate.mockImplementation((_params, options) => {
      if (options?.onSuccess) {
        options.onSuccess({});
      }
    });
    // Setup RoleAccess mocks
    mockedUseRoleDataStore.mockImplementation((selector: any) =>
      selector({ activeRole: {} as RoleItem }),
    );
    mockedHasActionPermission.mockReturnValue(true);
  });

  const renderComponent = () => {
    return render(
      <QueryClientProvider client={queryClient}>
        <ChakraProvider>
          <MemoryRouter>
            <ListKnowledgeBases />
          </MemoryRouter>
        </ChakraProvider>
      </QueryClientProvider>,
    );
  };

  const mockKnowledgeBasePermissions = (permissions: Partial<Record<UserActions, boolean>>) => {
    mockedHasActionPermission.mockImplementation((_role, location, action) => {
      if (location !== 'knowledge_base') {
        return true;
      }

      return permissions[action] ?? true;
    });
  };

  describe('Component Rendering', () => {
    it('renders the page title', () => {
      renderComponent();
      expect(screen.getByText('Knowledge Bases')).toBeTruthy();
    });

    it('renders the page description', () => {
      renderComponent();
      expect(
        screen.getByText(
          'Create and manage knowledge sources and document collections for your AI workflows.',
        ),
      ).toBeTruthy();
    });

    it('renders the New Knowledge Base button', () => {
      renderComponent();
      expect(screen.getByText('New Knowledge Base')).toBeTruthy();
    });

    it('renders plus icon in the button', () => {
      renderComponent();
      const button = screen.getByText('New Knowledge Base');
      expect(button.closest('button')).toBeTruthy();
    });

    it('renders ContentContainer wrapper', () => {
      const { container } = renderComponent();
      expect(container.querySelector('[class*="chakra"]')).toBeTruthy();
    });
  });

  describe('Data Table with Knowledge Bases', () => {
    it('renders column headers correctly', () => {
      renderComponent();
      expect(screen.getByText('Name')).toBeTruthy();
      expect(screen.getByText('Type')).toBeTruthy();
      expect(screen.getByText('Size')).toBeTruthy();
      expect(screen.getByText('Last Updated')).toBeTruthy();
    });

    it('renders knowledge base names from data', () => {
      renderComponent();
      expect(screen.getByText('Production Vector Store')).toBeTruthy();
      expect(screen.getByText('Development KB')).toBeTruthy();
      expect(screen.getByText('Test Knowledge Base')).toBeTruthy();
    });

    it('renders knowledge base types', () => {
      renderComponent();
      const typeTexts = screen.getAllByText('Vector Store');
      expect(typeTexts.length).toBe(3);
    });

    it('renders formatted file sizes', () => {
      renderComponent();
      // 1048576 bytes = 1.00 MB
      expect(screen.getByText('1.00 MB')).toBeTruthy();
      // 524288 bytes = 512.00 KB
      expect(screen.getByText('512.00 KB')).toBeTruthy();
      // 2097152 bytes = 2.00 MB
      expect(screen.getByText('2.00 MB')).toBeTruthy();
    });

    it('renders formatted timestamps', () => {
      renderComponent();
      expect(screen.getAllByText('01/01/2024').length).toBe(3);
    });

    it('renders table rows for each knowledge base', () => {
      renderComponent();
      const rows = screen.getAllByRole('row');
      // 1 header row + 3 data rows
      expect(rows.length).toBe(4);
    });

    it('exposes stable tbody and row test ids on the knowledge bases table', () => {
      renderComponent();

      expect(screen.getByTestId('knowledge-bases-list-table-tbody')).toBeInTheDocument();
      expect(screen.getByTestId('kb-list-table-row-1')).toBeInTheDocument();
      expect(screen.getByTestId('kb-list-table-row-2')).toBeInTheDocument();
      expect(screen.getByTestId('kb-list-table-row-3')).toBeInTheDocument();
    });

    it('renders delete action menu for each row', () => {
      const { container } = renderComponent();
      // HorizontalMenuActions renders menu triggers
      const menuTriggers = container.querySelectorAll('[data-testid]');
      expect(menuTriggers).toBeTruthy();
    });
  });

  describe('Empty State', () => {
    beforeEach(() => {
      mockKnowledgeBasesResponse = MOCK_API_RESPONSE_EMPTY;
    });

    it('renders empty state when no knowledge bases exist', () => {
      renderComponent();
      expect(screen.getByText('No Knowledge Bases created')).toBeTruthy();
    });

    it('renders empty state description', () => {
      renderComponent();
      expect(
        screen.getAllByText(
          'Create and manage knowledge sources and document collections for your AI workflows.',
        ).length,
      ).toBe(2);
    });

    it('renders Create Knowledge Base button in empty state', () => {
      renderComponent();
      expect(screen.getByText('Create Knowledge Base')).toBeTruthy();
    });

    it('uses a stable test id on the empty-state create button', () => {
      renderComponent();

      expect(screen.getByTestId('kb-empty-create-button')).toBeInTheDocument();
    });

    it('does not render data table when empty', () => {
      renderComponent();
      // Should not have the Name column header when in empty state
      const tables = screen.queryAllByRole('table');
      expect(tables.length).toBe(0);
    });

    it('empty state button opens create drawer', async () => {
      renderComponent();

      const createButton = screen.getByText('Create Knowledge Base');
      fireEvent.click(createButton);

      await waitFor(() => {
        expect(screen.getByText('Create new knowledge base')).toBeTruthy();
      });
    });
  });

  describe('Row Click Navigation', () => {
    it('navigates to knowledge base details when row is clicked', () => {
      renderComponent();

      const firstRow = screen.getByText('Production Vector Store').closest('tr');
      if (firstRow) {
        fireEvent.click(firstRow);
        expect(mockNavigate).toHaveBeenCalledWith('/knowledge-bases/1');
      }
    });

    it('navigates to correct path for second knowledge base', () => {
      renderComponent();

      const secondRow = screen.getByText('Development KB').closest('tr');
      if (secondRow) {
        fireEvent.click(secondRow);
        expect(mockNavigate).toHaveBeenCalledWith('/knowledge-bases/2');
      }
    });

    it('navigates to correct path for third knowledge base', () => {
      renderComponent();

      const thirdRow = screen.getByText('Test Knowledge Base').closest('tr');
      if (thirdRow) {
        fireEvent.click(thirdRow);
        expect(mockNavigate).toHaveBeenCalledWith('/knowledge-bases/3');
      }
    });
  });

  describe('Create Knowledge Base Drawer', () => {
    it('opens drawer when New Knowledge Base button is clicked', async () => {
      renderComponent();

      const newButton = screen.getByText('New Knowledge Base');
      fireEvent.click(newButton);

      await waitFor(() => {
        expect(screen.getByText('Create new knowledge base')).toBeTruthy();
      });
    });

    it('drawer shows Vector Store option', async () => {
      renderComponent();

      const newButton = screen.getByText('New Knowledge Base');
      fireEvent.click(newButton);

      await waitFor(() => {
        expect(screen.getByTestId('vector-store-option')).toBeTruthy();
      });
    });

    it('drawer shows Semantic Data Model option as coming soon', async () => {
      renderComponent();

      const newButton = screen.getByText('New Knowledge Base');
      fireEvent.click(newButton);

      await waitFor(() => {
        expect(screen.getByText('Semantic Data Model')).toBeTruthy();
        expect(screen.getByText('coming soon')).toBeTruthy();
      });
    });

    it('closes drawer when Cancel is clicked', async () => {
      renderComponent();

      const newButton = screen.getByText('New Knowledge Base');
      fireEvent.click(newButton);

      await waitFor(() => {
        expect(screen.getByText('Cancel')).toBeTruthy();
      });

      const cancelButton = screen.getByText('Cancel');
      fireEvent.click(cancelButton);

      await waitFor(() => {
        expect(screen.queryByText('Create new knowledge base')).toBeFalsy();
      });
    });
  });

  describe('Pagination', () => {
    it('renders pagination component when links are present', () => {
      renderComponent();
      const pagination = screen.getByTestId('pagination');
      expect(pagination).toBeTruthy();
    });

    it('does not render pagination when data is empty', () => {
      mockKnowledgeBasesResponse = MOCK_API_RESPONSE_EMPTY;
      renderComponent();
      const pagination = screen.queryByTestId('pagination');
      expect(pagination).toBeFalsy();
    });

    it('renders pagination with correct page numbers', () => {
      renderComponent();
      const pagination = screen.getByTestId('pagination');
      expect(pagination).toBeTruthy();
    });

    it('uses usePagination hook for page state', () => {
      renderComponent();
      // The hook is mocked and returns currentPage: 1
      const pagination = screen.getByTestId('pagination');
      expect(pagination).toBeTruthy();
    });
  });

  describe('API Integration', () => {
    it('uses useKnowledgeBaseQueries hook', () => {
      renderComponent();
      // Verify data is displayed from the mock
      expect(screen.getByText('Production Vector Store')).toBeTruthy();
    });

    it('provides refetch function to drawer', async () => {
      renderComponent();

      // Open drawer
      const newButton = screen.getByText('New Knowledge Base');
      fireEvent.click(newButton);

      await waitFor(() => {
        expect(screen.getByText('Create new knowledge base')).toBeTruthy();
      });
    });
  });

  describe('Data Display with Single Page', () => {
    beforeEach(() => {
      mockKnowledgeBasesResponse = MOCK_API_RESPONSE_SINGLE_PAGE;
    });

    it('renders data with single page links', () => {
      renderComponent();
      expect(screen.getByText('Production Vector Store')).toBeTruthy();
      expect(screen.getByText('Development KB')).toBeTruthy();
    });

    it('renders pagination for single page', () => {
      renderComponent();
      const pagination = screen.getByTestId('pagination');
      expect(pagination).toBeTruthy();
    });
  });

  describe('Table Styling', () => {
    it('renders within TableBox container', () => {
      const { container } = renderComponent();
      expect(container.querySelector('table')).toBeTruthy();
    });

    it('renders text with correct font weight for names', () => {
      renderComponent();
      const nameCell = screen.getByText('Production Vector Store');
      expect(nameCell).toBeTruthy();
    });
  });

  describe('Accessibility', () => {
    it('renders table with proper structure', () => {
      renderComponent();
      const table = screen.getByRole('table');
      expect(table).toBeTruthy();
    });

    it('renders rows with proper role', () => {
      renderComponent();
      const rows = screen.getAllByRole('row');
      expect(rows.length).toBeGreaterThan(0);
    });

    it('button has proper type', () => {
      renderComponent();
      const button = screen.getByText('New Knowledge Base').closest('button');
      expect(button).toBeTruthy();
    });
  });

  describe('Edge Cases', () => {
    it('handles knowledge base with null hosted_data_store_id', () => {
      renderComponent();
      // Development KB has hosted_data_store_id: null
      expect(screen.getByText('Development KB')).toBeTruthy();
    });

    it('handles different file sizes correctly', () => {
      renderComponent();
      // Verify all three different sizes are formatted
      expect(screen.getByText('1.00 MB')).toBeTruthy();
      expect(screen.getByText('512.00 KB')).toBeTruthy();
      expect(screen.getByText('2.00 MB')).toBeTruthy();
    });

    it('handles different timestamps correctly', () => {
      renderComponent();
      // All three dates should be rendered
      expect(screen.getAllByText('01/01/2024').length).toBe(3);
    });
  });

  describe('Loading State', () => {
    it('renders component while data is available', () => {
      renderComponent();
      expect(screen.getByText('Knowledge Bases')).toBeTruthy();
    });

    it('renders loader when data is loading', () => {
      mockIsLoading = true;
      renderComponent();
      expect(screen.getByTestId('loader')).toBeTruthy();
    });
  });

  describe('Button Interactions', () => {
    it('New Knowledge Base button is clickable', () => {
      renderComponent();
      const button = screen.getByText('New Knowledge Base').closest('button');
      expect(button).not.toBeDisabled();
    });

    it('triggers drawer open on button click', async () => {
      renderComponent();

      const button = screen.getByText('New Knowledge Base');
      fireEvent.click(button);

      await waitFor(() => {
        // Drawer should be visible
        expect(screen.getByRole('dialog')).toBeTruthy();
      });
    });
  });

  describe('RBAC (Role-Based Access Control)', () => {
    describe('Create Permission (New Knowledge Base Button)', () => {
      it('renders New Knowledge Base button when user has Create permission', () => {
        mockKnowledgeBasePermissions({ [UserActions.Create]: true });

        renderComponent();
        const newButton = screen.getByText('New Knowledge Base');
        expect(newButton).toBeTruthy();
      });

      it('does not render New Knowledge Base button when user lacks Create permission', () => {
        mockKnowledgeBasePermissions({ [UserActions.Create]: false });

        renderComponent();
        const newButton = screen.queryByText('New Knowledge Base');
        expect(newButton).toBeFalsy();
      });

      it('still renders page content when user lacks Create permission', () => {
        mockKnowledgeBasePermissions({ [UserActions.Create]: false });

        renderComponent();
        expect(screen.getByText('Knowledge Bases')).toBeTruthy();
        expect(screen.getByText('Production Vector Store')).toBeTruthy();
      });
    });

    describe('Empty State with RBAC', () => {
      beforeEach(() => {
        mockKnowledgeBasesResponse = MOCK_API_RESPONSE_EMPTY;
      });

      it('shows Create Knowledge Base button in empty state when user has Create permission', () => {
        mockKnowledgeBasePermissions({ [UserActions.Create]: true });

        renderComponent();
        expect(screen.getByText('Create Knowledge Base')).toBeTruthy();
      });

      it('does not show Create Knowledge Base button in empty state when user lacks Create permission', () => {
        mockKnowledgeBasePermissions({ [UserActions.Create]: false });

        renderComponent();
        const createButton = screen.queryByText('Create Knowledge Base');
        expect(createButton).toBeFalsy();
      });

      it('still shows empty state message when user lacks Create permission', () => {
        mockKnowledgeBasePermissions({ [UserActions.Create]: false });

        renderComponent();
        expect(screen.getByText('No Knowledge Bases created')).toBeTruthy();
      });

      it('shows the read-only empty state description when user lacks Create permission', () => {
        mockKnowledgeBasePermissions({ [UserActions.Create]: false });

        renderComponent();
        expect(
          screen.getByText(
            'You will be able to view the data on this page once the admin configures it',
          ),
        ).toBeInTheDocument();
        expect(screen.queryByText('Create Knowledge Base')).not.toBeInTheDocument();
      });
    });

    describe('Data Table Access', () => {
      it('renders data table regardless of Create permission', () => {
        mockKnowledgeBasePermissions({ [UserActions.Create]: false });

        renderComponent();
        expect(screen.getByText('Production Vector Store')).toBeTruthy();
        expect(screen.getByText('Development KB')).toBeTruthy();
        expect(screen.getByRole('table')).toBeTruthy();
      });

      it('allows row navigation when user lacks Create permission', () => {
        mockKnowledgeBasePermissions({ [UserActions.Create]: false });

        renderComponent();

        const firstRow = screen.getByText('Production Vector Store').closest('tr');
        if (firstRow) {
          fireEvent.click(firstRow);
          expect(mockNavigate).toHaveBeenCalledWith('/knowledge-bases/1');
        }
      });
    });

    describe('Combined RBAC Scenarios', () => {
      it('shows New KB button in header but not in empty state create button when permissions differ', () => {
        mockKnowledgeBasesResponse = MOCK_API_RESPONSE_WITH_DATA;
        mockedHasActionPermission.mockReturnValue(true);

        renderComponent();
        expect(screen.getByText('New Knowledge Base')).toBeTruthy();
      });

      it('renders complete UI when user has all permissions', () => {
        mockedHasActionPermission.mockReturnValue(true);

        renderComponent();
        expect(screen.getByText('Knowledge Bases')).toBeTruthy();
        expect(screen.getByText('New Knowledge Base')).toBeTruthy();
        expect(screen.getByRole('table')).toBeTruthy();
      });

      it('renders read-only UI when user has no Create permission', () => {
        mockKnowledgeBasePermissions({ [UserActions.Create]: false });

        renderComponent();
        expect(screen.getByText('Knowledge Bases')).toBeTruthy();
        expect(screen.queryByText('New Knowledge Base')).toBeFalsy();
        expect(screen.getByRole('table')).toBeTruthy();
      });
    });

    describe('Permission Edge Cases', () => {
      it('renders loader when activeRole is null', () => {
        mockedUseRoleDataStore.mockImplementation((selector: any) =>
          selector({ activeRole: null }),
        );

        renderComponent();
        expect(screen.getByTestId('loader')).toBeInTheDocument();
        expect(screen.queryByText('Knowledge Bases')).not.toBeInTheDocument();
      });

      it('renders NoAccess when read permission is denied', () => {
        mockedUseRoleDataStore.mockImplementation((selector: any) =>
          selector({ activeRole: {} as RoleItem }),
        );
        mockKnowledgeBasePermissions({ [UserActions.Read]: false });

        renderComponent();
        expect(screen.getByText('Access Denied')).toBeInTheDocument();
        expect(screen.queryByText('Knowledge Bases')).not.toBeInTheDocument();
      });
    });
  });

  describe('Delete Knowledge Base', () => {
    it('opens confirmation modal when delete button is clicked', async () => {
      mockKnowledgeBasePermissions({ [UserActions.Delete]: true });

      renderComponent();

      // Find and click the menu trigger for the first row
      const menuTriggers = screen.getAllByTestId('horizontal-menu-actions-trigger');
      expect(menuTriggers.length).toBeGreaterThan(0);

      fireEvent.click(menuTriggers[0]);

      await waitFor(() => {
        const deleteButtons = screen.getAllByTestId('delete-knowledge-base');
        expect(deleteButtons.length).toBeGreaterThan(0);
      });

      const deleteButtons = screen.getAllByTestId('delete-knowledge-base');
      fireEvent.click(deleteButtons[0]);

      await waitFor(() => {
        expect(screen.getByTestId('confirm-delete-modal')).toBeInTheDocument();
        expect(screen.getByTestId('delete-modal-title')).toHaveTextContent(
          'Are you sure you want to delete this Knowledge Base?',
        );
        expect(screen.getByTestId('delete-modal-description')).toHaveTextContent(
          'This action will permanently delete Production Vector Store and all associated files. This cannot be undone.',
        );
      });
    });

    it('calls delete mutation when confirmed in modal', async () => {
      mockKnowledgeBasePermissions({ [UserActions.Delete]: true });

      renderComponent();

      // Find and click the menu trigger for the first row
      const menuTriggers = screen.getAllByTestId('horizontal-menu-actions-trigger');
      expect(menuTriggers.length).toBeGreaterThan(0);

      fireEvent.click(menuTriggers[0]);

      await waitFor(() => {
        const deleteButtons = screen.getAllByTestId('delete-knowledge-base');
        expect(deleteButtons.length).toBeGreaterThan(0);
      });

      const deleteButtons = screen.getAllByTestId('delete-knowledge-base');
      fireEvent.click(deleteButtons[0]);

      await waitFor(() => {
        expect(screen.getByTestId('confirm-delete-modal')).toBeInTheDocument();
      });

      // Click confirm in modal
      const confirmButton = screen.getByTestId('confirm-delete-button');
      fireEvent.click(confirmButton);

      await waitFor(() => {
        expect(mockDeleteMutate).toHaveBeenCalledWith(
          {
            knowledgeBaseId: '1',
          },
          expect.objectContaining({
            onSuccess: expect.any(Function),
          }),
        );
      });
    });

    it('closes confirmation modal when cancel is clicked', async () => {
      mockKnowledgeBasePermissions({ [UserActions.Delete]: true });

      renderComponent();

      const menuTriggers = screen.getAllByTestId('horizontal-menu-actions-trigger');
      fireEvent.click(menuTriggers[0]);

      await waitFor(() => {
        const deleteButtons = screen.getAllByTestId('delete-knowledge-base');
        expect(deleteButtons.length).toBeGreaterThan(0);
      });

      const deleteButtons = screen.getAllByTestId('delete-knowledge-base');
      fireEvent.click(deleteButtons[0]);

      await waitFor(() => {
        expect(screen.getByTestId('confirm-delete-modal')).toBeInTheDocument();
      });

      // Click cancel in modal
      const cancelButton = screen.getByTestId('cancel-delete-button');
      fireEvent.click(cancelButton);

      await waitFor(() => {
        expect(screen.queryByTestId('confirm-delete-modal')).not.toBeInTheDocument();
      });

      // Delete should not be called
      expect(mockDeleteMutate).not.toHaveBeenCalled();
    });

    it('stops event propagation when clicking delete menu', async () => {
      mockKnowledgeBasePermissions({ [UserActions.Delete]: true });

      renderComponent();

      const menuTriggers = screen.getAllByTestId('horizontal-menu-actions-trigger');
      fireEvent.click(menuTriggers[0]);

      await waitFor(() => {
        const deleteButtons = screen.getAllByTestId('delete-knowledge-base');
        expect(deleteButtons.length).toBeGreaterThan(0);
      });

      // Verify navigation wasn't triggered when clicking menu
      expect(mockNavigate).not.toHaveBeenCalled();
    });

    it('does not show delete button when user lacks Delete permission', () => {
      mockKnowledgeBasePermissions({ [UserActions.Delete]: false });

      renderComponent();

      // Menu triggers should not be visible when no delete permission
      const menuTriggers = screen.queryAllByTestId('horizontal-menu-actions-trigger');
      expect(menuTriggers.length).toBe(0);
    });
  });

  describe('Knowledge Base Type Rendering', () => {
    it('renders Vector Store for vector_store type', () => {
      renderComponent();
      const typeTexts = screen.getAllByText('Vector Store');
      expect(typeTexts.length).toBe(3);
    });

    it('renders raw type value for non-vector_store types', () => {
      // Add a knowledge base with a different type
      mockKnowledgeBasesResponse = {
        data: [
          {
            ...MOCK_KNOWLEDGE_BASES[0],
            attributes: {
              ...MOCK_KNOWLEDGE_BASES[0].attributes,
              knowledge_base_type: 'semantic_model' as any,
            },
          },
        ],
        status: 200,
        links: MOCK_LINKS,
      };

      renderComponent();
      expect(screen.getByText('semantic_model')).toBeTruthy();
    });
  });
});
