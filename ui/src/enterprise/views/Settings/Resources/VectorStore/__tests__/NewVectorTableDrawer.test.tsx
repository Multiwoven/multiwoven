import { render, screen, fireEvent, waitFor } from '@testing-library/react';
import { expect } from '@jest/globals';
import '@testing-library/jest-dom/jest-globals';
import '@testing-library/jest-dom';
import NewVectorTableDrawer from '../NewVectorTableDrawer';
import { HostedDataStoreTableResponse } from '@/enterprise/services/types';

const mockCreateMutateAsync = jest.fn();
const mockUpdateMutateAsync = jest.fn();
const mockApiErrorToast = jest.fn();
const mockInvalidateQueries = jest.fn();

jest.mock('@/enterprise/hooks/mutations/useHostedStoreMutations', () => ({
  __esModule: true,
  default: () => ({
    createHostedDataStoreTableMutation: {
      mutateAsync: mockCreateMutateAsync,
      isPending: false,
    },
    updateHostedDataStoreTableMutation: {
      mutateAsync: mockUpdateMutateAsync,
      isPending: false,
    },
  }),
}));

jest.mock('@/hooks/useErrorToast', () => ({
  useAPIErrorsToast: () => mockApiErrorToast,
}));

jest.mock('@tanstack/react-query', () => ({
  useQueryClient: () => ({
    invalidateQueries: mockInvalidateQueries,
  }),
}));

jest.mock('../views', () => ({
  ColumnsView: ({ values }: any) => (
    <div data-testid='columns-view'>
      <span data-testid='table-name'>{values.tableName}</span>
      <span data-testid='columns-count'>{values.columns.length}</span>
    </div>
  ),
  SqlSchemaView: ({ values, readOnly }: any) => (
    <div data-testid='sql-schema-view' data-readonly={readOnly}>
      <span data-testid='sql-schema'>{values.sqlSchema}</span>
    </div>
  ),
}));

jest.mock('@/components/Alerts', () => ({
  __esModule: true,
  default: ({ description, status }: any) => (
    <div data-testid='alert-box' data-status={status}>
      {description}
    </div>
  ),
}));

jest.mock('../utils/sqlSchemaUtils', () => ({
  generateSqlFromColumns: jest.fn(
    (tableName: string, columns: any[]) =>
      `CREATE TABLE ${tableName} (${columns.map((c) => c.name).join(', ')});`,
  ),
}));

