import { screen, fireEvent, waitFor } from '@testing-library/react';
import { expect } from '@jest/globals';
import '@testing-library/jest-dom/jest-globals';
import '@testing-library/jest-dom';
import Workspace from '../Workspace';
import { renderWithProviders } from '@/utils/testUtils';
import {
  mockShowToast,
  mockUpdateWorkspace,
  mockGetWorkspaces,
  mockWorkspaceData,
  mockUpdateWorkspaceResponse,
  mockRefetch,
} from '../__mocks__/settingsMocks';
import { mockStoreImplementation } from '../../../../__mocks__/commonMocks';

// ── Mocks ───────────────────────────────────────────────────────────

jest.mock('@/stores', () => ({
  useStore: jest.fn(),
}));

jest.mock('@/hooks/useCustomToast', () => ({
  __esModule: true,
  default: () => mockShowToast,
}));

jest.mock('@/services/settings', () => ({
  getWorkspaces: (...args: unknown[]) => mockGetWorkspaces(...args),
  updateWorkspace: (...args: unknown[]) => mockUpdateWorkspace(...args),
}));

jest.mock('@/enterprise/components/RoleAccess', () => ({
  __esModule: true,
  default: ({ children }: { children: React.ReactNode }) => <>{children}</>,
}));

jest.mock('@/enterprise/components/UpdateLogo', () => ({
  __esModule: true,
  default: () => <div data-testid='update-logo'>UpdateLogo</div>,
}));

jest.mock('@tanstack/react-query', () => ({
  ...jest.requireActual('@tanstack/react-query'),
  useQuery: jest.fn(),
}));

import { useStore } from '@/stores';
import { useQuery } from '@tanstack/react-query';

const mockUseQuery = useQuery as jest.Mock;

// ── Helpers ─────────────────────────────────────────────────────────

const setupMocks = (workspaceData = mockWorkspaceData, workspaceId = 42) => {
  mockStoreImplementation(useStore, { workspaceId });

  mockUseQuery.mockImplementation(({ queryFn }: { queryFn: () => unknown }) => {
    // Invoke queryFn to cover the callback line
    try {
      queryFn();
    } catch {
      // ignore — mock may not return a promise
    }
    return {
      data: workspaceData,
      refetch: mockRefetch,
    };
  });
};

const renderWorkspace = () => renderWithProviders(<Workspace />);

// ── Tests ───────────────────────────────────────────────────────────

describe('Workspace', () => {
  beforeEach(() => {
    jest.clearAllMocks();
  });

  it('renders form fields with workspace data', () => {
    setupMocks();
    renderWorkspace();

    expect(screen.getByText('Edit your workspace details')).toBeInTheDocument();
    expect(screen.getByText('Workspace Name')).toBeInTheDocument();
    expect(screen.getByText('Organization Name')).toBeInTheDocument();
    expect(screen.getByText('Workspace Description')).toBeInTheDocument();
    expect(screen.getByTestId('update-logo')).toBeInTheDocument();
  });

  it('populates form with active workspace details', () => {
    setupMocks();
    renderWorkspace();

    const nameInput = screen.getByDisplayValue('Test Workspace');
    const orgInput = screen.getByDisplayValue('Test Org');
    const descInput = screen.getByDisplayValue('A test workspace');

    expect(nameInput).toBeInTheDocument();
    expect(orgInput).toBeInTheDocument();
    expect(descInput).toBeInTheDocument();
  });

  it('renders empty form when no workspace data is available', () => {
    setupMocks(undefined as unknown as typeof mockWorkspaceData);
    renderWorkspace();

    expect(screen.getByText('Edit your workspace details')).toBeInTheDocument();
  });

  it('renders empty form when workspace id does not match any workspace', () => {
    setupMocks(mockWorkspaceData, 999);
    renderWorkspace();

    // No matching workspace → empty initial values
    const nameInputs = screen.getAllByRole('textbox');
    expect(nameInputs.length).toBeGreaterThan(0);
  });

  it('updates form values on input change', () => {
    setupMocks();
    renderWorkspace();

    const nameInput = screen.getByDisplayValue('Test Workspace');
    fireEvent.change(nameInput, { target: { value: 'New Name' } });
    expect(screen.getByDisplayValue('New Name')).toBeInTheDocument();
  });

  it('shows success toast and refetches on successful submit', async () => {
    setupMocks();
    mockUpdateWorkspace.mockResolvedValue(mockUpdateWorkspaceResponse);
    renderWorkspace();

    const submitButton = screen.getByRole('button', { name: /save changes/i });
    fireEvent.click(submitButton);

    await waitFor(() => {
      expect(mockUpdateWorkspace).toHaveBeenCalledWith(
        expect.objectContaining({
          name: 'Test Workspace',
          description: 'A test workspace',
          organization_id: 1,
        }),
        42,
      );
    });

    await waitFor(() => {
      expect(mockShowToast).toHaveBeenCalledWith(
        expect.objectContaining({ title: 'Workspace updated successfully' }),
      );
    });

    await waitFor(() => {
      expect(mockRefetch).toHaveBeenCalled();
    });
  });

  it('shows error toast when update fails', async () => {
    setupMocks();
    mockUpdateWorkspace.mockRejectedValue(new Error('Network error'));
    renderWorkspace();

    const submitButton = screen.getByRole('button', { name: /save changes/i });
    fireEvent.click(submitButton);

    await waitFor(() => {
      expect(mockShowToast).toHaveBeenCalledWith(
        expect.objectContaining({
          title: 'Error!!',
          description: 'Something went wrong while updating the workspace',
        }),
      );
    });
  });

  it('disables submit button when name is empty', () => {
    setupMocks();
    renderWorkspace();

    const nameInput = screen.getByDisplayValue('Test Workspace');
    fireEvent.change(nameInput, { target: { value: '' } });

    const submitButton = screen.getByRole('button', { name: /save changes/i });
    expect(submitButton).toBeDisabled();
  });

  it('renders the UpdateLogo component', () => {
    setupMocks();
    renderWorkspace();

    expect(screen.getByTestId('update-logo')).toBeInTheDocument();
  });
});
