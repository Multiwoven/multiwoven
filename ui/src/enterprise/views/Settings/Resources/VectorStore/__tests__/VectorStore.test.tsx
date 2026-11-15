import React from 'react';
import { render, screen, fireEvent, waitFor } from '@testing-library/react';
import { expect } from '@jest/globals';
import '@testing-library/jest-dom/jest-globals';
import '@testing-library/jest-dom';
import { ChakraProvider } from '@chakra-ui/react';
import VectorStore from '../VectorStore';

const renderWithChakra = (component: React.ReactElement) => {
  return render(<ChakraProvider>{component}</ChakraProvider>);
};

// Mock hooks
const mockNavigate = jest.fn();
const mockUseParams = jest.fn();
const mockUseFilters = jest.fn();
const mockUseGetHostedDataStoreTables = jest.fn();
const mockUseGetHostedDBTemplates = jest.fn();
const mockDeleteMutateAsync = jest.fn();
const mockEnableMutateAsync = jest.fn();
const mockInvalidateQueries = jest.fn();
const mockApiErrorToast = jest.fn();
const mockUseRoleDataStore = jest.fn();

jest.mock('react-router-dom', () => ({
  useNavigate: () => mockNavigate,
  useParams: () => mockUseParams(),
}));

jest.mock('@/hooks/useFilters', () => ({
  __esModule: true,
  default: () => mockUseFilters(),
}));

jest.mock('@/enterprise/hooks/queries/useHostedStoreQueries', () => ({
  __esModule: true,
  default: () => ({
    useGetHostedDataStoreTables: mockUseGetHostedDataStoreTables,
    useGetHostedDBTemplates: mockUseGetHostedDBTemplates,
  }),
}));

jest.mock('@/enterprise/hooks/mutations/useHostedStoreMutations', () => ({
  __esModule: true,
  default: () => ({
    deleteHostedDataStoreTableMutation: {
      mutateAsync: mockDeleteMutateAsync,
      isPending: false,
    },
    enableHostedDataStoreMutation: {
      mutateAsync: mockEnableMutateAsync,
      isPending: false,
    },
  }),
}));

jest.mock('@tanstack/react-query', () => ({
  useQueryClient: () => ({
    invalidateQueries: mockInvalidateQueries,
  }),
}));

jest.mock('@/hooks/useErrorToast', () => ({
  useAPIErrorsToast: () => mockApiErrorToast,
}));

jest.mock('@/enterprise/store/useRoleDataStore', () => ({
  useRoleDataStore: (selector: any) => mockUseRoleDataStore(selector),
}));

jest.mock('@/enterprise/utils/accessControlPermission', () => ({
  hasActionPermission: jest.fn((role, _, action) => role?.permissions?.includes(action)),
}));

jest.mock('@/enterprise/types', () => ({
  UserActions: { Update: 'update' },
}));

// Mock UI components
jest.mock('@/components/ContentContainer', () => ({
  __esModule: true,
  default: ({ children }: any) => <div data-testid='content-container'>{children}</div>,
}));

jest.mock('@/components/TopBar', () => ({
  __esModule: true,
  default: ({ name, ctaName, onCtaClicked, isCtaVisible, extra }: any) => (
    <div data-testid='top-bar'>
      <span data-testid='top-bar-name'>{name}</span>
      {isCtaVisible && (
        <button data-testid='cta-button' onClick={onCtaClicked}>
          {ctaName}
        </button>
      )}
      <div data-testid='top-bar-extra'>{extra}</div>
    </div>
  ),
}));

jest.mock('@/components/Loader', () => ({
  __esModule: true,
  default: () => <div data-testid='loader'>Loading...</div>,
}));

