import { screen, fireEvent } from '@testing-library/react';
import { describe, it, expect, jest, beforeEach } from '@jest/globals';
import '@testing-library/jest-dom/jest-globals';

import { renderWithProviders } from '@/utils/testUtils';

import { DATABASE_ENABLE_COPY } from '../constants';
import { EmptyStateVisual } from '../EmptyStateVisual';
import { EnableState } from '../../shared/EnableState';
import { LoadingBadge } from '../../shared/LoadingBadge';
import { NoTablesState } from '../NoTablesState';
import { TableCard } from '../TableCard';
import { TablesList } from '../TablesList';

// TablesList fetches via useGetTables — mock the hook factory.
const mockUseGetTables = jest.fn();
jest.mock('@/enterprise/hooks/queries/useAppGenQueries', () => ({
  __esModule: true,
  default: () => ({
    useGetTables: (...args: unknown[]) => mockUseGetTables(...args),
  }),
}));

beforeEach(() => {
  jest.clearAllMocks();
});

describe('EmptyStateVisual', () => {
  it('renders an image with the empty-table alt text', () => {
    renderWithProviders(<EmptyStateVisual />);
    expect(screen.getByAltText('empty-table')).toBeInTheDocument();
  });
});

describe('LoadingBadge', () => {
  it('renders the passed step label', () => {
    renderWithProviders(<LoadingBadge label='Creating database' />);
    expect(screen.getByText('Creating database')).toBeInTheDocument();
  });

  it('updates the label when the prop changes', () => {
    const { rerender } = renderWithProviders(<LoadingBadge label='Step A' />);
    expect(screen.getByText('Step A')).toBeInTheDocument();
    rerender(<LoadingBadge label='Step B' />);
    expect(screen.queryByText('Step A')).not.toBeInTheDocument();
    expect(screen.getByText('Step B')).toBeInTheDocument();
  });
});

describe('NoTablesState', () => {
  it('renders the no-tables copy + the visual', () => {
    renderWithProviders(<NoTablesState />);
    expect(screen.getByText('No tables yet')).toBeInTheDocument();
    expect(screen.getByAltText('empty-table')).toBeInTheDocument();
  });
});

describe('EnableState', () => {
  const defaultProps = {
    copy: DATABASE_ENABLE_COPY,
    visual: <EmptyStateVisual />,
  };

  it('renders the idle copy and Enable button when status is idle', () => {
    const onEnable = jest.fn();
    renderWithProviders(
      <EnableState status='idle' stepLabel='' onEnable={onEnable} {...defaultProps} />,
    );
    expect(screen.getByText('AppGen Data & Logic is not enabled yet')).toBeInTheDocument();
    expect(screen.getByRole('button', { name: /Enable Data & Logic/i })).toBeInTheDocument();
    expect(screen.queryByText('Enabling AppGen Data & Logic')).not.toBeInTheDocument();
  });

  it('fires onEnable when the button is clicked', () => {
    const onEnable = jest.fn();
    renderWithProviders(
      <EnableState status='idle' stepLabel='' onEnable={onEnable} {...defaultProps} />,
    );
    fireEvent.click(screen.getByRole('button', { name: /Enable Data & Logic/i }));
    expect(onEnable).toHaveBeenCalledTimes(1);
  });

  it('applies enableButtonTestId to the Enable button when provided', () => {
    renderWithProviders(
      <EnableState
        status='idle'
        stepLabel=''
        onEnable={() => {}}
        enableButtonTestId='app-builder-enable-storage'
        {...defaultProps}
      />,
    );
    expect(screen.getByTestId('app-builder-enable-storage')).toBeInTheDocument();
    expect(screen.getByTestId('app-builder-enable-storage')).toHaveTextContent(
      /Enable Data & Logic/i,
    );
  });

  it('renders the enabling copy + LoadingBadge when status is enabling', () => {
    renderWithProviders(
      <EnableState
        status='enabling'
        stepLabel='Setting up storage'
        onEnable={() => {}}
        {...defaultProps}
      />,
    );
    expect(screen.getByText('Enabling AppGen Data & Logic')).toBeInTheDocument();
    expect(screen.getByText('Setting up storage')).toBeInTheDocument();
    expect(screen.queryByRole('button', { name: /Enable Data & Logic/i })).not.toBeInTheDocument();
  });
});

