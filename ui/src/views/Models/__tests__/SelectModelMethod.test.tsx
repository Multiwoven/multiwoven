import '@testing-library/jest-dom/jest-globals';
import '@testing-library/jest-dom';
import { screen, fireEvent, waitFor } from '@testing-library/react';
import { renderWithProviders } from '@/utils/testUtils';
import ModelMethod from '../ModelsForm/ModelMethod/SelectModelMethod';
import {
  mockHandleMoveForward,
  mockConnectorItem,
  mockGetCatalog,
  mockDynamicQueryStoreState,
} from '../__mocks__/modelsMocks';
import { mockStoreImplementation } from '../../../../__mocks__/commonMocks';

// ── Mocks ───────────────────────────────────────────────────────────

const mockUseStore = jest.fn();
jest.mock('@/stores', () => ({
  useStore: (...args: unknown[]) => mockUseStore(...args),
}));

jest.mock('@/stores/useSteppedForm', () => ({
  __esModule: true,
  default: () => ({
    forms: [
      {
        stepKey: 'datasource',
        data: { datasource: mockConnectorItem },
      },
      {
        stepKey: 'selectModelType',
        data: { selectModelType: { id: '1' } },
      },
    ],
    stepInfo: { formKey: 'selectModelType' },
    handleMoveForward: mockHandleMoveForward,
  }),
}));

const mockDynamicQueryStore = jest.fn();
jest.mock('@/enterprise/store/useDynamicQueryStore', () => ({
  useDynamicQueryStore: (selector: (state: unknown) => unknown) =>
    selector(mockDynamicQueryStore()),
}));

const mockUseQuery = jest.fn();
jest.mock('@tanstack/react-query', () => ({
  ...jest.requireActual('@tanstack/react-query'),
  useQuery: (opts: { queryFn: () => unknown }) => {
    if (opts?.queryFn) opts.queryFn();
    return mockUseQuery();
  },
}));

jest.mock('@/services/syncs', () => ({
  getCatalog: (...args: unknown[]) => mockGetCatalog(...args),
}));

jest.mock('@/components/ContentContainer', () => ({
  __esModule: true,
  default: ({ children }: { children: React.ReactNode }) => <div>{children}</div>,
}));

jest.mock('@/components/FormFooter', () => ({
  __esModule: true,
  default: () => <div data-testid='form-footer'>Footer</div>,
}));

jest.mock('@/components/Loader', () => ({
  __esModule: true,
  default: () => <div data-testid='loader'>Loading...</div>,
}));

jest.mock('@/components/Badge', () => ({
  __esModule: true,
  default: ({ text }: { text: string }) => <span data-testid='badge'>{text}</span>,
}));

// Mock the SelectQueryingMethodModal
jest.mock('@/enterprise/views/Define/DynamicDataModels/SelectQueryingMethod', () => ({
  __esModule: true,
  default: ({
    modalOpen,
    setQueryingMethod,
  }: {
    modalOpen: boolean;
    setModalOpen: (v: boolean) => void;
    setQueryingMethod: (method: string) => void;
  }) =>
    modalOpen ? (
      <div data-testid='select-query-modal'>
        <button data-testid='select-dynamic' onClick={() => setQueryingMethod('dynamic')}>
          Dynamic
        </button>
      </div>
    ) : null,
}));

jest.mock('@/utils', () => ({
  extractData: (forms: { data?: Record<string, unknown> }[]) => {
    return forms.map((f) => {
      if (f.data) {
        const values = Object.values(f.data);
        return values[0];
      }
      return {};
    });
  },
}));

// ── Tests ───────────────────────────────────────────────────────────

describe('SelectModelMethod', () => {
  beforeEach(() => {
    jest.clearAllMocks();
    mockStoreImplementation(mockUseStore, { workspaceId: 1 });
    mockDynamicQueryStore.mockReturnValue(mockDynamicQueryStoreState);
    mockUseQuery.mockReturnValue({
      data: {
        data: {
          attributes: {
            catalog: {
              schema_mode: 'schema',
            },
          },
        },
      },
      isLoading: false,
    });
  });

  it('renders loading state', () => {
    mockUseQuery.mockReturnValue({ data: undefined, isLoading: true });
    renderWithProviders(<ModelMethod />);
    expect(screen.getByTestId('loader')).toBeInTheDocument();
  });

  it('renders all three model methods', () => {
    renderWithProviders(<ModelMethod />);
    expect(screen.getByText('SQL Query')).toBeInTheDocument();
    expect(screen.getByText('Table Selector')).toBeInTheDocument();
    expect(screen.getByText('dbt Model')).toBeInTheDocument();
    expect(screen.getByTestId('model-method-sql')).toBeInTheDocument();
    expect(screen.getByTestId('model-method-select')).toBeInTheDocument();
    expect(screen.getByTestId('model-method-dbt')).toBeInTheDocument();
  });

  it('shows "weaving soon" badge for disabled methods', () => {
    renderWithProviders(<ModelMethod />);
    expect(screen.getByText('weaving soon')).toBeInTheDocument();
  });

  it('disables Table Selector when schema_mode is schemaless', () => {
    mockUseQuery.mockReturnValue({
      data: {
        data: {
          attributes: {
            catalog: {
              schema_mode: 'schemaless',
            },
          },
        },
      },
      isLoading: false,
    });
    renderWithProviders(<ModelMethod />);
    // Table Selector should now show "weaving soon" badge
    const badges = screen.getAllByTestId('badge');
    expect(badges.length).toBeGreaterThanOrEqual(2);
  });

  it('opens SelectQueryingMethodModal when SQL Query is clicked', () => {
    renderWithProviders(<ModelMethod />);
    fireEvent.click(screen.getByText('SQL Query'));
    expect(screen.getByTestId('select-query-modal')).toBeInTheDocument();
  });

  it('calls handleMoveForward for Table Selector click', () => {
    renderWithProviders(<ModelMethod />);
    fireEvent.click(screen.getByText('Table Selector'));
    expect(mockHandleMoveForward).toHaveBeenCalledWith('selectModelType', {
      modelMethodName: 'Table Selector',
      connectorDataType: 'structured',
    });
  });

  it('calls setQueryingMethod and handleMoveForward when query method is selected', async () => {
    renderWithProviders(<ModelMethod />);
    // Click SQL Query to open modal
    fireEvent.click(screen.getByText('SQL Query'));
    // Select Dynamic from the modal
    fireEvent.click(screen.getByTestId('select-dynamic'));

    await waitFor(() => {
      expect(mockHandleMoveForward).toHaveBeenCalledWith('selectModelType', {
        modelMethodName: 'SQL Query',
        connectorDataType: 'structured',
      });
    });
  });

  it('renders form footer', () => {
    renderWithProviders(<ModelMethod />);
    expect(screen.getByTestId('form-footer')).toBeInTheDocument();
  });
});
