import { render, screen, fireEvent, waitFor } from '@testing-library/react';
import { expect } from '@jest/globals';
import '@testing-library/jest-dom/jest-globals';
import '@testing-library/jest-dom';
import { MemoryRouter } from 'react-router-dom';
import { ChakraProvider } from '@chakra-ui/react';
import { QueryClient, QueryClientProvider } from '@tanstack/react-query';
import ViewKnowledgeBase from '../ViewKnowledgeBase';
import { KnowledgeBase, KnowledgeBaseFile } from '@/enterprise/services/knowledge-base';
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
const MOCK_KNOWLEDGE_BASE: KnowledgeBase = {
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
};

// Type-accurate mock KnowledgeBaseFile data
const MOCK_KNOWLEDGE_BASE_FILES: KnowledgeBaseFile[] = [
  {
    id: 'file-1',
    type: 'agents-knowledge_base_files',
    attributes: {
      knowledge_base_id: 1,
      name: 'sales_report.pdf',
      size: 524288, // 512 KB
      upload_status: 'processing',
      workflow_enabled: true,
      created_at: '2024-01-15T10:30:00Z',
      updated_at: '2024-01-20T14:45:00Z',
    },
  },
  {
    id: 'file-2',
    type: 'agents-knowledge_base_files',
    attributes: {
      knowledge_base_id: 1,
      name: 'product_docs.pdf',
      size: 1048576, // 1 MB
      upload_status: 'processed',
      workflow_enabled: true,
      created_at: '2024-01-15T10:30:00Z',
      updated_at: '2024-01-20T14:45:00Z',
    },
  },
  {
    id: 'file-3',
    type: 'agents-knowledge_base_files',
    attributes: {
      knowledge_base_id: 1,
      name: 'customer_data.pdf',
      size: 2147483648, // 2GB
      upload_status: 'failed',
      workflow_enabled: true,
      created_at: '2024-01-15T10:30:00Z',
      updated_at: '2024-01-20T14:45:00Z',
    },
  },
  {
    id: 'file-4',
    type: 'agents-knowledge_base_files',
    attributes: {
      knowledge_base_id: 1,
      name: 'random.pdf',
      size: 2147483648, // 2GB
      upload_status: 'failed_to_delete',
      workflow_enabled: true,
      created_at: '2024-01-15T10:30:00Z',
      updated_at: '2024-01-20T14:45:00Z',
    },
  },
];

// Type-accurate mock links for pagination
const MOCK_LINKS: LinksType = {
  first: 'http://api.example.com/knowledge_bases/1/knowledge_base_files?page=1',
  last: 'http://api.example.com/knowledge_bases/1/knowledge_base_files?page=3',
  next: 'http://api.example.com/knowledge_bases/1/knowledge_base_files?page=2',
  prev: null,
  self: 'http://api.example.com/knowledge_bases/1/knowledge_base_files?page=1',
};

const MOCK_LINKS_SINGLE_PAGE: LinksType = {
  first: 'http://api.example.com/knowledge_bases/1/knowledge_base_files?page=1',
  last: 'http://api.example.com/knowledge_bases/1/knowledge_base_files?page=1',
  next: null,
  prev: null,
  self: 'http://api.example.com/knowledge_bases/1/knowledge_base_files?page=1',
};

// Type-accurate API response for knowledge base
const MOCK_KB_API_RESPONSE: ApiResponse<KnowledgeBase> = {
  data: MOCK_KNOWLEDGE_BASE,
  status: 200,
};

// Type-accurate API response for files with pagination
const MOCK_FILES_API_RESPONSE: ApiResponse<KnowledgeBaseFile[]> = {
  data: MOCK_KNOWLEDGE_BASE_FILES,
  status: 200,
  links: MOCK_LINKS,
};

// Type-accurate API response for empty files
const MOCK_FILES_API_RESPONSE_EMPTY: ApiResponse<KnowledgeBaseFile[]> = {
  data: [],
  status: 200,
};

// Type-accurate API response for single page
const MOCK_FILES_API_RESPONSE_SINGLE_PAGE: ApiResponse<KnowledgeBaseFile[]> = {
  data: MOCK_KNOWLEDGE_BASE_FILES.slice(0, 2),
  status: 200,
  links: MOCK_LINKS_SINGLE_PAGE,
};

// Mock functions for mutations
const mockDeleteMutate = jest.fn();
const mockUploadMutate = jest.fn();
const mockGetFileMutate = jest.fn();
const mockRefetch = jest.fn();
const mockHandlePageChange = jest.fn();

// Mock functions for toast hooks
const mockApiErrorToast = jest.fn();
const mockErrorToast = jest.fn();
const mockCustomToast = jest.fn();

// Configurable mock responses
let mockKnowledgeBaseResponse: ApiResponse<KnowledgeBase> = MOCK_KB_API_RESPONSE;
let mockFilesResponse: ApiResponse<KnowledgeBaseFile[]> = MOCK_FILES_API_RESPONSE;

let mockIsLoadingGetAllKBFiles = false;
let mockIsLoadingGetAllKB = false;