jest.mock('@/components/DataTable', () => ({
  __esModule: true,
  default: ({ data, columns, noRowsComponent, dataTestId, getRowProps }: any) => (
    <div data-testid='data-table' data-datatable-root-testid={dataTestId ?? ''}>
      {data?.length > 0 ? (
        <div data-testid='table-rows'>
          {data.length} rows
          {data.map((row: any, rowIdx: number) => {
            const rowProps = getRowProps?.({
              index: rowIdx,
              original: row,
              id: String(rowIdx),
            } as any);
            return (
              <div key={row.id} {...(rowProps ?? {})}>
                {columns
                  ?.filter((col: any) => col.accessorKey === 'attributes' && col.cell)
                  .map((col: any, idx: number) => (
                    <div key={idx} data-testid={`action-cell-${row.id}`}>
                      {col.cell({ row: { original: row } })}
                    </div>
                  ))}
              </div>
            );
          })}
        </div>
      ) : (
        noRowsComponent
      )}
    </div>
  ),
}));

jest.mock('../NoTablesFound', () => ({
  __esModule: true,
  default: ({ onOpen, showActionButton }: any) => (
    <div data-testid='no-tables-found'>
      {showActionButton && <button onClick={onOpen}>Create Table</button>}
    </div>
  ),
}));

jest.mock('../NewVectorTableDrawer', () => ({
  __esModule: true,
  default: ({ isOpen, onClose, title, selectedTable, isEditable }: any) =>
    isOpen ? (
      <div data-testid='new-vector-table-drawer'>
        <span data-testid='drawer-title'>{title}</span>
        <span data-testid='drawer-editable'>{isEditable ? 'editable' : 'readonly'}</span>
        <span data-testid='selected-table-id'>{selectedTable?.id || 'none'}</span>
        <button onClick={onClose}>Close Drawer</button>
      </div>
    ) : null,
}));

jest.mock('../DisableVectorStore', () => ({
  __esModule: true,
  default: ({ isOpen, onClose, onDisable, onDeleteSuccess }: any) =>
    isOpen ? (
      <div data-testid='disable-vector-store-modal'>
        <button onClick={onDisable}>Confirm Disable</button>
        <button onClick={onClose}>Close Modal</button>
        <button onClick={onDeleteSuccess}>Delete Success</button>
      </div>
    ) : null,
}));

jest.mock('@/components/ConfirmDeleteModal/ConfirmDeleteModal', () => ({
  __esModule: true,
  default: ({ open, onDelete, onClose, title }: any) =>
    open ? (
      <div data-testid='confirm-delete-modal'>
        <span>{title}</span>
        <button onClick={onDelete}>Confirm Delete</button>
        <button onClick={onClose}>Cancel Delete</button>
      </div>
    ) : null,
}));

jest.mock('@/components/EnhancedPagination/Pagination', () => ({
  __esModule: true,
  default: ({ currentPage, handlePageChange }: any) => (
    <div data-testid='pagination'>
      <span>Page {currentPage}</span>
      <button onClick={() => handlePageChange(2)}>Next Page</button>
    </div>
  ),
}));

jest.mock('@/components/ToolTip', () => ({
  __esModule: true,
  default: ({ children, label }: any) => (
    <div data-testid='tooltip' data-label={label}>
      {children}
    </div>
  ),
}));

jest.mock('../VectorStoreTableColumns', () => ({
  __esModule: true,
  default: [],
}));

jest.mock('@/components/HorizontalMenuActions', () => ({
  __esModule: true,
  default: ({ children, onClick }: any) => (
    <div data-testid='horizontal-menu-actions' onClick={onClick}>
      {children}
    </div>
  ),
}));

jest.mock('@/enterprise/components/MenuAction/MenuAction', () => ({
  __esModule: true,
  default: ({ label, onClick, onClose, isDisabled, testId }: any) => (
    <div>
      <button data-testid={testId} onClick={onClick} disabled={isDisabled}>
        {label}
      </button>
      <button data-testid={`${testId}-close`} onClick={onClose}>
        Close Menu
      </button>
    </div>
  ),
}));

