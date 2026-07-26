import '@testing-library/jest-dom/jest-globals';
import '@testing-library/jest-dom';
import { screen, fireEvent, waitFor } from '@testing-library/react';
import { renderWithProviders } from '@/utils/testUtils';
import FinalizeModel from '../ModelsForm/FinalizeModel/FinalizeModel';
import {
  mockNavigate,
  mockShowToast,
  mockCreateNewModel,
  mockClearState,
  mockHandleMoveForward,
  mockConnectorItem,
  mockUnstructuredConnectorItem,
  mockSemistructuredConnectorItem,
  mockVectorConnectorItem,
  mockDynamicQueryStoreState,
} from '../__mocks__/modelsMocks';

// ── Mocks ───────────────────────────────────────────────────────────

jest.mock('react-router-dom', () => ({
  ...jest.requireActual('react-router-dom'),
  useNavigate: () => mockNavigate,
}));

jest.mock('@/hooks/useCustomToast', () => ({
  __esModule: true,
  default: () => mockShowToast,
}));

jest.mock('@/services/models', () => ({
  createNewModel: (...args: unknown[]) => mockCreateNewModel(...args),
}));

jest.mock('@/components/ContentContainer', () => ({
  __esModule: true,
  default: ({ children }: { children: React.ReactNode }) => <div>{children}</div>,
}));

jest.mock('@/components/FormFooter', () => ({
  __esModule: true,
  default: ({ ctaName, isCtaLoading }: { ctaName: string; isCtaLoading: boolean }) => (
    <button type='submit' data-testid='form-footer' disabled={isCtaLoading}>
      {ctaName}
    </button>
  ),
}));

// Stepped form mock - will be overridden per test
const mockSteppedFormReturn = jest.fn();
jest.mock('@/stores/useSteppedForm', () => ({
  __esModule: true,
  default: () => mockSteppedFormReturn(),
}));

// Dynamic query store mock
const mockDynamicQueryStore = jest.fn();
jest.mock('@/enterprise/store/useDynamicQueryStore', () => ({
  useDynamicQueryStore: (selector: (state: unknown) => unknown) =>
    selector(mockDynamicQueryStore()),
}));

// ── Helpers ─────────────────────────────────────────────────────────

const buildSteppedFormData = (connectorItem = mockConnectorItem) => ({
  forms: [
    {
      stepKey: 'datasource',
      data: { datasource: connectorItem },
    },
    {
      stepKey: 'defineModel',
      data: {
        defineModel: {
          id: 1,
          query: 'SELECT * FROM users',
          columns: [
            { key: 'id', name: 'id' },
            { key: 'name', name: 'name' },
          ],
        },
      },
    },
    {
      stepKey: 'configureChunkingAndEmbedding',
      data: {
        configureChunkingAndEmbedding: {
          chunkSize: '500',
          overlap: '50',
          embedding_config: { model: 'ada' },
          connector_id: '10',
        },
      },
    },
    {
      stepKey: 'configureDocumentAnalysis',
      data: {
        configureDocumentAnalysis: {
          service: 'lightning',
          options: {},
          connector_id: '20',
        },
      },
    },
  ],
  stepInfo: { formKey: 'finalizeModel' },
  handleMoveForward: mockHandleMoveForward,
});

// ── Tests ───────────────────────────────────────────────────────────

