import React from 'react';
import { render, screen, fireEvent, waitFor } from '@testing-library/react';
import { expect, describe, it, beforeEach, jest } from '@jest/globals';
import '@testing-library/jest-dom/jest-globals';
import '@testing-library/jest-dom';
import { MemoryRouter } from 'react-router-dom';
import { ChakraProvider } from '@chakra-ui/react';
import { QueryClient, QueryClientProvider } from '@tanstack/react-query';
import FinaliseSync from '..';
import { mockNavigate } from '../../../../../../../__mocks__/navigationMocks';
import * as syncsService from '@/services/syncs';

type CreateSyncResult = Awaited<ReturnType<typeof syncsService.createSync>>;
const mockCreateSync = syncsService.createSync as jest.MockedFunction<
  typeof syncsService.createSync
>;

const createQueryClient = () =>
  new QueryClient({
    defaultOptions: {
      queries: {
        retry: false,
      },
    },
  });

const mockForms = [
  {
    stepKey: 'configureSyncs',
    data: {
      configureSyncs: {
        source_id: '1',
        destination_id: '2',
        model_id: '3',
        stream_name: 'test_stream',
        configuration: [],
      },
    },
  },
];

const mockUseSteppedForm = {
  forms: mockForms,
  stepInfo: { formKey: 'finaliseSync' },
  handleMoveForward: jest.fn(),
};

const mockToast = jest.fn();

jest.mock('react-router-dom', () => {
  const actual = jest.requireActual<typeof import('react-router-dom')>('react-router-dom');
  return {
    ...actual,
    useNavigate: () => mockNavigate,
  };
});

jest.mock('@/services/syncs', () => ({
  createSync: jest.fn(),
}));

jest.mock('@/stores/useSteppedForm', () => ({
  __esModule: true,
  default: () => mockUseSteppedForm,
}));

jest.mock('@/hooks/useCustomToast', () => ({
  __esModule: true,
  default: () => mockToast,
}));

jest.mock('@/components/ContentContainer', () => ({
  __esModule: true,
  default: ({ children }: { children: React.ReactNode }) => (
    <div data-testid='content-container'>{children}</div>
  ),
}));

jest.mock('@/components/FormFooter', () => ({
  __esModule: true,
  default: ({
    ctaName,
    ctaType,
    isCtaLoading,
    onSubmit,
  }: {
    ctaName: string;
    ctaType?: 'button' | 'reset' | 'submit';
    isCtaLoading?: boolean;
    onSubmit?: () => void;
  }) => (
    <button data-testid='form-footer' type={ctaType} disabled={isCtaLoading} onClick={onSubmit}>
      {ctaName}
    </button>
  ),
}));

jest.mock('../SyncScheduleOptionsContainer/SyncScheduleOptionsContainer', () => ({
  __esModule: true,
  default: () => <div data-testid='schedule-options'>ScheduleOptions</div>,
}));

const renderComponent = () => {
  const queryClient = createQueryClient();
  return render(
    <QueryClientProvider client={queryClient}>
      <ChakraProvider>
        <MemoryRouter>
          <FinaliseSync />
        </MemoryRouter>
      </ChakraProvider>
    </QueryClientProvider>,
  );
};

describe('FinaliseSync', () => {
  beforeEach(() => {
    jest.clearAllMocks();
    mockCreateSync.mockResolvedValue({
      data: { attributes: {} },
    } as CreateSyncResult);
  });

  it('renders content container', () => {
    renderComponent();
    expect(screen.getByTestId('content-container')).toBeInTheDocument();
  });

  it('renders sync name input', () => {
    renderComponent();
    expect(screen.getByPlaceholderText('Enter sync name')).toBeInTheDocument();
  });

  it('renders description textarea', () => {
    renderComponent();
    expect(screen.getByPlaceholderText('Enter a description')).toBeInTheDocument();
  });

  it('renders schedule options', () => {
    renderComponent();
    expect(screen.getByTestId('schedule-options')).toBeInTheDocument();
  });

  it('renders form footer', () => {
    renderComponent();
    expect(screen.getByTestId('form-footer')).toBeInTheDocument();
  });

  it('updates sync name input', () => {
    renderComponent();
    const nameInput = screen.getByPlaceholderText('Enter sync name');
    fireEvent.change(nameInput, { target: { value: 'My Sync' } });
    expect(nameInput).toHaveValue('My Sync');
  });

  it('updates description textarea', () => {
    renderComponent();
    const descTextarea = screen.getByPlaceholderText('Enter a description');
    fireEvent.change(descTextarea, { target: { value: 'Test description' } });
    expect(descTextarea).toHaveValue('Test description');
  });

  it('creates sync on form submit', async () => {
    renderComponent();
    const nameInput = screen.getByPlaceholderText('Enter sync name');
    fireEvent.change(nameInput, { target: { value: 'Test Sync' } });
    const submitButton = screen.getByTestId('form-footer');
    fireEvent.click(submitButton);

    await waitFor(
      () => {
        expect(mockCreateSync).toHaveBeenCalled();
      },
      { timeout: 3000 },
    );
  });

  it('navigates to syncs list on successful creation', async () => {
    mockCreateSync.mockResolvedValue({
      data: { attributes: {} },
    } as CreateSyncResult);
    renderComponent();
    const nameInput = screen.getByPlaceholderText('Enter sync name');
    fireEvent.change(nameInput, { target: { value: 'Test Sync' } });
    const submitButton = screen.getByTestId('form-footer');
    fireEvent.click(submitButton);

    await waitFor(() => {
      expect(mockNavigate).toHaveBeenCalledWith('/activate/syncs');
    });
  });

  it('shows error toast on creation failure', async () => {
    mockCreateSync.mockRejectedValue(new Error('Creation failed'));
    renderComponent();
    const nameInput = screen.getByPlaceholderText('Enter sync name');
    fireEvent.change(nameInput, { target: { value: 'Test Sync' } });
    const submitButton = screen.getByTestId('form-footer');
    fireEvent.click(submitButton);

    await waitFor(() => {
      expect(mockToast).toHaveBeenCalledWith(
        expect.objectContaining({
          status: 'error',
          title: 'An error occurred.',
        }),
      );
    });
  });

  it('shows warning toast for API errors', async () => {
    mockCreateSync.mockResolvedValue({
      errors: [{ detail: 'Validation error' }],
    } as CreateSyncResult);
    renderComponent();
    const nameInput = screen.getByPlaceholderText('Enter sync name');
    fireEvent.change(nameInput, { target: { value: 'Test Sync' } });
    const submitButton = screen.getByTestId('form-footer');
    fireEvent.click(submitButton);

    await waitFor(() => {
      expect(mockToast).toHaveBeenCalledWith(
        expect.objectContaining({
          status: 'warning',
          title: 'Validation Error',
        }),
      );
    });
  });

  it('submits form with null configureSyncs data', async () => {
    const originalForms = mockUseSteppedForm.forms;
    mockUseSteppedForm.forms = [{ stepKey: 'configureSyncs', data: {} }] as typeof mockForms;
    renderComponent();
    const nameInput = screen.getByPlaceholderText('Enter sync name');
    fireEvent.change(nameInput, { target: { value: 'Test Sync' } });
    fireEvent.click(screen.getByTestId('form-footer'));
    await waitFor(() => {
      expect(mockCreateSync).toHaveBeenCalled();
    });
    mockUseSteppedForm.forms = originalForms;
  });
});
