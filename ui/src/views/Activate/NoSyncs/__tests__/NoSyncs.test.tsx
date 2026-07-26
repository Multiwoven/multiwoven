import { render, screen, fireEvent } from '@testing-library/react';
import { expect, describe, it, beforeEach } from '@jest/globals';
import '@testing-library/jest-dom/jest-globals';
import '@testing-library/jest-dom';
import { MemoryRouter } from 'react-router-dom';
import { ChakraProvider } from '@chakra-ui/react';
import { QueryClient, QueryClientProvider } from '@tanstack/react-query';
import NoActivations from '..';
import { ActivationType } from '../NoSyncs';
import { useRoleDataStore } from '@/enterprise/store/useRoleDataStore';
import { hasActionPermission } from '@/enterprise/utils/accessControlPermission';
import type { RoleItem } from '@/enterprise/services/types';
import { mockStoreImplementation } from '../../../../../__mocks__/commonMocks';

const createQueryClient = () =>
  new QueryClient({
    defaultOptions: {
      queries: {
        retry: false,
      },
    },
  });

const mockNavigate = jest.fn();

jest.mock('react-router-dom', () => ({
  ...jest.requireActual('react-router-dom'),
  useNavigate: () => mockNavigate,
}));

jest.mock('@/enterprise/store/useRoleDataStore');
jest.mock('@/enterprise/utils/accessControlPermission');
jest.mock('@/enterprise/views/NoAccess', () => ({
  __esModule: true,
  default: () => <div data-testid='no-access'>No Access</div>,
}));

const mockedUseRoleDataStore = useRoleDataStore as jest.MockedFunction<typeof useRoleDataStore>;
const mockedHasActionPermission = hasActionPermission as jest.MockedFunction<
  typeof hasActionPermission
>;

const renderComponent = (props = {}) => {
  const queryClient = createQueryClient();
  return render(
    <QueryClientProvider client={queryClient}>
      <ChakraProvider>
        <MemoryRouter>
          <NoActivations activationType={ActivationType.Sync} {...props} />
        </MemoryRouter>
      </ChakraProvider>
    </QueryClientProvider>,
  );
};

describe('NoActivations', () => {
  beforeEach(() => {
    jest.clearAllMocks();
    mockNavigate.mockClear();
    mockStoreImplementation(mockedUseRoleDataStore, { activeRole: {} as RoleItem });
    mockedHasActionPermission.mockReturnValue(true);
  });

  it('renders the component with correct heading', () => {
    renderComponent();
    expect(screen.getByText('No Syncs found')).toBeInTheDocument();
  });

  it('displays description when user has sync creation permission', () => {
    mockedHasActionPermission.mockReturnValue(true);
    renderComponent();
    expect(
      screen.getByText(
        'Add a Sync to declare how you want query results from a Model to appear in your destination',
      ),
    ).toBeInTheDocument();
  });

  it('displays different description when user lacks sync creation permission', () => {
    mockedHasActionPermission.mockReturnValue(false);
    renderComponent();
    expect(
      screen.getByText(
        'You will be able to view the data on this page once the admin configures it',
      ),
    ).toBeInTheDocument();
  });

  it('renders Add Sync button when user has permission', () => {
    mockedHasActionPermission.mockReturnValue(true);
    renderComponent();
    const addButton = screen.getByText('Add Sync');
    expect(addButton).toBeInTheDocument();
  });

  it('navigates to new sync page when Add Sync button is clicked', () => {
    mockedHasActionPermission.mockReturnValue(true);
    renderComponent();
    const addButton = screen.getByText('Add Sync');
    fireEvent.click(addButton);
    expect(mockNavigate).toHaveBeenCalledWith('new');
  });

  it('renders image for Sync activation type', () => {
    renderComponent();
    const image = screen.getByRole('img');
    expect(image).toBeInTheDocument();
    expect(image).toHaveAttribute('src');
  });

  it('renders NoAccess when activeRole is null', () => {
    mockStoreImplementation(mockedUseRoleDataStore, { activeRole: null });
    renderComponent();
    expect(screen.getByTestId('no-access')).toBeInTheDocument();
  });

  it('handles different activation types correctly', () => {
    renderComponent({ activationType: ActivationType.Sync });
    expect(screen.getByText('No Syncs found')).toBeInTheDocument();
  });

  it('renders null description for non-sync activationType', () => {
    renderComponent({ activationType: 'Other' as ActivationType });
    expect(screen.getByText('No Others found')).toBeInTheDocument();
    expect(
      screen.queryByText(
        'Add a Sync to declare how you want query results from a Model to appear in your destination',
      ),
    ).not.toBeInTheDocument();
  });

  it('renders empty image src for non-sync activationType', () => {
    renderComponent({ activationType: 'Other' as ActivationType });
    const image = screen.getByRole('img');
    expect(image).toHaveAttribute('src', '');
  });
});
