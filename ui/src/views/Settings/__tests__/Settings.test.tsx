import { screen, fireEvent } from '@testing-library/react';
import { expect } from '@jest/globals';
import '@testing-library/jest-dom/jest-globals';
import '@testing-library/jest-dom';
import Settings from '../index'; // covers barrel export
import { useRoleDataStore } from '@/enterprise/store/useRoleDataStore';
import { renderWithProviders } from '@/utils/testUtils';
import {
  adminRoleMock,
  memberRoleMock,
  viewerRoleMock,
  mockNavigate,
} from '../__mocks__/settingsMocks';

// ── Mocks ───────────────────────────────────────────────────────────

jest.mock('@/enterprise/store/useRoleDataStore', () => ({
  useRoleDataStore: jest.fn(),
}));

jest.mock('react-router-dom', () => ({
  ...jest.requireActual('react-router-dom'),
  useNavigate: () => mockNavigate,
}));

const mockUseRoleDataStore = useRoleDataStore as unknown as jest.Mock;

// ── Helpers ─────────────────────────────────────────────────────────

const renderSettings = (role: typeof adminRoleMock, route = '/settings/workspace') => {
  mockUseRoleDataStore.mockImplementation((selector: (s: unknown) => unknown) =>
    selector({ activeRole: role }),
  );
  return renderWithProviders(
    <Settings>
      <div data-testid='child-content'>child</div>
    </Settings>,
    { initialEntries: [route] },
  );
};

// ── Tests ───────────────────────────────────────────────────────────

describe('Settings', () => {
  afterEach(() => {
    jest.clearAllMocks();
  });

  it('renders all tabs for admin role (workspace, members, profile, audit, alerts, resources)', () => {
    renderSettings(adminRoleMock);

    expect(screen.getByTestId('tab-item-Workspace')).toBeInTheDocument();
    expect(screen.getByTestId('tab-item-Members')).toBeInTheDocument();
    expect(screen.getByTestId('tab-item-Profile')).toBeInTheDocument();
    expect(screen.getByTestId('tab-item-Audit Logs')).toBeInTheDocument();
    expect(screen.getByTestId('tab-item-Alerts')).toBeInTheDocument();
    expect(screen.getByTestId('tab-item-Resources')).toBeInTheDocument();
  });

  it('renders correct tabs for member role (no Members tab)', () => {
    renderSettings(memberRoleMock);

    expect(screen.getByTestId('tab-item-Workspace')).toBeInTheDocument();
    expect(screen.queryByTestId('tab-item-Members')).not.toBeInTheDocument();
    expect(screen.getByTestId('tab-item-Profile')).toBeInTheDocument();
    expect(screen.getByTestId('tab-item-Audit Logs')).toBeInTheDocument();
    expect(screen.getByTestId('tab-item-Alerts')).toBeInTheDocument();
    expect(screen.getByTestId('tab-item-Resources')).toBeInTheDocument();
  });

  it('renders minimal tabs for viewer role (no members, audit, alerts, resources)', () => {
    renderSettings(viewerRoleMock);

    expect(screen.getByTestId('tab-item-Workspace')).toBeInTheDocument();
    expect(screen.getByTestId('tab-item-Profile')).toBeInTheDocument();
    expect(screen.queryByTestId('tab-item-Members')).not.toBeInTheDocument();
    expect(screen.queryByTestId('tab-item-Audit Logs')).not.toBeInTheDocument();
    expect(screen.queryByTestId('tab-item-Alerts')).not.toBeInTheDocument();
    expect(screen.queryByTestId('tab-item-Resources')).not.toBeInTheDocument();
  });

  it('navigates when a tab is clicked', () => {
    renderSettings(adminRoleMock);

    fireEvent.click(screen.getByTestId('tab-item-Profile'));
    expect(mockNavigate).toHaveBeenCalledWith('/settings/profile', expect.any(Object));
  });

  it('switches active tab based on location', () => {
    renderSettings(viewerRoleMock, '/settings/profile');

    // Profile should be active when route matches
    expect(screen.getByTestId('tab-item-Profile').getAttribute('aria-selected')).toBe('true');
    expect(screen.getByTestId('tab-item-Workspace').getAttribute('aria-selected')).toBe('false');
  });

  it('defaults to first tab when location does not match any tab', () => {
    renderSettings(viewerRoleMock, '/settings/unknown');

    // Should default to index 0
    expect(screen.getByTestId('tab-item-Workspace').getAttribute('aria-selected')).toBe('true');
  });

  it('renders children content', () => {
    renderSettings(adminRoleMock);

    expect(screen.getByTestId('child-content')).toBeInTheDocument();
  });
});