describe('TableCard', () => {
  it('renders the table name and row count (formatted with toLocaleString)', () => {
    renderWithProviders(<TableCard table={{ name: 'users', row_count: 1234 }} />);
    expect(screen.getByText('users')).toBeInTheDocument();
    expect(screen.getByText('1,234 rows')).toBeInTheDocument();
  });

  it('renders 0 rows for empty tables', () => {
    renderWithProviders(<TableCard table={{ name: 'empty', row_count: 0 }} />);
    expect(screen.getByText('0 rows')).toBeInTheDocument();
  });

  it('fires onClick when clicked', () => {
    const onClick = jest.fn();
    renderWithProviders(<TableCard table={{ name: 'users', row_count: 0 }} onClick={onClick} />);
    fireEvent.click(screen.getByText('users'));
    expect(onClick).toHaveBeenCalledTimes(1);
  });

  it('renders without crashing when onClick is omitted', () => {
    renderWithProviders(<TableCard table={{ name: 'users', row_count: 0 }} />);
    // Clicking with no handler must not throw.
    fireEvent.click(screen.getByText('users'));
    expect(screen.getByText('users')).toBeInTheDocument();
  });
});

describe('TablesList', () => {
  it('renders a Spinner while loading', () => {
    mockUseGetTables.mockReturnValue({ data: undefined, isLoading: true });
    const { container } = renderWithProviders(<TablesList appId='app-1' />);
    // Chakra's Spinner has role="status" + class chakra-spinner
    expect(container.querySelector('.chakra-spinner')).toBeInTheDocument();
  });

  it('renders the NoTablesState when the API returns zero tables', () => {
    mockUseGetTables.mockReturnValue({
      data: { data: { tables: [] } },
      isLoading: false,
    });
    renderWithProviders(<TablesList appId='app-1' />);
    expect(screen.getByText('No tables yet')).toBeInTheDocument();
  });

  it('renders one TableCard per table from the API', () => {
    mockUseGetTables.mockReturnValue({
      data: {
        data: {
          tables: [
            { name: 'users', row_count: 100 },
            { name: 'orders', row_count: 42 },
            { name: 'products', row_count: 7 },
          ],
        },
      },
      isLoading: false,
    });
    renderWithProviders(<TablesList appId='app-1' />);
    expect(screen.getByText('users')).toBeInTheDocument();
    expect(screen.getByText('orders')).toBeInTheDocument();
    expect(screen.getByText('products')).toBeInTheDocument();
    expect(screen.getByText('100 rows')).toBeInTheDocument();
    expect(screen.getByText('42 rows')).toBeInTheDocument();
    expect(screen.getByText('7 rows')).toBeInTheDocument();
  });

  it('passes selected table back through onSelectTable when a card is clicked', () => {
    const onSelectTable = jest.fn();
    mockUseGetTables.mockReturnValue({
      data: { data: { tables: [{ name: 'users', row_count: 100 }] } },
      isLoading: false,
    });
    renderWithProviders(<TablesList appId='app-1' onSelectTable={onSelectTable} />);
    fireEvent.click(screen.getByText('users'));
    expect(onSelectTable).toHaveBeenCalledWith({ name: 'users', row_count: 100 });
  });

  it('handles a missing `data.tables` field gracefully (treats as empty)', () => {
    mockUseGetTables.mockReturnValue({ data: { data: {} }, isLoading: false });
    renderWithProviders(<TablesList appId='app-1' />);
    expect(screen.getByText('No tables yet')).toBeInTheDocument();
  });
});
