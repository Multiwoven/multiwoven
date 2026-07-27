import { screen, fireEvent } from '@testing-library/react';
import { expect, describe, it, jest, beforeEach } from '@jest/globals';
import '@testing-library/jest-dom/jest-globals';

jest.mock('react-markdown', () => ({ __esModule: true, default: () => null }));
jest.mock('remark-gfm', () => ({ __esModule: true, default: () => {} }));
jest.mock('jose', () => ({ jwtVerify: jest.fn(), SignJWT: jest.fn() }));

// RJSF pulls in `nanoid` (ESM) which the jest config doesn't transform. The
// Database section transitively imports JSONSchemaForm via CreateRowView. None
// of these tests navigate to the Add-Row screen, so stub the form out.
jest.mock('@/components/JSONSchemaForm', () => ({
  __esModule: true,
  default: () => null,
}));

jest.mock('@/enterprise/hooks/mutations/useAppGenMutations', () => ({
  __esModule: true,
  default: () => ({
    updateApp: { mutate: jest.fn(), isPending: false },
    updateAppSettings: { mutate: jest.fn(), isPending: false },
    inviteAppUsers: { mutate: jest.fn(), isPending: false },
    resendAppUserInvite: { mutate: jest.fn(), isPending: false },
    deleteAppUser: { mutate: jest.fn(), isPending: false },
    provisionDatabase: { mutate: jest.fn(), mutateAsync: jest.fn(), isPending: false },
    // Storage section pulls these — stub them so the panel renders.
    provisionStorage: { mutate: jest.fn(), mutateAsync: jest.fn(), isPending: false },
    createStorageFolder: { mutateAsync: jest.fn(), isPending: false },
    deleteStorageFolder: { mutateAsync: jest.fn(), isPending: false },
    uploadStorageFile: { mutateAsync: jest.fn(), isPending: false },
    deleteStorageFile: { mutateAsync: jest.fn(), isPending: false },
    // Secrets section stubs.
    createAppSecret: { mutateAsync: jest.fn(), isPending: false },
    updateAppSecret: { mutateAsync: jest.fn(), isPending: false },
    deleteAppSecret: { mutate: jest.fn(), isPending: false },
  }),
}));

jest.mock('@/enterprise/hooks/queries/useAppGenQueries', () => ({
  __esModule: true,
  default: () => ({
    useGetAppUsers: () => ({ data: { data: [] } }),
    useGetDatabase: () => ({
      data: { data: { attributes: { status: 'not_provisioned' } } },
      isLoading: false,
    }),
    useGetTables: () => ({ data: { data: { tables: [] } }, isLoading: false }),
    useGetStorage: () => ({
      data: { data: { attributes: { status: 'not_provisioned' } } },
      isLoading: false,
    }),
    useGetStorageFolders: () => ({ data: { data: { folders: [] } }, isLoading: false }),
    useGetStorageFiles: () => ({
      data: { data: { files: [] } },
      isLoading: false,
      isFetching: false,
      refetch: jest.fn(),
    }),
    useGetAppSecrets: () => ({ data: { data: [] } }),
  }),
}));

jest.mock('@/services/user', () => ({
  getUserProfile: jest.fn(() => Promise.resolve({ data: { attributes: { name: '', email: '' } } })),
}));

jest.mock('@/hooks/useCustomToast', () => ({
  __esModule: true,
  default: () => jest.fn(),
}));

import { renderWithProviders } from '@/utils/testUtils';
import AppSettingsModal from '../AppSettingsModal';

const baseProps = {
  openModal: true,
  setModalOpen: jest.fn(),
  appId: 'app-1',
  appName: 'My App',
  visibility: 'invited_only' as const,
  showBadge: false,
  status: 'published' as const,
};

