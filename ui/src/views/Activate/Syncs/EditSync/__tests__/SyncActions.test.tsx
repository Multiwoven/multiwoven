import { render, screen, fireEvent, waitFor } from '@testing-library/react';
import { expect, describe, it, beforeEach } from '@jest/globals';
import '@testing-library/jest-dom/jest-globals';
import '@testing-library/jest-dom';
import { MemoryRouter } from 'react-router-dom';
import { ChakraProvider } from '@chakra-ui/react';
import { QueryClient, QueryClientProvider } from '@tanstack/react-query';
import SyncActions from '../SyncActions';
import { mockNavigate } from '../../../../../../__mocks__/navigationMocks';
import * as syncsService from '@/services/syncs';

const createQueryClient = () =>
  new QueryClient({
    defaultOptions: {
      queries: {
        retry: false,
      },
    },
  });

const mockToast = jest.fn();
const mockUseParams = jest.fn(() => ({ syncId: '123' }));

jest.mock('@/services/syncs', () => ({
  deleteSync: jest.fn(),
}));

jest.mock('react-router-dom', () => {
  const actual = jest.requireActual<typeof import('react-router-dom')>('react-router-dom');
  return {
    ...actual,
    useParams: () => mockUseParams(),
    useNavigate: () => mockNavigate,
  };
});

jest.mock('@/hooks/useCustomToast', () => ({
  __esModule: true,
  default: () => mockToast,
}));

const renderComponent = () => {
  const queryClient = createQueryClient();
  return render(
    <QueryClientProvider client={queryClient}>
      <ChakraProvider>
        <MemoryRouter>
          <SyncActions />
        </MemoryRouter>
      </ChakraProvider>
    </QueryClientProvider>,
  );
};

describe('SyncActions', () => {
  beforeEach(() => {
    jest.clearAllMocks();
    mockNavigate.mockClear();
    mockToast.mockClear();
  });

  it('renders the more options button', () => {
    renderComponent();
    const button = screen.getByRole('button', { hidden: true });
    expect(button).toBeInTheDocument();
  });

  it('opens popover when button is clicked', () => {
    renderComponent();
    const trigger = screen.getByRole('button', { hidden: true });
    fireEvent.click(trigger);
    expect(screen.getByText('Delete')).toBeInTheDocument();
  });

  it('calls deleteSync and navigates on successful delete', async () => {
    (syncsService.deleteSync as jest.Mock).mockResolvedValue({} as any);
    renderComponent();

    const trigger = screen.getByRole('button', { hidden: true });
    fireEvent.click(trigger);

    const deleteButton = screen.getByText('Delete');
    fireEvent.click(deleteButton);

    await waitFor(() => {
      expect(syncsService.deleteSync).toHaveBeenCalledWith('123');
      expect(mockToast).toHaveBeenCalledWith(
        expect.objectContaining({
          title: 'Sync deleted successfully',
        }),
      );
      expect(mockNavigate).toHaveBeenCalledWith('/activate/syncs');
    });
  });

  it('shows error toast on delete failure', async () => {
    (syncsService.deleteSync as jest.Mock).mockRejectedValue(new Error('Delete failed'));
    renderComponent();

    const trigger = screen.getByRole('button', { hidden: true });
    fireEvent.click(trigger);

    const deleteButton = screen.getByText('Delete');
    fireEvent.click(deleteButton);

    await waitFor(() => {
      expect(mockToast).toHaveBeenCalledWith(
        expect.objectContaining({
          title: 'Error!!',
          description: 'Something went wrong while deleting the sync',
        }),
      );
    });
  });

  it('renders delete button with correct styling', () => {
    renderComponent();
    const trigger = screen.getByRole('button', { hidden: true });
    fireEvent.click(trigger);
    const deleteButton = screen.getByText('Delete');
    expect(deleteButton).toBeInTheDocument();
  });
});
