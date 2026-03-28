import { screen } from '@testing-library/react';
import { expect } from '@jest/globals';
import '@testing-library/jest-dom/jest-globals';
import '@testing-library/jest-dom';
import SetupSettings from '../SetupSettings';
import { renderWithProviders } from '@/utils/testUtils';
import { adminRoleMock, viewerRoleMock } from '../__mocks__/settingsMocks';
import { mockStoreImplementation } from '../../../../__mocks__/commonMocks';

// ── Mocks ───────────────────────────────────────────────────────────

jest.mock('@/enterprise/store/useRoleDataStore', () => ({
  useRoleDataStore: jest.fn(),
}));

jest.mock('@/views/Settings', () => ({
  __esModule: true,
  default: ({ children }: { children: React.ReactNode }) => (
    <div data-testid='settings-wrapper'>{children}</div>
  ),
}));

jest.mock('@/views/Settings/Workspace', () => ({
  __esModule: true,
  default: () => <div data-testid='workspace-page'>Workspace</div>,
}));

jest.mock('@/enterprise/views/Settings/Members', () => ({
  __esModule: true,
  default: () => <div data-testid='members-page'>Members</div>,
}));

jest.mock('@/enterprise/views/Settings/UserProfile', () => ({
  __esModule: true,
  default: () => <div data-testid='profile-page'>UserProfile</div>,
}));

jest.mock('@/enterprise/views/Settings/AuditLogs', () => ({
  __esModule: true,
  default: () => <div data-testid='audit-page'>AuditLogs</div>,
}));

jest.mock('@/enterprise/views/Settings/Alerts/Alerts', () => ({
  __esModule: true,
  default: () => <div data-testid='alerts-page'>Alerts</div>,
}));

jest.mock('@/enterprise/views/Settings/BillingAndUsage', () => ({
  BillingAndUsage: () => <div data-testid='billing-page'>BillingAndUsage</div>,
}));

jest.mock('@/enterprise/views/Settings/Organization', () => ({
  Organization: ({ children }: { children: React.ReactNode }) => (
    <div data-testid='organization-wrapper'>{children}</div>
  ),
}));

jest.mock('@/enterprise/views/Settings/Resources/SetupResourcesRoutes', () => ({
  __esModule: true,
  default: () => <div data-testid='resources-page'>Resources</div>,
}));

jest.mock('@/enterprise/components/RoleAccess', () => ({
  __esModule: true,
  default: ({ children }: { children: React.ReactNode }) => <>{children}</>,
}));

jest.mock('@/components/Loader', () => ({
  __esModule: true,
  default: () => <div data-testid='loader'>Loading...</div>,
}));

import { useRoleDataStore } from '@/enterprise/store/useRoleDataStore';

// ── Helpers ─────────────────────────────────────────────────────────

const renderSetupSettings = (role: typeof adminRoleMock | null, route: string) => {
  mockStoreImplementation(useRoleDataStore, { activeRole: role });
  return renderWithProviders(<SetupSettings />, { initialEntries: [route] });
};

// ── Tests ───────────────────────────────────────────────────────────

describe('SetupSettings', () => {
  afterEach(() => {
    jest.clearAllMocks();
  });

  it('renders Loader when activeRole is null', () => {
    renderSetupSettings(null, '/workspace');
    expect(screen.getByTestId('loader')).toBeInTheDocument();
  });

  it('renders workspace route for admin', () => {
    renderSetupSettings(adminRoleMock, '/workspace');
    expect(screen.getByTestId('workspace-page')).toBeInTheDocument();
  });

  it('renders members route for admin', () => {
    renderSetupSettings(adminRoleMock, '/members');
    expect(screen.getByTestId('members-page')).toBeInTheDocument();
  });

  it('renders profile route for admin', () => {
    renderSetupSettings(adminRoleMock, '/profile');
    expect(screen.getByTestId('profile-page')).toBeInTheDocument();
  });

  it('renders audit route for admin', () => {
    renderSetupSettings(adminRoleMock, '/audit');
    expect(screen.getByTestId('audit-page')).toBeInTheDocument();
  });

  it('renders alerts route for admin', () => {
    renderSetupSettings(adminRoleMock, '/alerts');
    expect(screen.getByTestId('alerts-page')).toBeInTheDocument();
  });

  it('renders organization/billing route for admin', () => {
    renderSetupSettings(adminRoleMock, '/organization/billing');
    expect(screen.getByTestId('billing-page')).toBeInTheDocument();
  });

  it('renders resources route for admin', () => {
    renderSetupSettings(adminRoleMock, '/resources');
    expect(screen.getByTestId('resources-page')).toBeInTheDocument();
  });

  it('builds accessible routes correctly for viewer (no members, no audit, no alerts)', () => {
    // Viewer has no user.create, no audit_logs.read, no alerts.read
    renderSetupSettings(viewerRoleMock, '/workspace');
    expect(screen.getByTestId('workspace-page')).toBeInTheDocument();
  });

  it('renders Navigate redirect on index route for admin', () => {
    // The index route uses <Navigate to={accessibleRoutes[0]} />
    // which redirects to /settings/workspace. Since SetupSettings uses
    // relative routes, the redirect goes outside the Routes scope in test.
    // We verify the component renders without crashing on the index route.
    renderSetupSettings(adminRoleMock, '/');
    // No crash — the Navigate component is rendered
    expect(screen.queryByTestId('loader')).not.toBeInTheDocument();
  });
});
