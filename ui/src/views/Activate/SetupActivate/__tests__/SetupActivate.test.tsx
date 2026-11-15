import { render, screen } from '@testing-library/react';
import { expect, describe, it } from '@jest/globals';
import '@testing-library/jest-dom/jest-globals';
import '@testing-library/jest-dom';
import { MemoryRouter, Routes, Route } from 'react-router-dom';
import { ChakraProvider } from '@chakra-ui/react';
import { QueryClient, QueryClientProvider } from '@tanstack/react-query';
import SetupActivate from '..';

const createQueryClient = () =>
  new QueryClient({
    defaultOptions: {
      queries: {
        retry: false,
      },
    },
  });

// Mock the child components
jest.mock('@/views/Activate/Syncs/SyncsList', () => ({
  __esModule: true,
  default: () => <div data-testid='syncs-list'>SyncsList</div>,
}));

jest.mock('@/views/Activate/Syncs/SyncForm', () => ({
  __esModule: true,
  default: () => <div data-testid='sync-form'>SyncForm</div>,
}));

jest.mock('@/views/Activate/Syncs/ViewSync', () => ({
  __esModule: true,
  default: () => <div data-testid='view-sync'>ViewSync</div>,
}));

jest.mock('@/views/Activate/Syncs/SyncRecords', () => ({
  __esModule: true,
  default: () => <div data-testid='sync-records'>SyncRecords</div>,
}));

jest.mock('@/enterprise/utils/withRoleAccess', () => ({
  withRoleAccess: (component: React.ReactElement) => component,
}));

const renderWithRouter = (initialEntries: string[] = ['/activate/syncs']) => {
  const queryClient = createQueryClient();
  return render(
    <QueryClientProvider client={queryClient}>
      <ChakraProvider>
        <MemoryRouter initialEntries={initialEntries}>
          <Routes>
            <Route path='/activate/*' element={<SetupActivate />} />
          </Routes>
        </MemoryRouter>
      </ChakraProvider>
    </QueryClientProvider>,
  );
};

describe('SetupActivate', () => {
  describe('Route Configuration', () => {
    it('renders SyncsList at /activate/syncs', () => {
      renderWithRouter(['/activate/syncs']);
      expect(screen.getByTestId('syncs-list')).toBeInTheDocument();
    });

    it('renders SyncForm at /activate/syncs/new', () => {
      renderWithRouter(['/activate/syncs/new']);
      expect(screen.getByTestId('sync-form')).toBeInTheDocument();
    });

    it('renders ViewSync at /activate/syncs/:syncId', () => {
      renderWithRouter(['/activate/syncs/123']);
      expect(screen.getByTestId('view-sync')).toBeInTheDocument();
    });

    it('renders SyncRecords at /activate/syncs/:syncId/run/:syncRunId', () => {
      renderWithRouter(['/activate/syncs/123/run/456']);
      expect(screen.getByTestId('sync-records')).toBeInTheDocument();
    });

    it('redirects unknown paths to /activate/syncs', () => {
      renderWithRouter(['/activate/unknown']);
      expect(screen.getByTestId('syncs-list')).toBeInTheDocument();
    });

    it('handles nested sync routes correctly', () => {
      renderWithRouter(['/activate/syncs/123']);
      expect(screen.getByTestId('view-sync')).toBeInTheDocument();
    });
  });
});
