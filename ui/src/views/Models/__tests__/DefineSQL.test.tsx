import '@testing-library/jest-dom/jest-globals';
import '@testing-library/jest-dom';
import { screen, fireEvent, waitFor } from '@testing-library/react';
import { renderWithProviders } from '@/utils/testUtils';
import DefineSQL from '../ModelsForm/DefineModel/DefineSQL/DefineSQL';
import {
  mockNavigate,
  mockShowToast,
  mockPutModelById,
  mockHandleMoveForward,
  mockDynamicQueryStoreState,
  mockApiErrorsToast,
  mockErrorToast,
  mockGetPreview,
  mockUseModelPreviewReturn,
  mockPrefillValues,
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

jest.mock('@/hooks/useErrorToast', () => ({
  useErrorToast: () => mockErrorToast,
  useAPIErrorsToast: () => mockApiErrorsToast,
}));

jest.mock('@/services/models', () => ({
  putModelById: (...args: unknown[]) => mockPutModelById(...args),
}));

jest.mock('@/stores/useSteppedForm', () => ({
  __esModule: true,
  default: () => ({
    stepInfo: { formKey: 'defineModel' },
    handleMoveForward: mockHandleMoveForward,
  }),
}));

const mockDynamicQueryStore = jest.fn();
jest.mock('@/enterprise/store/useDynamicQueryStore', () => ({
  useDynamicQueryStore: (selector: (state: unknown) => unknown) =>
    selector(mockDynamicQueryStore()),
}));

jest.mock('@/hooks/models/useModelPreview', () => ({
  useModelPreview: () => mockUseModelPreviewReturn,
}));

// Mock Monaco editor
const mockEditorRef = { current: { getValue: jest.fn(() => 'SELECT * FROM users') } };
jest.mock('@monaco-editor/react', () => ({
  __esModule: true,
  default: ({
    value,
    onMount,
    onChange,
  }: {
    value: string;
    onMount?: (editor: unknown) => void;
    onChange?: (value: string) => void;
  }) => {
    // Simulate editor mount
    if (onMount) {
      onMount(mockEditorRef.current);
    }
    return (
      <textarea
        data-testid='monaco-editor'
        value={value}
        onChange={(e) => onChange?.(e.target.value)}
      />
    );
  },
  useMonaco: () => null,
}));

jest.mock('@/components/ContentContainer', () => ({
  __esModule: true,
  default: ({ children }: { children: React.ReactNode }) => <div>{children}</div>,
}));

jest.mock('@/components/FormFooter', () => ({
  __esModule: true,
  default: ({
    ctaName,
    onCtaClick,
    isCtaDisabled,
  }: {
    ctaName: string;
    onCtaClick?: () => void;
    isCtaDisabled?: boolean;
  }) => (
    <button data-testid='form-footer' onClick={onCtaClick} disabled={isCtaDisabled}>
      {ctaName}
    </button>
  ),
}));

jest.mock('../ModelsForm/DefineModel/ModelQueryResults', () => ({
  __esModule: true,
  default: ({
    onRunQuery,
    isLoading,
    isEnabled,
  }: {
    onRunQuery: () => void;
    isLoading: boolean;
    isEnabled: boolean;
  }) => (
    <div data-testid='model-query-results'>
      <button data-testid='run-query-btn' onClick={onRunQuery} disabled={!isEnabled || isLoading}>
        Show Preview
      </button>
    </div>
  ),
}));

jest.mock('../ModelsForm/DefineModel/QueryBox', () => ({
  __esModule: true,
  default: ({
    children,
    handleQueryRun,
    extra,
  }: {
    children: React.ReactNode;
    handleQueryRun: () => void;
    extra?: React.ReactNode;
  }) => (
    <div data-testid='query-box'>
      <button data-testid='query-run-btn' onClick={handleQueryRun}>
        Run
      </button>
      {extra}
      {children}
    </div>
  ),
}));

jest.mock('@/enterprise/dataApps/components/TableVisual', () => ({
  __esModule: true,
  default: () => <div data-testid='table-visual'>Table Visual</div>,
}));

jest.mock('@/enterprise/views/Define/DynamicDataModels/ConfiguringDynamicVariablesInfo', () => ({
  __esModule: true,
  default: ({ modalOpen }: { modalOpen: boolean }) =>
    modalOpen ? <div data-testid='dynamic-vars-info-modal'>Info</div> : null,
}));

jest.mock('@/enterprise/views/Define/DynamicDataModels/InputFieldsMappingModal', () => ({
  __esModule: true,
  default: ({
    modalOpen,
    handlePreviewClick,
  }: {
    modalOpen: boolean;
    handlePreviewClick: () => void;
  }) =>
    modalOpen ? (
      <div data-testid='input-fields-modal'>
        <button data-testid='preview-mapped' onClick={handlePreviewClick}>
          Preview
        </button>
      </div>
    ) : null,
}));

jest.mock('@/enterprise/views/Define/DynamicDataModels/HarvestDynamicModels', () => ({
  __esModule: true,
  default: () => <div data-testid='harvest-screen'>Harvest</div>,
}));

jest.mock('sql-formatter', () => ({
  format: (sql: string) => sql,
}));

jest.mock('@/enterprise/utils/extractVariableNames', () => ({
  extractVariableNames: (query: string) => {
    const matches = query.match(/:(\w+)/g);
    return matches ? matches.map((m) => m.slice(1)) : [];
  },
}));

jest.mock('@/assets/icons/FiAI', () => ({
  __esModule: true,
  default: () => <span>AI</span>,
}));

// ── Tests ───────────────────────────────────────────────────────────

describe('DefineSQL', () => {
  const defaultProps = {
    isUpdateButtonVisible: false,
    connectorId: '1',
    connectorIcon: <span>Icon</span>,
    connectorDataType: 'structured',
  };

  beforeEach(() => {
    jest.clearAllMocks();
    mockDynamicQueryStore.mockReturnValue(mockDynamicQueryStoreState);
    mockEditorRef.current.getValue.mockReturnValue('SELECT * FROM users');
    // Reset shared mock state to defaults
    mockUseModelPreviewReturn.tableData = null;
    mockUseModelPreviewReturn.loading = false;
    mockUseModelPreviewReturn.canMoveForward = false;
  });

  afterEach(() => {
    // Ensure cleanup even if test fails or times out
    mockUseModelPreviewReturn.tableData = null;
    mockUseModelPreviewReturn.loading = false;
    mockUseModelPreviewReturn.canMoveForward = false;
  });

  it('renders the SQL editor and query results', () => {
    renderWithProviders(<DefineSQL {...defaultProps} />);
    expect(screen.getByTestId('query-box')).toBeInTheDocument();
    expect(screen.getByTestId('model-sql-monaco-editor')).toBeInTheDocument();
    expect(screen.getByTestId('monaco-editor')).toBeInTheDocument();
    expect(screen.getByTestId('model-query-results')).toBeInTheDocument();
  });

  it('renders Continue footer when not in update mode', () => {
    renderWithProviders(<DefineSQL {...defaultProps} />);
    expect(screen.getByTestId('form-footer')).toHaveTextContent('Continue');
  });

  it('renders Save Changes footer when in update mode', () => {
    renderWithProviders(<DefineSQL {...defaultProps} isUpdateButtonVisible={true} />);
    expect(screen.getByTestId('form-footer')).toHaveTextContent('Save Changes');
  });

  it('calls getPreview when run query is clicked (static method)', () => {
    renderWithProviders(<DefineSQL {...defaultProps} />);
    fireEvent.click(screen.getByTestId('query-run-btn'));
    expect(mockGetPreview).toHaveBeenCalledWith('SELECT * FROM users', '1');
  });

  it('renders table visual when tableData is available', () => {
    mockUseModelPreviewReturn.tableData = {
      data: [{ id: '1' }],
      columns: [{ key: 'id', name: 'id' }],
    } as never;
    renderWithProviders(<DefineSQL {...defaultProps} />);
    expect(screen.getByTestId('table-visual')).toBeInTheDocument();
  });

  it('calls handleMoveForward on Continue click (static method)', () => {
    mockUseModelPreviewReturn.canMoveForward = true;
    renderWithProviders(<DefineSQL {...defaultProps} />);
    fireEvent.click(screen.getByTestId('form-footer'));
    expect(mockHandleMoveForward).toHaveBeenCalledWith('defineModel', {
      query: 'SELECT * FROM users',
      id: '1',
      query_type: 'raw_sql',
      columns: undefined,
    });
  });

  it('shows harvest screen on Continue click (dynamic method)', () => {
    mockDynamicQueryStore.mockReturnValue({
      ...mockDynamicQueryStoreState,
      queryingMethod: 'dynamic_sql',
    });
    mockUseModelPreviewReturn.canMoveForward = true;
    renderWithProviders(<DefineSQL {...defaultProps} />);
    fireEvent.click(screen.getByTestId('form-footer'));
    expect(screen.getByTestId('harvest-screen')).toBeInTheDocument();
  });

  it('calls putModelById on Save Changes click in update mode', async () => {
    mockPutModelById.mockResolvedValue({ data: { id: '42' } });
    mockUseModelPreviewReturn.canMoveForward = true;
    renderWithProviders(
      <DefineSQL
        {...defaultProps}
        isUpdateButtonVisible={true}
        prefillValues={mockPrefillValues as never}
      />,
    );
    fireEvent.click(screen.getByTestId('form-footer'));

    await waitFor(() => {
      expect(mockPutModelById).toHaveBeenCalled();
    });

    await waitFor(() => {
      expect(mockShowToast).toHaveBeenCalledWith(
        expect.objectContaining({ title: 'Model updated successfully' }),
      );
    });
  });

  it('shows API errors on model update failure', async () => {
    mockPutModelById.mockResolvedValue({ errors: [{ detail: 'Bad request' }] });
    mockUseModelPreviewReturn.canMoveForward = true;
    renderWithProviders(
      <DefineSQL
        {...defaultProps}
        isUpdateButtonVisible={true}
        prefillValues={mockPrefillValues as never}
      />,
    );
    fireEvent.click(screen.getByTestId('form-footer'));

    await waitFor(() => {
      expect(mockApiErrorsToast).toHaveBeenCalled();
    });
  });

  it('shows error toast on model update network failure', async () => {
    mockPutModelById.mockRejectedValue(new Error('Network error'));
    mockUseModelPreviewReturn.canMoveForward = true;
    renderWithProviders(
      <DefineSQL
        {...defaultProps}
        isUpdateButtonVisible={true}
        prefillValues={mockPrefillValues as never}
      />,
    );
    fireEvent.click(screen.getByTestId('form-footer'));

    await waitFor(() => {
      expect(mockErrorToast).toHaveBeenCalled();
    });
  });

  it('opens dynamic variables info modal for dynamic method without prefilled values', () => {
    mockDynamicQueryStore.mockReturnValue({
      ...mockDynamicQueryStoreState,
      queryingMethod: 'dynamic_sql',
    });
    renderWithProviders(<DefineSQL {...defaultProps} />);
    expect(screen.getByTestId('dynamic-vars-info-modal')).toBeInTheDocument();
  });

  it('does not open dynamic variables info modal when hasPrefilledValues is true', () => {
    mockDynamicQueryStore.mockReturnValue({
      ...mockDynamicQueryStoreState,
      queryingMethod: 'dynamic_sql',
    });
    renderWithProviders(<DefineSQL {...defaultProps} hasPrefilledValues={true} />);
    expect(screen.queryByTestId('dynamic-vars-info-modal')).not.toBeInTheDocument();
  });

  it('renders with prefilled values', () => {
    renderWithProviders(
      <DefineSQL
        {...defaultProps}
        prefillValues={mockPrefillValues as never}
        hasPrefilledValues={true}
      />,
    );
    expect(screen.getByTestId('monaco-editor')).toBeInTheDocument();
  });

  it('opens input fields mapping modal when dynamic query has variables', () => {
    mockDynamicQueryStore.mockReturnValue({
      ...mockDynamicQueryStoreState,
      queryingMethod: 'dynamic_sql',
    });
    // Query with dynamic variables
    mockEditorRef.current.getValue.mockReturnValue('SELECT * FROM users WHERE id = :userId');
    renderWithProviders(<DefineSQL {...defaultProps} hasPrefilledValues={true} />);
    // Trigger query run - should detect :userId variable
    fireEvent.click(screen.getByTestId('query-run-btn'));
    // Input fields mapping modal should open
    expect(screen.getByTestId('input-fields-modal')).toBeInTheDocument();
  });

  it('calls getPreview via mapDynamicVariablesWithQuery when preview is clicked in mapping modal', () => {
    mockDynamicQueryStore.mockReturnValue({
      ...mockDynamicQueryStoreState,
      queryingMethod: 'dynamic_sql',
      inputSchema: [
        {
          name: 'userId',
          type: 'string',
          value: 'userId',
          value_type: 'dynamic',
          sample_input_value: 'test123',
        },
      ],
    });
    mockEditorRef.current.getValue.mockReturnValue('SELECT * FROM users WHERE id = :userId');
    renderWithProviders(<DefineSQL {...defaultProps} hasPrefilledValues={true} />);
    // Trigger query run to open mapping modal
    fireEvent.click(screen.getByTestId('query-run-btn'));
    // Click preview in mapping modal
    fireEvent.click(screen.getByTestId('preview-mapped'));
    expect(mockGetPreview).toHaveBeenCalled();
  });

  it('sets up dynamic store state from prefillValues for dynamic query type in update mode', () => {
    const dynamicPrefillValues = {
      ...mockPrefillValues,
      query_type: 'dynamic_sql',
      configuration: {
        json_schema: { input: [{ name: 'var1' }], output: [{ name: 'out1' }] },
        harvesters: [{ name: 'h1' }],
        response_format: ['col1'],
      },
    };
    mockDynamicQueryStore.mockReturnValue({
      ...mockDynamicQueryStoreState,
      queryingMethod: 'dynamic_sql',
    });
    renderWithProviders(
      <DefineSQL
        {...defaultProps}
        isUpdateButtonVisible={true}
        prefillValues={dynamicPrefillValues as never}
        hasPrefilledValues={true}
      />,
    );
    // The useEffect should have called setOutputSchema, setInputSchema, etc.
    expect(mockDynamicQueryStoreState.setOutputSchema).toHaveBeenCalled();
    expect(mockDynamicQueryStoreState.setInputSchema).toHaveBeenCalled();
    expect(mockDynamicQueryStoreState.setDynamicVariablesHarvestedMap).toHaveBeenCalled();
    expect(mockDynamicQueryStoreState.setTableColumns).toHaveBeenCalled();
  });

  it('clears dynamic store state for non-dynamic query type', () => {
    renderWithProviders(
      <DefineSQL
        {...defaultProps}
        prefillValues={mockPrefillValues as never}
        hasPrefilledValues={true}
      />,
    );
    // For static query type, useEffect should clear the store
    expect(mockDynamicQueryStoreState.setInputSchema).toHaveBeenCalledWith([]);
    expect(mockDynamicQueryStoreState.setOutputSchema).toHaveBeenCalledWith([]);
  });

  it('handles editor onChange by updating state', () => {
    renderWithProviders(<DefineSQL {...defaultProps} />);
    const editor = screen.getByTestId('monaco-editor');
    fireEvent.change(editor, { target: { value: 'SELECT id FROM orders' } });
    // The onChange should call setCanMoveForward(false) and canRunQuery(true)
    expect(mockUseModelPreviewReturn.setCanMoveForward).toHaveBeenCalledWith(false);
  });
});