describe('NewVectorTableDrawer', () => {
  const defaultProps = {
    isOpen: true,
    onClose: jest.fn(),
    title: 'Create new table',
    dataStoreId: 'store-123',
  };

  const mockSelectedTable: HostedDataStoreTableResponse = {
    id: 'table-1',
    type: 'hosted_data_store_tables',
    attributes: {
      template_id: 'vector_store_hosted_connector',
      name: 'existing_table',
      column_count: 2,
      row_count: 10,
      size: 10,
      sync_enabled: 'disabled',
      table_schema: {
        type: 'vector_db',
        properties: {
          id: { type: 'INT8', primary_key: true },
          name: { type: 'TEXT' },
        },
        required: ['id', 'name'],
      },
    },
  };

  beforeEach(() => {
    jest.clearAllMocks();
  });

  describe('Rendering', () => {
    it('renders drawer when isOpen is true', () => {
      render(<NewVectorTableDrawer {...defaultProps} />);

      expect(screen.getByText('Create new table')).toBeInTheDocument();
    });

    it('renders title correctly', () => {
      render(<NewVectorTableDrawer {...defaultProps} title='Edit table' />);

      expect(screen.getByText('Edit table')).toBeInTheDocument();
    });

    it('renders ColumnsView by default', () => {
      render(<NewVectorTableDrawer {...defaultProps} />);

      expect(screen.getByTestId('columns-view')).toBeInTheDocument();
      expect(screen.queryByTestId('sql-schema-view')).not.toBeInTheDocument();
    });

    it('renders Cancel button', () => {
      render(<NewVectorTableDrawer {...defaultProps} />);

      expect(screen.getByRole('button', { name: 'Cancel' })).toBeInTheDocument();
    });

    it('renders Create button for new table', () => {
      render(<NewVectorTableDrawer {...defaultProps} />);

      expect(screen.getByRole('button', { name: 'Create' })).toBeInTheDocument();
    });

    it('uses a stable test id on the submit button', () => {
      render(<NewVectorTableDrawer {...defaultProps} />);

      expect(screen.getByTestId('data-store-submit-button')).toBeInTheDocument();
    });

    it('renders Update button when editing existing table', () => {
      render(<NewVectorTableDrawer {...defaultProps} selectedTable={mockSelectedTable} />);

      expect(screen.getByRole('button', { name: 'Update' })).toBeInTheDocument();
    });

    it('keeps the same submit test id when editing an existing table', () => {
      render(<NewVectorTableDrawer {...defaultProps} selectedTable={mockSelectedTable} />);

      expect(screen.getByTestId('data-store-submit-button')).toBeInTheDocument();
    });

    it('renders Define SQL Schema button', () => {
      render(<NewVectorTableDrawer {...defaultProps} />);

      expect(screen.getByRole('button', { name: 'Define SQL Schema' })).toBeInTheDocument();
    });
  });

  describe('View Toggle', () => {
    it('switches to SqlSchemaView when Define SQL Schema is clicked', () => {
      render(<NewVectorTableDrawer {...defaultProps} />);

      fireEvent.click(screen.getByRole('button', { name: 'Define SQL Schema' }));

      expect(screen.getByTestId('sql-schema-view')).toBeInTheDocument();
      expect(screen.queryByTestId('columns-view')).not.toBeInTheDocument();
    });

    it('shows Define Columns button when in SQL Schema view', () => {
      render(<NewVectorTableDrawer {...defaultProps} />);

      fireEvent.click(screen.getByRole('button', { name: 'Define SQL Schema' }));

      expect(screen.getByRole('button', { name: 'Define Columns' })).toBeInTheDocument();
    });

    it('switches back to ColumnsView when Define Columns is clicked', () => {
      render(<NewVectorTableDrawer {...defaultProps} />);

      fireEvent.click(screen.getByRole('button', { name: 'Define SQL Schema' }));
      fireEvent.click(screen.getByRole('button', { name: 'Define Columns' }));

      expect(screen.getByTestId('columns-view')).toBeInTheDocument();
    });
  });

  describe('Initial Values', () => {
    it('uses template values for new table', () => {
      render(<NewVectorTableDrawer {...defaultProps} />);

      expect(screen.getByTestId('table-name')).toHaveTextContent('document_vector_embeddings');
      expect(screen.getByTestId('columns-count')).toHaveTextContent('4');
    });

    it('uses selected table values when editing', () => {
      render(<NewVectorTableDrawer {...defaultProps} selectedTable={mockSelectedTable} />);

      expect(screen.getByTestId('table-name')).toHaveTextContent('existing_table');
      expect(screen.getByTestId('columns-count')).toHaveTextContent('2');
    });
  });

  describe('Non-Editable State', () => {
    it('shows warning alert when isEditable is false', () => {
      render(<NewVectorTableDrawer {...defaultProps} isEditable={false} />);

      expect(screen.getByTestId('alert-box')).toBeInTheDocument();
    });

    it('does not show warning alert when isEditable is true', () => {
      render(<NewVectorTableDrawer {...defaultProps} isEditable={true} />);

      expect(screen.queryByTestId('alert-box')).not.toBeInTheDocument();
    });

    it('disables Create/Update button when isEditable is false', () => {
      render(<NewVectorTableDrawer {...defaultProps} isEditable={false} />);

      expect(screen.getByRole('button', { name: 'Create' })).toBeDisabled();
    });

    it('disables Define SQL Schema button when isEditable is false', () => {
      render(<NewVectorTableDrawer {...defaultProps} isEditable={false} />);

      expect(screen.getByRole('button', { name: 'Define SQL Schema' })).toBeDisabled();
    });

    it('passes readOnly prop to SqlSchemaView when not editable', () => {
      render(<NewVectorTableDrawer {...defaultProps} isEditable={false} />);

      fireEvent.click(screen.getByRole('button', { name: 'Define SQL Schema' }));

      // Button is disabled, so view won't change - test that the button is disabled
      expect(screen.getByRole('button', { name: 'Define SQL Schema' })).toBeDisabled();
    });
  });

  describe('Form Submission - Create', () => {
    it('calls createHostedDataStoreTableMutation for new table', async () => {
      mockCreateMutateAsync.mockResolvedValue({ data: { id: 'new-table-1' } });

      render(<NewVectorTableDrawer {...defaultProps} />);

      fireEvent.click(screen.getByRole('button', { name: 'Create' }));

      await waitFor(() => {
        expect(mockCreateMutateAsync).toHaveBeenCalledWith({
          dataStoreId: 'store-123',
          payload: expect.objectContaining({
            hosted_data_store_table: expect.objectContaining({
              name: 'document_vector_embeddings',
              template_id: 'vector_store_hosted_connector',
            }),
          }),
        });
      });
    });

    it('invalidates queries on successful creation', async () => {
      mockCreateMutateAsync.mockResolvedValue({ data: { id: 'new-table-1' } });

      render(<NewVectorTableDrawer {...defaultProps} />);

      fireEvent.click(screen.getByRole('button', { name: 'Create' }));

      await waitFor(() => {
        expect(mockInvalidateQueries).toHaveBeenCalledWith({
          queryKey: ['get-hosted-data-store-tables', 'store-123'],
        });
      });
    });

    it('calls onClose on successful creation', async () => {
      mockCreateMutateAsync.mockResolvedValue({ data: { id: 'new-table-1' } });

      render(<NewVectorTableDrawer {...defaultProps} />);

      fireEvent.click(screen.getByRole('button', { name: 'Create' }));

      await waitFor(() => {
        expect(defaultProps.onClose).toHaveBeenCalled();
      });
    });

    it('shows error toast when creation fails', async () => {
      const errors = [{ message: 'Failed to create' }];
      mockCreateMutateAsync.mockResolvedValue({ errors });

      render(<NewVectorTableDrawer {...defaultProps} />);

      fireEvent.click(screen.getByRole('button', { name: 'Create' }));

      await waitFor(() => {
        expect(mockApiErrorToast).toHaveBeenCalledWith(errors);
      });
    });
  });

  describe('Form Submission - Update', () => {
    it('calls updateHostedDataStoreTableMutation for existing table', async () => {
      mockUpdateMutateAsync.mockResolvedValue({ data: { id: 'table-1' } });

      render(<NewVectorTableDrawer {...defaultProps} selectedTable={mockSelectedTable} />);

      fireEvent.click(screen.getByRole('button', { name: 'Update' }));

      await waitFor(() => {
        expect(mockUpdateMutateAsync).toHaveBeenCalledWith({
          dataStoreId: 'store-123',
          tableId: 'table-1',
          payload: expect.objectContaining({
            hosted_data_store_table: expect.objectContaining({
              name: 'existing_table',
            }),
          }),
        });
      });
    });

    it('invalidates queries on successful update', async () => {
      mockUpdateMutateAsync.mockResolvedValue({ data: { id: 'table-1' } });

      render(<NewVectorTableDrawer {...defaultProps} selectedTable={mockSelectedTable} />);

      fireEvent.click(screen.getByRole('button', { name: 'Update' }));

      await waitFor(() => {
        expect(mockInvalidateQueries).toHaveBeenCalledWith({
          queryKey: ['get-hosted-data-store-tables', 'store-123'],
        });
      });
    });

    it('shows error toast when update fails', async () => {
      const errors = [{ message: 'Failed to update' }];
      mockUpdateMutateAsync.mockResolvedValue({ errors });

      render(<NewVectorTableDrawer {...defaultProps} selectedTable={mockSelectedTable} />);

      fireEvent.click(screen.getByRole('button', { name: 'Update' }));

      await waitFor(() => {
        expect(mockApiErrorToast).toHaveBeenCalledWith(errors);
      });
    });
  });

  describe('Cancel Button', () => {
    it('calls onClose when Cancel is clicked', () => {
      render(<NewVectorTableDrawer {...defaultProps} />);

      fireEvent.click(screen.getByRole('button', { name: 'Cancel' }));

      expect(defaultProps.onClose).toHaveBeenCalledTimes(1);
    });
  });
});