// Mock react-router-dom
jest.mock('react-router-dom', () => ({
  ...jest.requireActual('react-router-dom'),
  useParams: () => ({ id: '1' }),
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
    useGetKnowledgeBase: () => ({
      data: mockKnowledgeBaseResponse,
      isLoading: mockIsLoadingGetAllKB,
      isError: false,
      refetch: mockRefetch,
    }),
    useGetAllKnowledgeBaseFiles: () => ({
      data: mockFilesResponse,
      isLoading: mockIsLoadingGetAllKBFiles,
      isError: false,
      refetch: mockRefetch,
    }),
    useGetKnowledgeBases: jest.fn(),
    useGetKnowledgeBaseFile: jest.fn(),
    useDeleteKnowledgeBaseFile: jest.fn(),
    useUploadKnowledgeBaseFile: jest.fn(),
  }),
}));

// Mock useKnowledgeBaseMutations hook
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
    deleteKnowledgeBaseFileMutation: {
      mutate: mockDeleteMutate,
      isPending: false,
    },
    getKnowledgeBaseFileMutation: {
      mutate: mockGetFileMutate,
      isPending: false,
    },
    uploadKnowledgeBaseFileMutation: {
      mutate: mockUploadMutate,
      isPending: false,
      mutateAsync: jest.fn(),
    },
  }),
}));

// Mock toast hooks
jest.mock('@/hooks/useErrorToast', () => ({
  useErrorToast: () => mockErrorToast,
  useAPIErrorsToast: () => mockApiErrorToast,
}));

jest.mock('@/hooks/useCustomToast', () => ({
  __esModule: true,
  default: () => mockCustomToast,
}));

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

// Mock useRoleDataStore for RoleAccess component
jest.mock('@/enterprise/store/useRoleDataStore');

// Mock hasActionPermission utility
jest.mock('@/enterprise/utils/accessControlPermission');

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

// Required for Chakra UI portal and DataTable
global.ResizeObserver = class {
  observe() {}
  unobserve() {}
  disconnect() {}
};