describe('FinalizeModel', () => {
  beforeEach(() => {
    jest.clearAllMocks();
    mockSteppedFormReturn.mockReturnValue(buildSteppedFormData());
    mockDynamicQueryStore.mockReturnValue(mockDynamicQueryStoreState);
  });

  it('renders the form with model name, description, and primary key fields', () => {
    renderWithProviders(<FinalizeModel />);
    expect(screen.getByText('Finalize settings for this Model')).toBeInTheDocument();
    expect(screen.getByTestId('finalize-model-name-input')).toBeInTheDocument();
    expect(screen.getByPlaceholderText('Enter a name')).toBeInTheDocument();
    expect(screen.getByPlaceholderText('Enter a description')).toBeInTheDocument();
    expect(screen.getByText('Primary Key')).toBeInTheDocument();
    expect(screen.getByText('Select a column')).toBeInTheDocument();
  });

  it('renders column options in the primary key select', () => {
    renderWithProviders(<FinalizeModel />);
    const options = screen.getAllByRole('option');
    // "Select a column" placeholder + 2 columns
    expect(options).toHaveLength(3);
    expect(options[1]).toHaveTextContent('id');
    expect(options[2]).toHaveTextContent('name');
  });

  it('hides primary key field for unstructured data type', () => {
    mockSteppedFormReturn.mockReturnValue(buildSteppedFormData(mockUnstructuredConnectorItem));
    renderWithProviders(<FinalizeModel />);
    expect(screen.queryByText('Primary Key')).not.toBeInTheDocument();
  });

  it('hides primary key field for semistructured data type', () => {
    mockSteppedFormReturn.mockReturnValue(buildSteppedFormData(mockSemistructuredConnectorItem));
    renderWithProviders(<FinalizeModel />);
    expect(screen.queryByText('Primary Key')).not.toBeInTheDocument();
  });

  it('shows validation error when model name is empty on submit', async () => {
    renderWithProviders(<FinalizeModel />);
    fireEvent.click(screen.getByText('Finish'));
    await waitFor(() => {
      expect(screen.getByText('Model name is required')).toBeInTheDocument();
    });
  });

  it('submits form successfully and navigates', async () => {
    mockCreateNewModel.mockResolvedValue({ data: { id: '99' } });
    renderWithProviders(<FinalizeModel />);

    fireEvent.change(screen.getByPlaceholderText('Enter a name'), {
      target: { value: 'My Model' },
    });
    fireEvent.change(screen.getByPlaceholderText('Enter a description'), {
      target: { value: 'A description' },
    });
    // Select primary key
    fireEvent.change(screen.getByRole('combobox'), { target: { value: 'id' } });

    fireEvent.click(screen.getByText('Finish'));

    await waitFor(() => {
      expect(mockCreateNewModel).toHaveBeenCalledWith(
        expect.objectContaining({
          model: expect.objectContaining({
            name: 'My Model',
            description: 'A description',
            primary_key: 'id',
          }),
        }),
      );
    });

    await waitFor(() => {
      expect(mockShowToast).toHaveBeenCalledWith(expect.objectContaining({ title: 'Success!!' }));
      expect(mockClearState).toHaveBeenCalled();
      expect(mockNavigate).toHaveBeenCalledWith('/define/models/99');
    });
  });

  it('shows error toasts when API returns errors', async () => {
    mockCreateNewModel.mockResolvedValue({
      errors: [{ detail: 'name already taken' }],
    });
    renderWithProviders(<FinalizeModel />);

    fireEvent.change(screen.getByPlaceholderText('Enter a name'), {
      target: { value: 'My Model' },
    });
    fireEvent.change(screen.getByRole('combobox'), { target: { value: 'id' } });
    fireEvent.click(screen.getByText('Finish'));

    await waitFor(() => {
      expect(mockShowToast).toHaveBeenCalledWith(
        expect.objectContaining({ title: 'Name Already Taken' }),
      );
    });
  });

  it('shows error toast on network failure', async () => {
    mockCreateNewModel.mockRejectedValue(new Error('Network error'));
    renderWithProviders(<FinalizeModel />);

    fireEvent.change(screen.getByPlaceholderText('Enter a name'), {
      target: { value: 'My Model' },
    });
    fireEvent.change(screen.getByRole('combobox'), { target: { value: 'id' } });
    fireEvent.click(screen.getByText('Finish'));

    await waitFor(() => {
      expect(mockShowToast).toHaveBeenCalledWith(
        expect.objectContaining({
          title: 'An error occurred.',
          description: 'Something went wrong while creating Model.',
        }),
      );
    });
  });

  it('uses vector_search query type for vector data type', async () => {
    mockSteppedFormReturn.mockReturnValue(buildSteppedFormData(mockVectorConnectorItem));
    mockCreateNewModel.mockResolvedValue({ data: { id: '100' } });
    renderWithProviders(<FinalizeModel />);

    fireEvent.change(screen.getByPlaceholderText('Enter a name'), {
      target: { value: 'Vector Model' },
    });
    fireEvent.change(screen.getByRole('combobox'), { target: { value: 'id' } });
    fireEvent.click(screen.getByText('Finish'));

    await waitFor(() => {
      expect(mockCreateNewModel).toHaveBeenCalledWith(
        expect.objectContaining({
          model: expect.objectContaining({
            query_type: 'vector_search',
          }),
        }),
      );
    });
  });

  it('uses unstructured query type and chunking connector_id for unstructured data', async () => {
    mockSteppedFormReturn.mockReturnValue(buildSteppedFormData(mockUnstructuredConnectorItem));
    mockCreateNewModel.mockResolvedValue({ data: { id: '101' } });
    renderWithProviders(<FinalizeModel />);

    fireEvent.change(screen.getByPlaceholderText('Enter a name'), {
      target: { value: 'Unstructured Model' },
    });
    fireEvent.click(screen.getByText('Finish'));

    await waitFor(() => {
      expect(mockCreateNewModel).toHaveBeenCalledWith(
        expect.objectContaining({
          model: expect.objectContaining({
            query_type: 'unstructured',
            connector_id: 10,
          }),
        }),
      );
    });
  });

  it('uses semistructured query type and document analysis connector_id', async () => {
    mockSteppedFormReturn.mockReturnValue(buildSteppedFormData(mockSemistructuredConnectorItem));
    mockCreateNewModel.mockResolvedValue({ data: { id: '102' } });
    renderWithProviders(<FinalizeModel />);

    fireEvent.change(screen.getByPlaceholderText('Enter a name'), {
      target: { value: 'Semi Model' },
    });
    fireEvent.click(screen.getByText('Finish'));

    await waitFor(() => {
      expect(mockCreateNewModel).toHaveBeenCalledWith(
        expect.objectContaining({
          model: expect.objectContaining({
            query_type: 'semistructured',
            connector_id: 20,
          }),
        }),
      );
    });
  });
});
