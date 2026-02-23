import { render, screen } from '@testing-library/react';
import { expect, describe, it } from '@jest/globals';
import '@testing-library/jest-dom/jest-globals';
import '@testing-library/jest-dom';
import { MemoryRouter } from 'react-router-dom';
import { ChakraProvider } from '@chakra-ui/react';
import { QueryClient, QueryClientProvider } from '@tanstack/react-query';
import SyncForm from '..';

const createQueryClient = () =>
  new QueryClient({
    defaultOptions: {
      queries: {
        retry: false,
      },
    },
  });

jest.mock('../SelectModel', () => ({
  __esModule: true,
  default: () => <div data-testid='select-model'>SelectModel</div>,
}));

jest.mock('../SelectDestination', () => ({
  __esModule: true,
  default: () => <div data-testid='select-destination'>SelectDestination</div>,
}));

jest.mock('../ConfigureSyncs', () => ({
  __esModule: true,
  default: () => <div data-testid='configure-syncs'>ConfigureSyncs</div>,
}));

jest.mock('../FinaliseSync', () => ({
  __esModule: true,
  default: () => <div data-testid='finalise-sync'>FinaliseSync</div>,
}));

jest.mock('@/components/SteppedFormDrawer', () => ({
  __esModule: true,
  default: ({ steps }: { steps: Array<{ formKey: string; name: string }> }) => (
    <div data-testid='stepped-form-drawer'>
      {steps.map((step, index) => (
        <div key={index} data-testid={`step-${step.formKey}`}>
          {step.name}
        </div>
      ))}
    </div>
  ),
}));

const renderComponent = () => {
  const queryClient = createQueryClient();
  return render(
    <QueryClientProvider client={queryClient}>
      <ChakraProvider>
        <MemoryRouter>
          <SyncForm />
        </MemoryRouter>
      </ChakraProvider>
    </QueryClientProvider>,
  );
};

describe('SyncForm', () => {
  it('renders stepped form drawer with all steps', () => {
    renderComponent();
    expect(screen.getByTestId('stepped-form-drawer')).toBeInTheDocument();
  });

  it('includes Select Model step', () => {
    renderComponent();
    expect(screen.getByTestId('step-selectModel')).toBeInTheDocument();
    expect(screen.getByText('Select a Model')).toBeInTheDocument();
  });

  it('includes Select Destination step', () => {
    renderComponent();
    expect(screen.getByTestId('step-selectDestination')).toBeInTheDocument();
    expect(screen.getByText('Select a Destination')).toBeInTheDocument();
  });

  it('includes Configure Sync step', () => {
    renderComponent();
    expect(screen.getByTestId('step-configureSyncs')).toBeInTheDocument();
    expect(screen.getByText('Configure Sync')).toBeInTheDocument();
  });

  it('includes Finalize Sync step', () => {
    renderComponent();
    expect(screen.getByTestId('step-finaliseSync')).toBeInTheDocument();
    expect(screen.getByText('Finalize Sync')).toBeInTheDocument();
  });

  it('has correct number of steps', () => {
    renderComponent();
    const steps = screen.getAllByTestId(/^step-/);
    expect(steps.length).toBe(4);
  });
});