describe('AppSettingsModal', () => {
  beforeEach(() => {
    jest.clearAllMocks();
  });

  it('renders the modal with app-builder-settings test id', () => {
    renderWithProviders(<AppSettingsModal {...baseProps} />);
    expect(screen.getByTestId('app-builder-settings')).toBeInTheDocument();
  });

  it('renders the Secrets nav with app-builder-secret test id', () => {
    renderWithProviders(<AppSettingsModal {...baseProps} />);
    expect(screen.getByTestId('app-builder-secret')).toBeInTheDocument();
    expect(screen.getByTestId('app-builder-secret')).toHaveTextContent('Secrets');
  });

  it('renders the Storage nav with app-builder-storage test id', () => {
    renderWithProviders(<AppSettingsModal {...baseProps} />);
    expect(screen.getByTestId('app-builder-storage')).toBeInTheDocument();
    expect(screen.getByTestId('app-builder-storage')).toHaveTextContent('Storage');
  });

  it('renders the close button with app-builder-close test id', () => {
    renderWithProviders(<AppSettingsModal {...baseProps} />);
    expect(screen.getByTestId('app-builder-close')).toBeInTheDocument();
  });

  it('renders the modal title and the four nav items', () => {
    renderWithProviders(<AppSettingsModal {...baseProps} />);
    expect(screen.getAllByText('App Settings').length).toBeGreaterThan(0);
    // "General" appears twice: nav row + panel heading. Confirm both render.
    expect(screen.getAllByText('General').length).toBeGreaterThanOrEqual(2);
    expect(screen.getByText('Database')).toBeInTheDocument();
    expect(screen.getByText('Secrets')).toBeInTheDocument();
    expect(screen.getByText('Storage')).toBeInTheDocument();
  });

  it('renders the Data & Logic group label above Database', () => {
    renderWithProviders(<AppSettingsModal {...baseProps} />);
    expect(screen.getByText('Data & Logic')).toBeInTheDocument();
  });

  it('renders the General panel by default', () => {
    renderWithProviders(<AppSettingsModal {...baseProps} />);
    // VisibilitySection lives in GeneralPanel
    expect(screen.getByTestId('visibility-select')).toBeInTheDocument();
  });

  it('switches to the Database panel when Database nav is clicked', () => {
    renderWithProviders(<AppSettingsModal {...baseProps} />);
    fireEvent.click(screen.getByText('Database'));
    expect(screen.getByText('View and manage the data stored in your app.')).toBeInTheDocument();
    // General panel content gone
    expect(screen.queryByTestId('visibility-select')).not.toBeInTheDocument();
  });

  it('switches to the Secrets panel when Secrets nav is clicked', () => {
    renderWithProviders(<AppSettingsModal {...baseProps} />);
    fireEvent.click(screen.getByTestId('app-builder-secret'));
    expect(
      screen.getByText(
        'Secrets are hidden values and securely save sensitive information like API keys.',
      ),
    ).toBeInTheDocument();
    expect(screen.queryByTestId('visibility-select')).not.toBeInTheDocument();
  });

  it('switches to the Storage panel when Storage nav is clicked', () => {
    renderWithProviders(<AppSettingsModal {...baseProps} />);
    fireEvent.click(screen.getByTestId('app-builder-storage'));
    expect(screen.getByText('View and manage the files stored in your app.')).toBeInTheDocument();
    expect(screen.getByTestId('app-builder-enable-storage')).toBeInTheDocument();
  });

  it('does not render any panel content when openModal is false', () => {
    renderWithProviders(<AppSettingsModal {...baseProps} openModal={false} />);
    expect(screen.queryByTestId('visibility-select')).not.toBeInTheDocument();
  });

  it('renders without error when onRepublish callback is provided', () => {
    const onRepublish = jest.fn();
    renderWithProviders(<AppSettingsModal {...baseProps} onRepublish={onRepublish} />);
    expect(screen.getAllByText('App Settings').length).toBeGreaterThan(0);
  });

  it('renders without error when onSetToDraft callback is provided', () => {
    const onSetToDraft = jest.fn();
    renderWithProviders(<AppSettingsModal {...baseProps} onSetToDraft={onSetToDraft} />);
    expect(screen.getAllByText('App Settings').length).toBeGreaterThan(0);
  });
});