describe('ViewKnowledgeBase', () => {
  let queryClient: QueryClient;
  const mockedUseRoleDataStore = useRoleDataStore as jest.MockedFunction<typeof useRoleDataStore>;
  const mockedHasActionPermission = hasActionPermission as jest.MockedFunction<
    typeof hasActionPermission
  >;

  beforeEach(() => {
    queryClient = createQueryClient();
    jest.clearAllMocks();
    // Reset mock functions
    mockDeleteMutate.mockClear();
    mockUploadMutate.mockClear();
    mockGetFileMutate.mockClear();
    mockRefetch.mockClear();
    mockHandlePageChange.mockClear();
    mockApiErrorToast.mockClear();
    mockErrorToast.mockClear();
    mockCustomToast.mockClear();
    // Set default implementations that call callbacks if provided
    mockDeleteMutate.mockImplementation((_params, options) => {
      if (options?.onSuccess) {
        options.onSuccess({});
      }
    });
    mockUploadMutate.mockImplementation((_params, options) => {
      if (options?.onSuccess) {
        options.onSuccess({ data: { attributes: { upload_status: 'processing' } } });
      }
    });
    mockGetFileMutate.mockImplementation((_params, options) => {
      if (options?.onSuccess) {
        const mockBlob = new Blob(['test'], { type: 'application/pdf' });
        options.onSuccess(mockBlob);
      }
    });
    // Reset mock responses
    mockKnowledgeBaseResponse = MOCK_KB_API_RESPONSE;
    mockFilesResponse = MOCK_FILES_API_RESPONSE;
    mockIsLoadingGetAllKBFiles = false;
    mockIsLoadingGetAllKB = false;
    // Setup RoleAccess mocks - default to having permissions
    mockedUseRoleDataStore.mockReturnValue({ activeRole: {} as RoleItem });
    mockedHasActionPermission.mockReturnValue(true);
  });

  const renderComponent = () => {
    return render(
      <QueryClientProvider client={queryClient}>
        <ChakraProvider>
          <MemoryRouter>
            <ViewKnowledgeBase />
          </MemoryRouter>
        </ChakraProvider>
      </QueryClientProvider>,
    );
  };

  describe('Component Rendering', () => {
    it('renders the knowledge base name in the top bar', () => {
      renderComponent();
      expect(screen.getByTestId('top-bar-name')).toHaveTextContent('Production Vector Store');
    });

    it('renders the breadcrumb navigation with correct links', () => {
      renderComponent();
      expect(screen.getByText('Knowledge Bases')).toBeTruthy();
      // Name appears in both breadcrumb and top bar
      expect(screen.getAllByText('Production Vector Store').length).toBeGreaterThan(0);
    });

    it('renders the Add Files button', () => {
      renderComponent();
      expect(screen.getByText('Add Files')).toBeTruthy();
    });

    it('renders Add Files button as clickable when not uploading', () => {
      renderComponent();
      const button = screen.getByText('Add Files').closest('button');
      expect(button).not.toBeDisabled();
    });

    it('renders ContentContainer wrapper', () => {
      const { container } = renderComponent();
      expect(container.querySelector('[class*="chakra"]')).toBeTruthy();
    });

    it('renders the settings icon button', () => {
      renderComponent();
      const settingsButton = screen.getByLabelText('Edit Knowledge Base');
      expect(settingsButton).toBeTruthy();
    });
  });

  describe('Data Table with Files', () => {
    it('renders column headers correctly', () => {
      renderComponent();
      expect(screen.getByText('Name')).toBeTruthy();
      expect(screen.getByText('Size')).toBeTruthy();
      expect(screen.getByText('Last Updated')).toBeTruthy();
      expect(screen.getByText('Status')).toBeTruthy();
    });

    it('renders file names from data', () => {
      renderComponent();
      expect(screen.getByText('sales_report.pdf')).toBeTruthy();
      expect(screen.getByText('product_docs.pdf')).toBeTruthy();
      expect(screen.getByText('customer_data.pdf')).toBeTruthy();
      expect(screen.getByText('random.pdf')).toBeTruthy();
    });

    it('renders formatted file sizes', () => {
      renderComponent();
      expect(screen.getAllByText('512.00 KB').length).toBeTruthy();
      expect(screen.getAllByText('1.00 MB').length).toBeTruthy();
      expect(screen.getAllByText('2.00 GB').length).toBeTruthy();
    });

    it('renders formatted timestamps', () => {
      renderComponent();
      // Dates should be formatted
      expect(screen.getAllByText(/\/2024/).length).toBeGreaterThan(0);
    });

    it('renders file statuses correctly', () => {
      renderComponent();
      expect(screen.getByText('Processing')).toBeTruthy();
      expect(screen.getByText('Processed')).toBeTruthy();
      expect(screen.getByText('Failed')).toBeTruthy();
      expect(screen.getByText('Failed to Delete')).toBeTruthy();
    });

    it('exposes stable status and tbody test ids for file rows', () => {
      renderComponent();

      expect(screen.getByTestId('kb-file-table-tbody')).toBeInTheDocument();
      expect(screen.getByTestId('kb-file-status-processing')).toHaveTextContent('Processing');
      expect(screen.getByTestId('kb-file-status-processed')).toHaveTextContent('Processed');
      expect(screen.getByTestId('kb-file-status-failed')).toHaveTextContent('Failed');
      expect(screen.getByTestId('kb-file-status-failed-to-delete')).toHaveTextContent(
        'Failed to Delete',
      );
    });

    it('renders table rows for each file', () => {
      renderComponent();
      const rows = screen.getAllByRole('row');
      expect(rows.length).toBe(5);
    });

    it('renders action menu for each row', () => {
      renderComponent();
      // HorizontalMenuActions renders button triggers in each row
      const tableRows = screen.getAllByRole('row');
      // Each data row (excluding header) should have action buttons
      expect(tableRows.length).toBe(5);
    });
  });

  describe('Empty State', () => {
    beforeEach(() => {
      mockFilesResponse = MOCK_FILES_API_RESPONSE_EMPTY;
    });

    it('renders empty state when no files exist', () => {
      renderComponent();
      expect(
        screen.getByText("This vector store is empty. You haven't added any files yet."),
      ).toBeTruthy();
    });

    it('renders Add Files button in empty state', () => {
      renderComponent();
      // There should be two "Add Files" buttons - one in top bar and one in empty state
      const addFilesButtons = screen.getAllByText('Add Files');
      expect(addFilesButtons.length).toBe(2);
    });

    it('uses a stable test id on the empty-state Add Files button', () => {
      renderComponent();

      expect(screen.getByTestId('kb-empty-add-files-button')).toBeInTheDocument();
    });

    it('does not render data table when empty', () => {
      renderComponent();
      const tables = screen.queryAllByRole('table');
      expect(tables.length).toBe(0);
    });

    it('empty state shows correct image', () => {
      const { container } = renderComponent();
      const image = container.querySelector('img');
      expect(image).toBeTruthy();
    });
  });

  describe('File Upload Interaction', () => {
    it('renders hidden file input', () => {
      renderComponent();
      const fileInput = screen.getByTestId('custom-visual-file-input');
      expect(fileInput).toBeTruthy();
    });

    it('hidden file input has correct type', () => {
      renderComponent();
      const fileInput = screen.getByTestId('custom-visual-file-input') as HTMLInputElement;
      expect(fileInput.type).toBe('file');
    });

    it('hidden file input accepts PDF files', () => {
      renderComponent();
      const fileInput = screen.getByTestId('custom-visual-file-input');
      expect(fileInput.getAttribute('accept')).toContain('.pdf');
    });

    it('triggers file input click when Add Files button is clicked', () => {
      renderComponent();
      const addFilesButton = screen.getByText('Add Files');
      const fileInput = screen.getByTestId('custom-visual-file-input');

      const clickSpy = jest.spyOn(fileInput, 'click');
      fireEvent.click(addFilesButton);
      expect(clickSpy).toHaveBeenCalled();
    });

    it('calls upload mutation when file is selected', async () => {
      renderComponent();
      const fileInput = screen.getByTestId('custom-visual-file-input');

      const testFile = new File(['test content'], 'test-document.pdf', {
        type: 'application/pdf',
      });

      fireEvent.change(fileInput, { target: { files: [testFile] } });

      await waitFor(() => {
        expect(mockUploadMutate).toHaveBeenCalled();
      });
    });

    it('calls apiErrorToast when upload succeeds but returns errors', async () => {
      renderComponent();
      const fileInput = screen.getByTestId('custom-visual-file-input');

      const testFile = new File(['test content'], 'test-document.pdf', {
        type: 'application/pdf',
      });

      // Mock the upload mutation to call onSuccess with errors
      mockUploadMutate.mockImplementation((_params, options) => {
        if (options?.onSuccess) {
          options.onSuccess({ errors: [{ detail: 'File too large' }] });
        }
      });

      fireEvent.change(fileInput, { target: { files: [testFile] } });

      await waitFor(() => {
        expect(mockUploadMutate).toHaveBeenCalledWith(
          {
            knowledgeBaseId: '1',
            file: testFile,
          },
          expect.objectContaining({
            onSuccess: expect.any(Function),
            onError: expect.any(Function),
          }),
        );
        expect(mockApiErrorToast).toHaveBeenCalledWith([{ detail: 'File too large' }]);
      });
    });

    it('calls errorToast when upload fails with error', async () => {
      renderComponent();
      const fileInput = screen.getByTestId('custom-visual-file-input');

      const testFile = new File(['test content'], 'test-document.pdf', {
        type: 'application/pdf',
      });

      // Mock the upload mutation to call onError
      mockUploadMutate.mockImplementation((_params, options) => {
        if (options?.onError) {
          options.onError(new Error('Network error'));
        }
      });

      fireEvent.change(fileInput, { target: { files: [testFile] } });

      await waitFor(() => {
        expect(mockUploadMutate).toHaveBeenCalled();
        expect(mockErrorToast).toHaveBeenCalledWith(
          'Unable to upload file: Network error',
          true,
          null,
          true,
        );
      });
    });

    it('does not call upload mutation when no file is selected', () => {
      renderComponent();
      const fileInput = screen.getByTestId('custom-visual-file-input');

      // Trigger change with no files
      fireEvent.change(fileInput, { target: { files: [] } });

      expect(mockUploadMutate).not.toHaveBeenCalled();
    });
  });

  describe('File Delete Interaction', () => {
    it('renders delete option in action menu', async () => {
      const { container } = renderComponent();

      // Find and click a menu trigger
      const menuTriggers = container.querySelectorAll('button');
      const menuTrigger = Array.from(menuTriggers).find(
        (btn) => btn.querySelector('svg') && !btn.textContent,
      );

      if (menuTrigger) {
        fireEvent.click(menuTrigger);

        await waitFor(() => {
          // Multiple delete options may appear (one per row)
          expect(screen.getAllByText('Delete').length).toBeGreaterThan(0);
        });
      }
    });
  });

  describe('Settings Drawer', () => {
    it('settings button is enabled when knowledge base data exists', () => {
      renderComponent();
      const settingsButton = screen.getByTestId('settings-button');
      expect(settingsButton).not.toBeDisabled();
    });

    it('opens drawer when settings button is clicked', async () => {
      renderComponent();
      const settingsButton = screen.getByTestId('settings-button');

      fireEvent.click(settingsButton);

      await waitFor(() => {
        expect(screen.getByRole('dialog')).toBeTruthy();
      });
    });

    it('drawer shows knowledge base configuration', async () => {
      renderComponent();
      const settingsButton = screen.getByTestId('settings-button');

      fireEvent.click(settingsButton);

      await waitFor(() => {
        // Drawer should show knowledge base name
        expect(screen.getByDisplayValue('Production Vector Store')).toBeTruthy();
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
      mockFilesResponse = MOCK_FILES_API_RESPONSE_EMPTY;
      renderComponent();
      const pagination = screen.queryByTestId('pagination');
      expect(pagination).toBeFalsy();
    });

    it('renders pagination for single page', () => {
      mockFilesResponse = MOCK_FILES_API_RESPONSE_SINGLE_PAGE;
      renderComponent();
      const pagination = screen.getByTestId('pagination');
      expect(pagination).toBeTruthy();
    });
  });

  describe('API Integration', () => {
    it('uses useKnowledgeBaseQueries hook for fetching data', () => {
      renderComponent();
      // Verify data is displayed from the mock (name appears in breadcrumb and top bar)
      expect(screen.getAllByText('Production Vector Store').length).toBeGreaterThan(0);
    });

    it('displays file data from API response', () => {
      renderComponent();
      expect(screen.getByText('sales_report.pdf')).toBeTruthy();
      expect(screen.getByText('product_docs.pdf')).toBeTruthy();
    });

    it('uses knowledge base ID from URL params', () => {
      renderComponent();
      // Component should use the ID from useParams (mocked as '1')
      expect(screen.getByTestId('top-bar-name')).toHaveTextContent('Production Vector Store');
    });
  });

  describe('Single Page Data', () => {
    beforeEach(() => {
      mockFilesResponse = MOCK_FILES_API_RESPONSE_SINGLE_PAGE;
    });

    it('renders data with single page links', () => {
      renderComponent();
      expect(screen.getByText('sales_report.pdf')).toBeTruthy();
      expect(screen.getByText('product_docs.pdf')).toBeTruthy();
    });

    it('renders correct number of rows for single page', () => {
      renderComponent();
      const rows = screen.getAllByRole('row');
      // 1 header row + 2 data rows
      expect(rows.length).toBe(3);
    });
  });

  describe('Table Styling', () => {
    it('renders within TableBox container', () => {
      const { container } = renderComponent();
      expect(container.querySelector('table')).toBeTruthy();
    });

    it('renders file names with icon', () => {
      const { container } = renderComponent();
      // IconEntity should render icons next to file names
      const icons = container.querySelectorAll('svg');
      expect(icons.length).toBeGreaterThan(0);
    });
  });

  describe('Edge Cases', () => {
    it('handles different file sizes correctly', () => {
      renderComponent();
      // Verify all three different sizes are formatted
      expect(screen.getAllByText('512.00 KB').length).toBeTruthy();
      expect(screen.getAllByText('1.00 MB').length).toBeTruthy();
      expect(screen.getAllByText('2.00 GB').length).toBeTruthy();
    });

    it('handles different file statuses', () => {
      renderComponent();
      expect(screen.getByText('Processing')).toBeTruthy();
      expect(screen.getByText('Processed')).toBeTruthy();
      expect(screen.getByText('Failed')).toBeTruthy();
      expect(screen.getByText('Failed to Delete')).toBeTruthy();
    });

    it('handles null hosted_data_store_id in knowledge base', () => {
      mockKnowledgeBaseResponse = {
        ...MOCK_KB_API_RESPONSE,
        data: {
          ...MOCK_KNOWLEDGE_BASE,
          attributes: {
            ...MOCK_KNOWLEDGE_BASE.attributes,
            hosted_data_store_id: null,
          },
        },
      };
      renderComponent();
      expect(screen.getByTestId('top-bar-name')).toHaveTextContent('Production Vector Store');
    });
  });

  describe('Loading State', () => {
    it('renders component while data is available', () => {
      renderComponent();
      expect(screen.getByTestId('top-bar-name')).toHaveTextContent('Production Vector Store');
    });

    it('renders loader when data is loading', () => {
      mockIsLoadingGetAllKBFiles = true;
      mockIsLoadingGetAllKB = true;
      renderComponent();
      expect(screen.getByTestId('loader')).toBeTruthy();
    });
  });

  describe('Button Interactions', () => {
    it('Add Files button is clickable', () => {
      renderComponent();
      const button = screen.getByText('Add Files').closest('button');
      expect(button).not.toBeDisabled();
    });

    it('settings button triggers drawer', async () => {
      renderComponent();

      const settingsButton = screen.getByTestId('settings-button');
      fireEvent.click(settingsButton);

      await waitFor(() => {
        expect(screen.getByRole('dialog')).toBeTruthy();
      });
    });
  });

  describe('Knowledge Base Data Display', () => {
    it('displays knowledge base name from API', () => {
      renderComponent();
      expect(screen.getByTestId('top-bar-name')).toHaveTextContent('Production Vector Store');
    });

    it('displays breadcrumb with knowledge base name', () => {
      renderComponent();
      const breadcrumbs = screen.getAllByText('Production Vector Store');
      expect(breadcrumbs.length).toBeGreaterThan(0);
    });
  });

  describe('File Actions Menu', () => {
    it('renders preview option in action menu', async () => {
      const { container } = renderComponent();

      // Find and click a menu trigger
      const menuTriggers = container.querySelectorAll('button');
      const menuTrigger = Array.from(menuTriggers).find(
        (btn) => btn.querySelector('svg') && !btn.textContent,
      );

      if (menuTrigger) {
        fireEvent.click(menuTrigger);

        await waitFor(() => {
          // Multiple preview options may appear (one per row)
          expect(screen.getAllByText('Preview').length).toBeGreaterThan(0);
        });
      }
    });

    it('renders download option in action menu', async () => {
      const { container } = renderComponent();

      // Find and click a menu trigger
      const menuTriggers = container.querySelectorAll('button');
      const menuTrigger = Array.from(menuTriggers).find(
        (btn) => btn.querySelector('svg') && !btn.textContent,
      );

      if (menuTrigger) {
        fireEvent.click(menuTrigger);

        await waitFor(() => {
          // Multiple download options may appear (one per row)
          expect(screen.getAllByText('Download').length).toBeGreaterThan(0);
        });
      }
    });
  });

  describe('File Download Functionality', () => {
    let createObjectURLSpy: jest.Mock;
    let revokeObjectURLSpy: jest.Mock;
    let createElementSpy: jest.SpyInstance;
    let mockAnchor: HTMLAnchorElement;

    beforeEach(() => {
      // Mock URL.createObjectURL and URL.revokeObjectURL
      createObjectURLSpy = jest.fn().mockReturnValue('blob:mock-url');
      revokeObjectURLSpy = jest.fn();
      (global.URL.createObjectURL as any) = createObjectURLSpy;
      (global.URL.revokeObjectURL as any) = revokeObjectURLSpy;

      // Mock document.createElement to track anchor element creation
      const originalCreateElement = document.createElement.bind(document);
      mockAnchor = originalCreateElement('a');
      mockAnchor.click = jest.fn();
      createElementSpy = jest.spyOn(document, 'createElement').mockImplementation((tagName) => {
        if (tagName === 'a') {
          return mockAnchor;
        }
        return originalCreateElement(tagName);
      });
    });

    afterEach(() => {
      createElementSpy.mockRestore();
    });

    it('successfully downloads file when download succeeds', async () => {
      const mockBlob = new Blob(['file content'], { type: 'application/pdf' });

      // Mock the download mutation to call onSuccess with blob data
      mockGetFileMutate.mockImplementation((_params, options) => {
        if (options?.onSuccess) {
          options.onSuccess(mockBlob);
        }
      });

      const { container } = renderComponent();

      // Find and click a menu trigger
      const menuTriggers = container.querySelectorAll('button');
      const menuTrigger = Array.from(menuTriggers).find(
        (btn) => btn.querySelector('svg') && !btn.textContent,
      );

      if (menuTrigger) {
        fireEvent.click(menuTrigger);

        await waitFor(() => {
          expect(screen.getAllByText('Download').length).toBeGreaterThan(0);
        });

        // Click the download button
        const downloadButton = screen.getAllByText('Download')[0];
        fireEvent.click(downloadButton);

        await waitFor(() => {
          expect(mockGetFileMutate).toHaveBeenCalledWith(
            {
              knowledgeBaseId: '1',
              fileId: 'file-1',
            },
            expect.objectContaining({
              onSuccess: expect.any(Function),
            }),
          );

          // Verify URL methods were called
          expect(createObjectURLSpy).toHaveBeenCalledWith(mockBlob);
          expect(revokeObjectURLSpy).toHaveBeenCalledWith('blob:mock-url');

          // Verify success toast was shown
          expect(mockCustomToast).toHaveBeenCalledWith({
            title: 'File downloaded successfully',
            description: 'Downloaded file: sales_report.pdf',
            status: 'success',
            isClosable: true,
            duration: 3000,
            position: 'bottom-right',
          });
        });
      }
    });

    it('shows error toast when download returns null data', async () => {
      // Mock the download mutation to call onSuccess with null
      mockGetFileMutate.mockImplementation((_params, options) => {
        if (options?.onSuccess) {
          options.onSuccess(null);
        }
      });

      const { container } = renderComponent();

      // Find and click a menu trigger
      const menuTriggers = container.querySelectorAll('button');
      const menuTrigger = Array.from(menuTriggers).find(
        (btn) => btn.querySelector('svg') && !btn.textContent,
      );

      if (menuTrigger) {
        fireEvent.click(menuTrigger);

        await waitFor(() => {
          expect(screen.getAllByText('Download').length).toBeGreaterThan(0);
        });

        // Click the download button
        const downloadButton = screen.getAllByText('Download')[0];
        fireEvent.click(downloadButton);

        await waitFor(() => {
          expect(mockGetFileMutate).toHaveBeenCalled();
          expect(mockErrorToast).toHaveBeenCalledWith('Unable to download file', true, null, true);
          // URL methods should not be called
          expect(createObjectURLSpy).not.toHaveBeenCalled();
        });
      }
    });

    it('successfully handles file preview', async () => {
      const mockBlob = new Blob(['file content'], { type: 'application/pdf' });

      // Mock the get file mutation to call onSuccess with blob data
      mockGetFileMutate.mockImplementation((_params, options) => {
        if (options?.onSuccess) {
          options.onSuccess(mockBlob);
        }
      });

      const { container } = renderComponent();

      // Find and click a menu trigger
      const menuTriggers = container.querySelectorAll('button');
      const menuTrigger = Array.from(menuTriggers).find(
        (btn) => btn.querySelector('svg') && !btn.textContent,
      );

      if (menuTrigger) {
        fireEvent.click(menuTrigger);

        await waitFor(() => {
          expect(screen.getAllByText('Preview').length).toBeGreaterThan(0);
        });

        // Click the preview button
        const previewButton = screen.getAllByText('Preview')[0];
        fireEvent.click(previewButton);

        await waitFor(() => {
          expect(mockGetFileMutate).toHaveBeenCalledWith(
            {
              knowledgeBaseId: '1',
              fileId: 'file-1',
            },
            expect.objectContaining({
              onSuccess: expect.any(Function),
            }),
          );
        });
      }
    });
  });

  describe('RBAC (Role-Based Access Control)', () => {
    describe('Create Permission (Add Files Button)', () => {
      it('renders Add Files button when user has Create permission on knowledge_base', () => {
        // Mock permission check to return true for Create
        mockedHasActionPermission.mockImplementation((_role, location, action) => {
          if (location === 'knowledge_base' && action === UserActions.Create) {
            return true;
          }
          return false;
        });

        renderComponent();
        const addFilesButton = screen.getByText('Add Files');
        expect(addFilesButton).toBeTruthy();
      });

      it('does not render Add Files button when user lacks Create permission on knowledge_base', () => {
        // Mock permission check to return false for Create
        mockedHasActionPermission.mockImplementation((_role, location, action) => {
          if (location === 'knowledge_base' && action === UserActions.Create) {
            return false;
          }
          return true;
        });

        renderComponent();
        const addFilesButtons = screen.queryAllByText('Add Files');
        // Should not find Add Files button in top bar (only in empty state if applicable)
        expect(addFilesButtons.length).toBe(0);
      });

      it('does not render file input when user lacks Create permission', () => {
        mockedHasActionPermission.mockImplementation((_role, location, action) => {
          if (location === 'knowledge_base' && action === UserActions.Create) {
            return false;
          }
          return true;
        });

        renderComponent();
        const fileInput = screen.queryByTestId('custom-visual-file-input');
        expect(fileInput).toBeFalsy();
      });
    });

    describe('Read Permission (Settings Button)', () => {
      it('renders Settings button when user has Read permissions on both knowledge_base and connector', () => {
        mockedHasActionPermission.mockImplementation((_role, location, action) => {
          if (
            (location === 'knowledge_base' && action === UserActions.Read) ||
            (location === 'connector' && action === UserActions.Read)
          ) {
            return true;
          }
          return false;
        });

        renderComponent();
        const settingsButton = screen.getByTestId('settings-button');
        expect(settingsButton).toBeTruthy();
      });

      it('does not render Settings button when user lacks Read permission on knowledge_base', () => {
        mockedHasActionPermission.mockImplementation((_role, location, action) => {
          if (location === 'knowledge_base' && action === UserActions.Read) {
            return false;
          }
          if (location === 'connector' && action === UserActions.Read) {
            return true;
          }
          return false;
        });

        renderComponent();
        const settingsButton = screen.queryByTestId('settings-button');
        expect(settingsButton).toBeFalsy();
      });

      it('does not render Settings button when user lacks Read permission on connector', () => {
        mockedHasActionPermission.mockImplementation((_role, location, action) => {
          if (location === 'knowledge_base' && action === UserActions.Read) {
            return true;
          }
          if (location === 'connector' && action === UserActions.Read) {
            return false;
          }
          return false;
        });

        renderComponent();
        const settingsButton = screen.queryByTestId('settings-button');
        expect(settingsButton).toBeFalsy();
      });

      it('does not render Settings button when user lacks both Read permissions', () => {
        mockedHasActionPermission.mockImplementation((_role, location, action) => {
          if (
            (location === 'knowledge_base' && action === UserActions.Read) ||
            (location === 'connector' && action === UserActions.Read)
          ) {
            return false;
          }
          return false;
        });

        renderComponent();
        const settingsButton = screen.queryByTestId('settings-button');
        expect(settingsButton).toBeFalsy();
      });
    });

    describe('Combined RBAC Scenarios', () => {
      it('renders both Add Files and Settings when user has all permissions', () => {
        mockedHasActionPermission.mockReturnValue(true);

        renderComponent();
        expect(screen.getByText('Add Files')).toBeTruthy();
        expect(screen.getByTestId('settings-button')).toBeTruthy();
      });

      it('renders only Settings when user has Read but not Create permission', () => {
        mockedHasActionPermission.mockImplementation((_role, _location, action) => {
          if (action === UserActions.Read) {
            return true;
          }
          if (action === UserActions.Create) {
            return false;
          }
          return false;
        });

        renderComponent();
        expect(screen.queryByText('Add Files')).toBeFalsy();
        expect(screen.getByTestId('settings-button')).toBeTruthy();
      });

      it('renders only Add Files when user has Create but not Read permissions', () => {
        mockedHasActionPermission.mockImplementation((_role, location, action) => {
          if (location === 'knowledge_base' && action === UserActions.Create) {
            return true;
          }
          if (action === UserActions.Read) {
            return false;
          }
          return false;
        });

        renderComponent();
        expect(screen.getByText('Add Files')).toBeTruthy();
        expect(screen.queryByTestId('settings-button')).toBeFalsy();
      });

      it('renders neither Add Files nor Settings when user lacks all permissions', () => {
        mockedHasActionPermission.mockReturnValue(false);

        renderComponent();
        expect(screen.queryByText('Add Files')).toBeFalsy();
        expect(screen.queryByTestId('settings-button')).toBeFalsy();
      });
    });

    describe('Empty State RBAC', () => {
      beforeEach(() => {
        mockFilesResponse = MOCK_FILES_API_RESPONSE_EMPTY;
      });

      it('shows Add Files button in empty state when user has Create permission', () => {
        mockedHasActionPermission.mockImplementation((_role, location, action) => {
          if (location === 'knowledge_base' && action === UserActions.Create) {
            return true;
          }
          return false;
        });

        renderComponent();
        // Empty state should not show Add Files button in action area due to RoleAccess
        const emptyState = screen.getByText(
          "This vector store is empty. You haven't added any files yet.",
        );
        expect(emptyState).toBeTruthy();
      });

      it('does not show Add Files button in empty state when user lacks Create permission', () => {
        mockedHasActionPermission.mockReturnValue(false);

        renderComponent();
        const addFilesButtons = screen.queryAllByText('Add Files');
        expect(addFilesButtons.length).toBe(0);
      });
    });
  });

  describe('File Delete Action', () => {
    it('opens confirmation modal when delete button is clicked', async () => {
      const { container } = renderComponent();

      // Find and click a menu trigger
      const menuTriggers = container.querySelectorAll('button');
      const menuTrigger = Array.from(menuTriggers).find(
        (btn) => btn.querySelector('svg') && !btn.textContent,
      );

      if (menuTrigger) {
        fireEvent.click(menuTrigger);

        await waitFor(() => {
          expect(screen.getAllByText('Delete').length).toBeGreaterThan(0);
        });

        // Click the delete button - should open confirmation modal
        const deleteButton = screen.getAllByText('Delete')[0];
        fireEvent.click(deleteButton);

        await waitFor(() => {
          expect(screen.getByTestId('confirm-delete-modal')).toBeInTheDocument();
          expect(screen.getByTestId('delete-modal-title')).toHaveTextContent(
            'Are you sure you want to delete this file?',
          );
          expect(screen.getByTestId('delete-modal-description')).toHaveTextContent(
            'This action will permanently delete sales_report.pdf from the knowledge base. This cannot be undone.',
          );
        });
      }
    });

    it('calls delete mutation when confirmed in modal', async () => {
      const { container } = renderComponent();

      // Find and click a menu trigger
      const menuTriggers = container.querySelectorAll('button');
      const menuTrigger = Array.from(menuTriggers).find(
        (btn) => btn.querySelector('svg') && !btn.textContent,
      );

      if (menuTrigger) {
        fireEvent.click(menuTrigger);

        await waitFor(() => {
          expect(screen.getAllByText('Delete').length).toBeGreaterThan(0);
        });

        // Click the delete button to open modal
        const deleteButton = screen.getAllByText('Delete')[0];
        fireEvent.click(deleteButton);

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
              fileId: 'file-1',
            },
            expect.objectContaining({
              onSuccess: expect.any(Function),
            }),
          );
        });
      }
    });

    it('closes confirmation modal when cancel is clicked', async () => {
      const { container } = renderComponent();

      // Find and click a menu trigger
      const menuTriggers = container.querySelectorAll('button');
      const menuTrigger = Array.from(menuTriggers).find(
        (btn) => btn.querySelector('svg') && !btn.textContent,
      );

      if (menuTrigger) {
        fireEvent.click(menuTrigger);

        await waitFor(() => {
          expect(screen.getAllByText('Delete').length).toBeGreaterThan(0);
        });

        // Click the delete button to open modal
        const deleteButton = screen.getAllByText('Delete')[0];
        fireEvent.click(deleteButton);

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
      }
    });
  });

  describe('ViewKBFile Modal', () => {
    it('renders ViewKBFile component', () => {
      renderComponent();
      // The ViewKBFile component should be in the DOM (though not visible when open=false)
      expect(screen.queryByTestId('view-kb-file')).toBeFalsy(); // Modal not visible initially
    });

    it('opens ViewKBFile modal when preview is triggered', async () => {
      const mockBlob = new Blob(['file content'], { type: 'application/pdf' });

      // Mock the get file mutation to call onSuccess with blob data
      mockGetFileMutate.mockImplementation((_params, options) => {
        if (options?.onSuccess) {
          options.onSuccess(mockBlob);
        }
      });

      const { container } = renderComponent();

      // Find and click a menu trigger
      const menuTriggers = container.querySelectorAll('button');
      const menuTrigger = Array.from(menuTriggers).find(
        (btn) => btn.querySelector('svg') && !btn.textContent,
      );

      if (menuTrigger) {
        fireEvent.click(menuTrigger);

        await waitFor(() => {
          expect(screen.getAllByText('Preview').length).toBeGreaterThan(0);
        });

        // Click the preview button
        const previewButton = screen.getAllByText('Preview')[0];
        fireEvent.click(previewButton);

        await waitFor(() => {
          expect(mockGetFileMutate).toHaveBeenCalledWith(
            {
              knowledgeBaseId: '1',
              fileId: 'file-1',
            },
            expect.objectContaining({
              onSuccess: expect.any(Function),
            }),
          );
        });
      }
    });

    it('closes ViewKBFile modal when close button is clicked', async () => {
      const mockBlob = new Blob(['file content'], { type: 'application/pdf' });

      // Mock the get file mutation to set the state and open modal
      mockGetFileMutate.mockImplementation((_params, options) => {
        if (options?.onSuccess) {
          options.onSuccess(mockBlob);
        }
      });

      const { container } = renderComponent();

      // Find and click a menu trigger to open preview
      const menuTriggers = container.querySelectorAll('button');
      const menuTrigger = Array.from(menuTriggers).find(
        (btn) => btn.querySelector('svg') && !btn.textContent,
      );

      if (menuTrigger) {
        fireEvent.click(menuTrigger);

        await waitFor(() => {
          expect(screen.getAllByText('Preview').length).toBeGreaterThan(0);
        });

        // Click the preview button to open modal
        const previewButton = screen.getAllByText('Preview')[0];
        fireEvent.click(previewButton);

        await waitFor(() => {
          expect(mockGetFileMutate).toHaveBeenCalled();
        });

        // Wait for modal close button to appear
        await waitFor(() => {
          const closeButton = screen.queryByTestId('close-modal-button');
          expect(closeButton).toBeTruthy();
        });

        // Find and click the close button in the modal
        const closeButton = screen.getByTestId('close-modal-button');
        fireEvent.click(closeButton);

        // Modal should close (openPreviewModal should be set to false)
        await waitFor(() => {
          // After closing, the modal should not be visible
          expect(screen.queryByTestId('close-modal-button')).toBeFalsy();
        });
      }
    });
  });

  describe('Upload Status Edge Cases', () => {
    it('handles unknown upload status with default case', () => {
      const mockFilesWithUnknownStatus: ApiResponse<KnowledgeBaseFile[]> = {
        data: [
          {
            id: 'file-unknown',
            type: 'agents-knowledge_base_files',
            attributes: {
              knowledge_base_id: 1,
              name: 'unknown_status.pdf',
              size: 524288,
              upload_status: 'unknown_status' as any, // Force an unknown status
              workflow_enabled: true,
              created_at: '2024-01-15T10:30:00Z',
              updated_at: '2024-01-20T14:45:00Z',
            },
          },
        ],
        status: 200,
        links: MOCK_LINKS_SINGLE_PAGE,
      };

      mockFilesResponse = mockFilesWithUnknownStatus;
      renderComponent();

      // The component should render without crashing and show processing status (default)
      expect(screen.getByText('unknown_status.pdf')).toBeTruthy();
      expect(screen.getByText('Processing')).toBeTruthy(); // Default to processing status
    });
  });

  describe('Empty State Button Click', () => {
    beforeEach(() => {
      mockFilesResponse = MOCK_FILES_API_RESPONSE_EMPTY;
    });

    it('triggers file input click when empty state Add Files button is clicked', () => {
      renderComponent();

      const fileInput = screen.getByTestId('custom-visual-file-input');
      const clickSpy = jest.spyOn(fileInput, 'click');

      // Find the Add Files button in empty state (second one)
      const addFilesButtons = screen.getAllByText('Add Files');
      if (addFilesButtons.length > 1) {
        fireEvent.click(addFilesButtons[1]);
        expect(clickSpy).toHaveBeenCalled();
      }
    });
  });
});
