import '@testing-library/jest-dom/jest-globals';
import '@testing-library/jest-dom';
import { screen, fireEvent } from '@testing-library/react';
import { renderWithProviders } from '@/utils/testUtils';
import QueryBox from '../ModelsForm/DefineModel/QueryBox';

// ── Mocks ───────────────────────────────────────────────────────────

jest.mock('../ModelsForm/DefineModel/RefreshModelCatalog', () => ({
  __esModule: true,
  default: () => <div data-testid='refresh-catalog'>Refresh</div>,
}));

jest.mock('@/components/SearchBar/SearchBar', () => ({
  __esModule: true,
  default: ({ setSearchTerm }: { setSearchTerm: (v: string) => void }) => (
    <input data-testid='search-bar' onChange={(e) => setSearchTerm(e.target.value)} />
  ),
}));

// ── Tests ───────────────────────────────────────────────────────────

describe('QueryBox', () => {
  const mockHandleQueryRun = jest.fn();

  const defaultProps = {
    connectorIcon: <span data-testid='connector-icon'>Icon</span>,
    connectorId: '1',
    handleQueryRun: mockHandleQueryRun,
    runQuery: true,
    loading: false,
    children: <div data-testid='children'>Content</div>,
  };

  beforeEach(() => {
    jest.clearAllMocks();
  });

  it('renders connector icon and children', () => {
    renderWithProviders(<QueryBox {...defaultProps} />);
    expect(screen.getByTestId('connector-icon')).toBeInTheDocument();
    expect(screen.getByTestId('children')).toBeInTheDocument();
  });

  it('renders Show Preview button', () => {
    renderWithProviders(<QueryBox {...defaultProps} />);
    const runBtn = screen.getByTestId('query-run-button');
    expect(runBtn).toHaveTextContent('Show Preview');
  });

  it('calls handleQueryRun on Show Preview click', () => {
    renderWithProviders(<QueryBox {...defaultProps} />);
    fireEvent.click(screen.getByTestId('query-run-button'));
    expect(mockHandleQueryRun).toHaveBeenCalled();
  });

  it('disables Show Preview when runQuery is false', () => {
    renderWithProviders(<QueryBox {...defaultProps} runQuery={false} />);
    expect(screen.getByTestId('query-run-button')).toBeDisabled();
  });

  it('renders search bar when showSearchBar is true', () => {
    const setSearchTerm = jest.fn();
    renderWithProviders(<QueryBox {...defaultProps} showSearchBar setSearchTerm={setSearchTerm} />);
    expect(screen.getByTestId('search-bar')).toBeInTheDocument();
  });

  it('does not render search bar when showSearchBar is false', () => {
    renderWithProviders(<QueryBox {...defaultProps} />);
    expect(screen.queryByTestId('search-bar')).not.toBeInTheDocument();
  });

  it('renders extra content when provided', () => {
    renderWithProviders(
      <QueryBox {...defaultProps} extra={<div data-testid='extra'>Extra</div>} />,
    );
    expect(screen.getByTestId('extra')).toBeInTheDocument();
  });

  it('renders RefreshModelCatalog', () => {
    renderWithProviders(<QueryBox {...defaultProps} />);
    expect(screen.getByTestId('refresh-catalog')).toBeInTheDocument();
  });
});