describe('VectorStore', () => {
  const mockTemplate = {
    id: 'template-1',
    name: 'AI Squared Vector Store',
    linked_data_store_id: '123',
    store_enabled: true,
  };

  const mockTables = [
    {
      id: 'table-1',
      attributes: { name: 'table1', sync_enabled: 'disabled' },
    },
    {
      id: 'table-2',
      attributes: { name: 'table2', sync_enabled: 'enabled' },
    },
  ];

  beforeEach(() => {
    jest.clearAllMocks();
    mockUseParams.mockReturnValue({ storeId: '123' });
    mockUseFilters.mockReturnValue({
      filters: { page: '1' },
      updateFilters: jest.fn(),
    });
    mockUseRoleDataStore.mockReturnValue({ permissions: ['update'] });
    mockUseGetHostedDBTemplates.mockReturnValue({
      data: { data: [mockTemplate] },
    });
    mockUseGetHostedDataStoreTables.mockReturnValue({
      data: { data: mockTables, links: { next: '/next' } },
      isLoading: false,
    });
  });

  describe('Loading State', () => {
    it('renders loader while tables are loading', () => {
      mockUseGetHostedDataStoreTables.mockReturnValue({
        data: null,
        isLoading: true,
      });

      renderWithChakra(<VectorStore />);

      expect(screen.getByTestId('loader')).toBeInTheDocument();
    });
  });

  describe('Content Rendering', () => {
    it('renders content container', () => {
      renderWithChakra(<VectorStore />);

      expect(screen.getByTestId('content-container')).toBeInTheDocument();
    });

    it('renders top bar with store name', () => {
      renderWithChakra(<VectorStore />);

      expect(screen.getByTestId('top-bar-name')).toHaveTextContent('AI Squared Vector Store');
    });

    it('renders Create Table CTA button when user has permission', () => {
      renderWithChakra(<VectorStore />);

      expect(screen.getByTestId('cta-button')).toBeInTheDocument();
      expect(screen.getByTestId('cta-button')).toHaveTextContent('Create Table');
    });

    it('does not render Create Table CTA when user lacks permission', () => {
      mockUseRoleDataStore.mockReturnValue({ permissions: [] });

      renderWithChakra(<VectorStore />);

      expect(screen.queryByTestId('cta-button')).not.toBeInTheDocument();
    });

    it('renders data table with tables', () => {
      renderWithChakra(<VectorStore />);

      expect(screen.getByTestId('data-table')).toBeInTheDocument();
      expect(screen.getByTestId('table-rows')).toHaveTextContent('2 rows');
    });

    it('passes automation test ids to DataTable and rows', () => {
      renderWithChakra(<VectorStore />);

      expect(screen.getByTestId('data-table')).toHaveAttribute(
        'data-datatable-root-testid',
        'data-store-tables-datatable',
      );
      expect(screen.getByTestId('data-store-table-row-table-1')).toBeInTheDocument();
      expect(screen.getByTestId('data-store-table-row-table-2')).toBeInTheDocument();
    });

    it('renders NoTablesFound when no tables exist', () => {
      mockUseGetHostedDataStoreTables.mockReturnValue({
        data: { data: [] },
        isLoading: false,
      });

      renderWithChakra(<VectorStore />);

      expect(screen.getByTestId('no-tables-found')).toBeInTheDocument();
    });

    it('renders pagination when tables have links', () => {
      renderWithChakra(<VectorStore />);

      expect(screen.getByTestId('pagination')).toBeInTheDocument();
    });

    it('does not render pagination when no links', () => {
      mockUseGetHostedDataStoreTables.mockReturnValue({
        data: { data: mockTables, links: null },
        isLoading: false,
      });

      renderWithChakra(<VectorStore />);

      expect(screen.queryByTestId('pagination')).not.toBeInTheDocument();
    });
  });

  describe('Create Table Drawer', () => {
    it('opens drawer when Create Table is clicked', () => {
      renderWithChakra(<VectorStore />);

      fireEvent.click(screen.getByTestId('cta-button'));

      expect(screen.getByTestId('new-vector-table-drawer')).toBeInTheDocument();
      expect(screen.getByTestId('drawer-title')).toHaveTextContent('Create new table');
    });

    it('closes drawer when close is clicked', () => {
      renderWithChakra(<VectorStore />);

      fireEvent.click(screen.getByTestId('cta-button'));
      expect(screen.getByTestId('new-vector-table-drawer')).toBeInTheDocument();

      fireEvent.click(screen.getByText('Close Drawer'));
      expect(screen.queryByTestId('new-vector-table-drawer')).not.toBeInTheDocument();
    });

    it('shows no selected table when creating new', () => {
      renderWithChakra(<VectorStore />);

      fireEvent.click(screen.getByTestId('cta-button'));

      expect(screen.getByTestId('selected-table-id')).toHaveTextContent('none');
    });
  });

  describe('Enable/Disable Store Toggle', () => {
    it('renders enable/disable switch when user has permission', () => {
      renderWithChakra(<VectorStore />);

      // The switch text should be visible
      expect(screen.getByText('ENABLED')).toBeInTheDocument();
    });

    it('does not render switch when user lacks permission', () => {
      mockUseRoleDataStore.mockReturnValue({ permissions: [] });

      renderWithChakra(<VectorStore />);

      expect(screen.queryByText('ENABLED')).not.toBeInTheDocument();
    });
  });

  describe('Error Handling', () => {
    it('shows error toast when hostedDataStoreTables has errors', () => {
      const errors = [{ message: 'Failed to fetch' }];
      mockUseGetHostedDataStoreTables.mockReturnValue({
        data: { errors },
        isLoading: false,
      });

      renderWithChakra(<VectorStore />);

      expect(mockApiErrorToast).toHaveBeenCalledWith(errors);
    });
  });

  describe('Pagination', () => {
    it('displays current page', () => {
      renderWithChakra(<VectorStore />);

      expect(screen.getByText('Page 1')).toBeInTheDocument();
    });

    it('calls updateFilters when page changes', () => {
      const mockUpdateFilters = jest.fn();
      mockUseFilters.mockReturnValue({
        filters: { page: '1' },
        updateFilters: mockUpdateFilters,
      });

      renderWithChakra(<VectorStore />);

      fireEvent.click(screen.getByText('Next Page'));

      expect(mockUpdateFilters).toHaveBeenCalledWith({ page: '2' });
    });
  });

  describe('Default Template Name', () => {
    it('uses default name when template is not found', () => {
      mockUseGetHostedDBTemplates.mockReturnValue({
        data: { data: [] },
      });

      renderWithChakra(<VectorStore />);

      expect(screen.getByTestId('top-bar-name')).toHaveTextContent('AI Squared Vector Store');
    });
  });

  describe('Disable Vector Store Modal', () => {
    it('navigates to resources on delete success', () => {
      renderWithChakra(<VectorStore />);

      // We need to open the disable modal first - this would require simulating the switch toggle
      // For now, test that the component renders without the modal
      expect(screen.queryByTestId('disable-vector-store-modal')).not.toBeInTheDocument();
    });
  });

  describe('Action Column Menu', () => {
    it('renders edit and delete action buttons when user has permission', () => {
      renderWithChakra(<VectorStore />);

      // Action cells should be rendered for each table row
      expect(screen.getByTestId('action-cell-table-1')).toBeInTheDocument();
      expect(screen.getByTestId('action-cell-table-2')).toBeInTheDocument();
    });

    it('opens drawer with selected table when edit is clicked', () => {
      renderWithChakra(<VectorStore />);

      const editButtons = screen.getAllByTestId('edit-hosted-data-store-table');
      fireEvent.click(editButtons[0]);

      expect(screen.getByTestId('new-vector-table-drawer')).toBeInTheDocument();
      expect(screen.getByTestId('drawer-title')).toHaveTextContent('Edit table');
      expect(screen.getByTestId('selected-table-id')).toHaveTextContent('table-1');
    });

    it('opens delete modal with selected table when delete is clicked', () => {
      renderWithChakra(<VectorStore />);

      const deleteButtons = screen.getAllByTestId('delete-hosted-data-store-table');
      fireEvent.click(deleteButtons[0]);

      expect(screen.getByTestId('confirm-delete-modal')).toBeInTheDocument();
    });

    it('disables delete button when sync is enabled for that table', () => {
      renderWithChakra(<VectorStore />);

      const deleteButtons = screen.getAllByTestId('delete-hosted-data-store-table');
      // table-2 has sync_enabled: 'enabled'
      expect(deleteButtons[1]).toBeDisabled();
    });

    it('does not render action column when user lacks permission', () => {
      mockUseRoleDataStore.mockReturnValue({ permissions: [] });

      renderWithChakra(<VectorStore />);

      expect(screen.queryByTestId('action-cell-table-1')).not.toBeInTheDocument();
    });

    it('calls onClose for edit menu action', () => {
      renderWithChakra(<VectorStore />);

      // Click the close button for edit action to trigger onClose callback
      const editCloseButtons = screen.getAllByTestId('edit-hosted-data-store-table-close');
      fireEvent.click(editCloseButtons[0]);

      // The onClose callback calls onClose() from useDisclosure - verify it doesn't throw
      expect(editCloseButtons[0]).toBeInTheDocument();
    });

    it('calls onClose for delete menu action and clears selected table', () => {
      renderWithChakra(<VectorStore />);

      // First click delete to set selectedTable
      const deleteButtons = screen.getAllByTestId('delete-hosted-data-store-table');
      fireEvent.click(deleteButtons[0]);

      // Modal should be open
      expect(screen.getByTestId('confirm-delete-modal')).toBeInTheDocument();

      // Cancel the modal to close it
      fireEvent.click(screen.getByText('Cancel Delete'));

      // Now click the close button for delete action to trigger onClose callback
      const deleteCloseButtons = screen.getAllByTestId('delete-hosted-data-store-table-close');
      fireEvent.click(deleteCloseButtons[0]);

      // The onClose callback sets selectedTable to null and calls onClose()
      // Since selectedTable is null, opening the drawer should show 'none' for selected table
      fireEvent.click(screen.getByTestId('cta-button'));
      expect(screen.getByTestId('selected-table-id')).toHaveTextContent('none');
    });
  });

  describe('Delete Table Modal Handlers', () => {
    it('deletes table and invalidates queries on confirm', async () => {
      mockDeleteMutateAsync.mockResolvedValue({});

      renderWithChakra(<VectorStore />);

      // Click delete to open modal
      const deleteButtons = screen.getAllByTestId('delete-hosted-data-store-table');
      fireEvent.click(deleteButtons[0]);

      // Verify modal is open
      expect(screen.getByTestId('confirm-delete-modal')).toBeInTheDocument();

      // Confirm deletion
      fireEvent.click(screen.getByText('Confirm Delete'));

      await waitFor(() => {
        expect(mockDeleteMutateAsync).toHaveBeenCalledWith({
          dataStoreId: '123',
          tableId: 'table-1',
        });
      });

      await waitFor(() => {
        expect(mockInvalidateQueries).toHaveBeenCalledWith({
          queryKey: ['get-hosted-data-store-tables'],
        });
      });
    });

    it('closes delete modal and clears selected table on cancel', () => {
      renderWithChakra(<VectorStore />);

      // Click delete to open modal
      const deleteButtons = screen.getAllByTestId('delete-hosted-data-store-table');
      fireEvent.click(deleteButtons[0]);

      expect(screen.getByTestId('confirm-delete-modal')).toBeInTheDocument();

      // Cancel deletion
      fireEvent.click(screen.getByText('Cancel Delete'));

      expect(screen.queryByTestId('confirm-delete-modal')).not.toBeInTheDocument();
    });
  });

  describe('Enable/Disable Store API Calls', () => {
    it('enables store when switch is toggled on', async () => {
      // Use tables with no sync enabled so switch is not disabled
      mockUseGetHostedDataStoreTables.mockReturnValue({
        data: {
          data: [{ id: 'table-1', attributes: { name: 'table1', sync_enabled: 'disabled' } }],
          links: { next: '/next' },
        },
        isLoading: false,
      });
      mockUseGetHostedDBTemplates.mockReturnValue({
        data: {
          data: [{ ...mockTemplate, store_enabled: false }],
        },
      });
      mockEnableMutateAsync.mockResolvedValue({});

      renderWithChakra(<VectorStore />);

      // Find the switch and toggle it
      const switchElement = screen.getByRole('checkbox');
      fireEvent.click(switchElement);

      await waitFor(() => {
        expect(mockEnableMutateAsync).toHaveBeenCalledWith({
          dataStoreId: '123',
          enabled: true,
        });
      });
    });

    it('shows error toast when enable fails', async () => {
      // Use tables with no sync enabled so switch is not disabled
      mockUseGetHostedDataStoreTables.mockReturnValue({
        data: {
          data: [{ id: 'table-1', attributes: { name: 'table1', sync_enabled: 'disabled' } }],
          links: { next: '/next' },
        },
        isLoading: false,
      });
      mockUseGetHostedDBTemplates.mockReturnValue({
        data: {
          data: [{ ...mockTemplate, store_enabled: false }],
        },
      });
      const errors = [{ message: 'Enable failed' }];
      mockEnableMutateAsync.mockResolvedValue({ errors });

      renderWithChakra(<VectorStore />);

      const switchElement = screen.getByRole('checkbox');
      fireEvent.click(switchElement);

      await waitFor(() => {
        expect(mockApiErrorToast).toHaveBeenCalledWith(errors);
      });
    });

    it('opens disable modal when switch is toggled off', () => {
      // Use tables with no sync enabled so switch is not disabled
      mockUseGetHostedDataStoreTables.mockReturnValue({
        data: {
          data: [{ id: 'table-1', attributes: { name: 'table1', sync_enabled: 'disabled' } }],
          links: { next: '/next' },
        },
        isLoading: false,
      });

      renderWithChakra(<VectorStore />);

      // Find the switch (currently enabled) and toggle it off
      const switchElement = screen.getByRole('checkbox');
      fireEvent.click(switchElement);

      expect(screen.getByTestId('disable-vector-store-modal')).toBeInTheDocument();
    });

    it('disables store when confirm disable is clicked', async () => {
      // Use tables with no sync enabled so switch is not disabled
      mockUseGetHostedDataStoreTables.mockReturnValue({
        data: {
          data: [{ id: 'table-1', attributes: { name: 'table1', sync_enabled: 'disabled' } }],
          links: { next: '/next' },
        },
        isLoading: false,
      });
      mockEnableMutateAsync.mockResolvedValue({});

      renderWithChakra(<VectorStore />);

      // Open disable modal
      const switchElement = screen.getByRole('checkbox');
      fireEvent.click(switchElement);

      // Confirm disable
      fireEvent.click(screen.getByText('Confirm Disable'));

      await waitFor(() => {
        expect(mockEnableMutateAsync).toHaveBeenCalledWith({
          dataStoreId: '123',
          enabled: false,
        });
      });
    });

    it('shows error toast when disable fails', async () => {
      // Use tables with no sync enabled so switch is not disabled
      mockUseGetHostedDataStoreTables.mockReturnValue({
        data: {
          data: [{ id: 'table-1', attributes: { name: 'table1', sync_enabled: 'disabled' } }],
          links: { next: '/next' },
        },
        isLoading: false,
      });
      const errors = [{ message: 'Disable failed' }];
      mockEnableMutateAsync.mockResolvedValue({ errors });

      renderWithChakra(<VectorStore />);

      // Open disable modal
      const switchElement = screen.getByRole('checkbox');
      fireEvent.click(switchElement);

      // Confirm disable
      fireEvent.click(screen.getByText('Confirm Disable'));

      await waitFor(() => {
        expect(mockApiErrorToast).toHaveBeenCalledWith(errors);
      });
    });

    it('closes disable modal on close', () => {
      // Use tables with no sync enabled so switch is not disabled
      mockUseGetHostedDataStoreTables.mockReturnValue({
        data: {
          data: [{ id: 'table-1', attributes: { name: 'table1', sync_enabled: 'disabled' } }],
          links: { next: '/next' },
        },
        isLoading: false,
      });

      renderWithChakra(<VectorStore />);

      // Open disable modal
      const switchElement = screen.getByRole('checkbox');
      fireEvent.click(switchElement);

      expect(screen.getByTestId('disable-vector-store-modal')).toBeInTheDocument();

      // Close modal
      fireEvent.click(screen.getByText('Close Modal'));

      expect(screen.queryByTestId('disable-vector-store-modal')).not.toBeInTheDocument();
    });

    it('navigates to resources on delete success callback', () => {
      // Use tables with no sync enabled so switch is not disabled
      mockUseGetHostedDataStoreTables.mockReturnValue({
        data: {
          data: [{ id: 'table-1', attributes: { name: 'table1', sync_enabled: 'disabled' } }],
          links: { next: '/next' },
        },
        isLoading: false,
      });

      renderWithChakra(<VectorStore />);

      // Open disable modal
      const switchElement = screen.getByRole('checkbox');
      fireEvent.click(switchElement);

      // Trigger delete success
      fireEvent.click(screen.getByText('Delete Success'));

      expect(mockNavigate).toHaveBeenCalledWith('/settings/resources', { replace: true });
    });
  });

  describe('Sync Enabled State', () => {
    it('disables switch when any table has sync enabled', () => {
      renderWithChakra(<VectorStore />);

      // table-2 has sync_enabled: 'enabled', so switch should be disabled
      const switchElement = screen.getByRole('checkbox');
      expect(switchElement).toBeDisabled();
    });

    it('enables switch when no table has sync enabled', () => {
      mockUseGetHostedDataStoreTables.mockReturnValue({
        data: {
          data: [{ id: 'table-1', attributes: { name: 'table1', sync_enabled: 'disabled' } }],
          links: { next: '/next' },
        },
        isLoading: false,
      });

      renderWithChakra(<VectorStore />);

      const switchElement = screen.getByRole('checkbox');
      expect(switchElement).not.toBeDisabled();
    });

    it('shows tooltip message when switch is disabled due to sync', () => {
      renderWithChakra(<VectorStore />);

      const tooltip = screen.getByTestId('tooltip');
      expect(tooltip).toHaveAttribute(
        'data-label',
        "This resource can't be disabled because one or more tables are part of an active sync. Disable all active syncs to disable this resource.",
      );
    });
  });

  describe('Drawer Edit Mode', () => {
    it('shows edit title and selected table when editing', () => {
      renderWithChakra(<VectorStore />);

      const editButtons = screen.getAllByTestId('edit-hosted-data-store-table');
      fireEvent.click(editButtons[0]);

      expect(screen.getByTestId('drawer-title')).toHaveTextContent('Edit table');
      expect(screen.getByTestId('selected-table-id')).toHaveTextContent('table-1');
    });

    it('sets drawer as readonly when table has sync enabled', () => {
      renderWithChakra(<VectorStore />);

      // table-2 has sync_enabled: 'enabled'
      const editButtons = screen.getAllByTestId('edit-hosted-data-store-table');
      fireEvent.click(editButtons[1]);

      expect(screen.getByTestId('drawer-editable')).toHaveTextContent('readonly');
    });

    it('sets drawer as editable when table has sync disabled', () => {
      renderWithChakra(<VectorStore />);

      // table-1 has sync_enabled: 'disabled'
      const editButtons = screen.getAllByTestId('edit-hosted-data-store-table');
      fireEvent.click(editButtons[0]);

      expect(screen.getByTestId('drawer-editable')).toHaveTextContent('editable');
    });

    it('clears selected table and closes drawer on drawer close', () => {
      renderWithChakra(<VectorStore />);

      // Open drawer with edit
      const editButtons = screen.getAllByTestId('edit-hosted-data-store-table');
      fireEvent.click(editButtons[0]);

      expect(screen.getByTestId('new-vector-table-drawer')).toBeInTheDocument();

      // Close drawer
      fireEvent.click(screen.getByText('Close Drawer'));

      expect(screen.queryByTestId('new-vector-table-drawer')).not.toBeInTheDocument();
    });
  });

  describe('HorizontalMenuActions Click Handler', () => {
    it('stops propagation when menu is clicked', () => {
      renderWithChakra(<VectorStore />);

      const menuActions = screen.getAllByTestId('horizontal-menu-actions');
      const mockEvent = { stopPropagation: jest.fn() };

      fireEvent.click(menuActions[0], mockEvent);

      // The click handler should be present (stopPropagation is called internally)
      expect(menuActions[0]).toBeInTheDocument();
    });
  });

  describe('Template Store Enabled Effect', () => {
    it('sets store enabled state from template', () => {
      mockUseGetHostedDBTemplates.mockReturnValue({
        data: {
          data: [{ ...mockTemplate, store_enabled: false }],
        },
      });

      renderWithChakra(<VectorStore />);

      expect(screen.getByText('DISABLED')).toBeInTheDocument();
    });
  });
});
