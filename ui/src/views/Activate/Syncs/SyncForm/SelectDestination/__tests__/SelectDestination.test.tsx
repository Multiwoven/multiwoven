import React from 'react';
import { render, screen, fireEvent } from '@testing-library/react';
import { expect, describe, it, beforeEach, jest } from '@jest/globals';
import '@testing-library/jest-dom/jest-globals';
import '@testing-library/jest-dom';
import { MemoryRouter } from 'react-router-dom';
import { ChakraProvider } from '@chakra-ui/react';
import { QueryClient, QueryClientProvider } from '@tanstack/react-query';
import SelectDestination from '..';
import { getUserConnectors } from '@/services/connectors';
import { mockHandleMoveForward } from '../../../../../../../__mocks__/connectorMocks';

const createQueryClient = () =>
  new QueryClient({
    defaultOptions: {
      queries: {
        retry: false,
      },
    },
  });

const mockConnectors = {
  data: [
    {
      id: '1',
      attributes: { name: 'Snowflake', connector_name: 'snowflake' },
    },
    {
      id: '2',
      attributes: { name: 'BigQuery', connector_name: 'bigquery' },
    },
  ],
};

const mockUseSteppedForm = {
  stepInfo: { formKey: 'selectDestination' },
  handleMoveForward: mockHandleMoveForward,
};

const mockUseQueryWrapper = jest.fn();

jest.mock('@/stores/useSteppedForm', () => ({
  __esModule: true,
  default: () => mockUseSteppedForm,
}));

jest.mock('@/hooks/useQueryWrapper', () => ({
  __esModule: true,
  default: (_key: unknown, queryFn?: () => unknown) => {
    if (typeof queryFn === 'function') {
      try {
        queryFn();
      } catch {
        /* expected in mock */
      }
    }
    return mockUseQueryWrapper();
  },
}));

jest.mock('@/services/connectors', () => ({
  getUserConnectors: jest.fn(),
}));

jest.mock('@/components/ContentContainer', () => ({
  __esModule: true,
  default: ({ children }: { children: React.ReactNode }) => (
    <div data-testid='content-container'>{children}</div>
  ),
}));

jest.mock('@/components/Loader', () => ({
  __esModule: true,
  default: () => <div data-testid='loader'>Loading...</div>,
}));

jest.mock('@/components/SearchBar/SearchBar', () => ({
  __esModule: true,
  default: ({
    placeholder,
    setSearchTerm,
  }: {
    placeholder: string;
    setSearchTerm: React.Dispatch<React.SetStateAction<string>>;
  }) => (
    <input
      data-testid='search-bar'
      placeholder={placeholder}
      onChange={(e) => setSearchTerm(e.target.value)}
    />
  ),
}));

jest.mock('@/components/DataTable', () => ({
  __esModule: true,
  default: ({
    data,
    onRowClick,
  }: {
    data: Array<{ attributes: { name: string } }>;
    onRowClick?: (row: { original: { attributes: { name: string } } }) => void;
  }) => (
    <table data-testid='data-table'>
      <tbody>
        {data.map((row: { attributes: { name: string } }, idx: number) => (
          <tr key={idx} onClick={() => onRowClick?.({ original: row })} data-testid={`row-${idx}`}>
            <td>{row.attributes.name}</td>
          </tr>
        ))}
      </tbody>
    </table>
  ),
}));

jest.mock('@/components/FormFooter', () => ({
  __esModule: true,
  default: ({ ctaName }: { ctaName: string }) => (
    <button data-testid='form-footer'>{ctaName}</button>
  ),
}));

jest.mock('@/views/Connectors/NoConnectors', () => ({
  __esModule: true,
  default: () => <div data-testid='no-connectors'>No Connectors</div>,
}));

const mockedGetUserConnectors = getUserConnectors as jest.MockedFunction<typeof getUserConnectors>;

const renderComponent = () => {
  const queryClient = createQueryClient();
  return render(
    <QueryClientProvider client={queryClient}>
      <ChakraProvider>
        <MemoryRouter>
          <SelectDestination />
        </MemoryRouter>
      </ChakraProvider>
    </QueryClientProvider>,
  );
};

describe('SelectDestination', () => {
  beforeEach(() => {
    jest.clearAllMocks();
    mockUseQueryWrapper.mockReturnValue({
      data: mockConnectors,
      isLoading: false,
    });
    mockedGetUserConnectors.mockResolvedValue(mockConnectors as any);
  });

  it('renders loader when loading', () => {
    mockUseQueryWrapper.mockReturnValue({
      data: undefined,
      isLoading: true,
    });
    renderComponent();
    expect(screen.getByTestId('loader')).toBeInTheDocument();
  });

  it('renders no connectors when data is empty', () => {
    mockUseQueryWrapper.mockReturnValue({
      data: { data: [] },
      isLoading: false,
    });
    renderComponent();
    expect(screen.getByTestId('no-connectors')).toBeInTheDocument();
  });

  it('renders destination table when data is available', () => {
    renderComponent();
    expect(screen.getByTestId('data-table')).toBeInTheDocument();
  });

  it('renders search bar', () => {
    renderComponent();
    expect(screen.getByTestId('search-bar')).toBeInTheDocument();
  });

  it('filters destinations by search term', () => {
    renderComponent();
    const searchInput = screen.getByTestId('search-bar');
    fireEvent.change(searchInput, { target: { value: 'Snow' } });
    expect(screen.getByText('Snowflake')).toBeInTheDocument();
    expect(screen.queryByText('BigQuery')).not.toBeInTheDocument();
  });

  it('calls handleMoveForward when row is clicked', () => {
    renderComponent();
    const row = screen.getByTestId('row-0');
    fireEvent.click(row);
    expect(mockHandleMoveForward).toHaveBeenCalledWith('selectDestination', mockConnectors.data[0]);
  });

  it('renders form footer', () => {
    renderComponent();
    expect(screen.getByTestId('form-footer')).toBeInTheDocument();
  });

  it('renders NoConnectors when destination list is empty', () => {
    mockUseQueryWrapper.mockReturnValue({
      data: { data: [] },
      isLoading: false,
    });
    renderComponent();
    expect(screen.getByTestId('no-connectors')).toBeInTheDocument();
  });

  it('renders loader inside content container when isLoading is true and data exists', () => {
    mockUseQueryWrapper.mockReturnValue({
      data: mockConnectors,
      isLoading: true,
    });
    renderComponent();
    expect(screen.getByTestId('content-container')).toBeInTheDocument();
    expect(screen.getByTestId('loader')).toBeInTheDocument();
  });
});
