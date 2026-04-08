import React from 'react';
import { render, screen, fireEvent } from '@testing-library/react';
import { expect, describe, it, beforeEach, jest } from '@jest/globals';
import '@testing-library/jest-dom/jest-globals';
import '@testing-library/jest-dom';
import { MemoryRouter } from 'react-router-dom';
import { ChakraProvider } from '@chakra-ui/react';
import { QueryClient, QueryClientProvider } from '@tanstack/react-query';
import SelectModel from '..';
import { mockHandleMoveForward } from '../../../../../../../__mocks__/connectorMocks';

const createQueryClient = () =>
  new QueryClient({
    defaultOptions: {
      queries: {
        retry: false,
      },
    },
  });

const mockUseSteppedForm = {
  stepInfo: { formKey: 'selectModel' },
  handleMoveForward: mockHandleMoveForward,
};

jest.mock('@/stores/useSteppedForm', () => ({
  __esModule: true,
  default: () => mockUseSteppedForm,
}));

jest.mock('@/components/ContentContainer', () => ({
  __esModule: true,
  default: ({ children }: { children: React.ReactNode }) => (
    <div data-testid='content-container'>{children}</div>
  ),
}));

jest.mock('@/components/ModelTable', () => ({
  __esModule: true,
  default: ({
    handleOnRowClick,
    showSearchBar,
  }: {
    handleOnRowClick: (args: {
      original: { id: string; attributes: { name: string; connector?: { name: string } } };
    }) => void;
    showSearchBar?: boolean;
  }) => (
    <div data-testid='model-table'>
      <div data-testid='search-bar'>{showSearchBar && 'Search Bar'}</div>
      <button
        data-testid='mock-row'
        onClick={() =>
          handleOnRowClick({
            original: {
              id: 'model-1',
              attributes: { name: 'Test Model', connector: { name: 'PostgreSQL' } },
            },
          })
        }
      >
        Click Row
      </button>
    </div>
  ),
}));

const renderComponent = () => {
  const queryClient = createQueryClient();
  return render(
    <QueryClientProvider client={queryClient}>
      <ChakraProvider>
        <MemoryRouter>
          <SelectModel />
        </MemoryRouter>
      </ChakraProvider>
    </QueryClientProvider>,
  );
};

describe('SelectModel', () => {
  beforeEach(() => {
    jest.clearAllMocks();
  });

  it('renders content container', () => {
    renderComponent();
    expect(screen.getByTestId('content-container')).toBeInTheDocument();
  });

  it('renders ModelTable', () => {
    renderComponent();
    expect(screen.getByTestId('model-table')).toBeInTheDocument();
  });

  it('shows search bar', () => {
    renderComponent();
    expect(screen.getByTestId('search-bar')).toBeInTheDocument();
  });

  it('calls handleMoveForward when row is clicked', () => {
    renderComponent();
    const rowButton = screen.getByTestId('mock-row');
    fireEvent.click(rowButton);
    expect(mockHandleMoveForward).toHaveBeenCalledWith('selectModel', {
      name: 'Test Model',
      connector: { name: 'PostgreSQL' },
      id: 'model-1',
    });
  });
});
