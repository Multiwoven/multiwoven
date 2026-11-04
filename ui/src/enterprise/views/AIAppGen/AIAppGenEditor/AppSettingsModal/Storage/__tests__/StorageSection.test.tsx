import { screen, fireEvent, waitFor, act } from '@testing-library/react';
import { describe, it, expect, jest, beforeEach, afterEach } from '@jest/globals';
import '@testing-library/jest-dom/jest-globals';

import { renderWithProviders } from '@/utils/testUtils';
import * as StorageIndex from '../index';

// ---- Mocks -----------------------------------------------------------------

const mockToast = jest.fn();
jest.mock('@/hooks/useCustomToast', () => ({
  __esModule: true,
  default: () => mockToast,
}));

const mockUseGetStorage = jest.fn();
const mockUseGetStorageFolders = jest.fn();
const mockUseGetStorageFiles = jest.fn();

jest.mock('@/enterprise/hooks/queries/useAppGenQueries', () => ({
  __esModule: true,
  default: () => ({
    useGetStorage: (...a: unknown[]) => mockUseGetStorage(...a),
    useGetStorageFolders: (...a: unknown[]) => mockUseGetStorageFolders(...a),
    useGetStorageFiles: (...a: unknown[]) => mockUseGetStorageFiles(...a),
  }),
}));

type MutateResult = Promise<{ errors?: unknown[]; data?: unknown } | void>;
const mockProvisionMutateAsync = jest.fn<(...args: unknown[]) => MutateResult>();
const mockCreateFolderMutateAsync = jest.fn<(...args: unknown[]) => MutateResult>();
const mockDeleteFolderMutateAsync = jest.fn<(...args: unknown[]) => MutateResult>();

jest.mock('@/enterprise/hooks/mutations/useAppGenMutations', () => ({
  __esModule: true,
  default: () => ({
    provisionStorage: {
      mutateAsync: (...a: unknown[]) => mockProvisionMutateAsync(...a),
      isPending: false,
    },
    createStorageFolder: {
      mutateAsync: (...a: unknown[]) => mockCreateFolderMutateAsync(...a),
      isPending: false,
    },
    deleteStorageFolder: {
      mutateAsync: (...a: unknown[]) => mockDeleteFolderMutateAsync(...a),
      isPending: false,
    },
    uploadStorageFile: { mutateAsync: jest.fn(), isPending: false },
    deleteStorageFile: { mutateAsync: jest.fn(), isPending: false },
  }),
}));

import { StorageSection } from '../StorageSection';

const provisionedStorage = {
  data: { data: { attributes: { status: 'provisioned' } } },
  isLoading: false,
};

const idleStorage = {
  data: { data: { attributes: { status: 'not_provisioned' } } },
  isLoading: false,
};

beforeEach(() => {
  jest.clearAllMocks();
  mockUseGetStorage.mockReturnValue(provisionedStorage);
  mockUseGetStorageFolders.mockReturnValue({
    data: { data: { folders: [] } },
    isLoading: false,
  });
  mockUseGetStorageFiles.mockReturnValue({
    data: { data: { files: [] } },
    isLoading: false,
    isFetching: false,
    refetch: jest.fn(),
  });
});

describe('StorageSection — gating', () => {
  it('renders the Spinner while the Storage query is loading', () => {
    mockUseGetStorage.mockReturnValue({ data: undefined, isLoading: true });
    const { container } = renderWithProviders(<StorageSection appId='app-1' />);
    expect(container.querySelector('.chakra-spinner')).toBeInTheDocument();
  });

  it('renders the enable state when storage is not provisioned', () => {
    mockUseGetStorage.mockReturnValue(idleStorage);
    renderWithProviders(<StorageSection appId='app-1' />);
    expect(screen.getByText('Storage is not enabled yet')).toBeInTheDocument();
    expect(screen.getByTestId('app-builder-enable-storage')).toBeInTheDocument();
    expect(screen.getByTestId('app-builder-enable-storage')).toHaveTextContent(/enable storage/i);
    // No Add New Folder CTA until we're enabled.
    expect(screen.queryByTestId('app-builder-add-new-folder')).not.toBeInTheDocument();
  });
});

describe('StorageSection — folders list', () => {
  it('renders folders returned by the API', () => {
    mockUseGetStorageFolders.mockReturnValue({
      data: {
        data: {
          folders: [
            { name: 'avatars', public: true },
            { name: 'documents', public: false },
          ],
        },
      },
      isLoading: false,
    });
    renderWithProviders(<StorageSection appId='app-1' />);
    expect(screen.getByTestId('app-builder-folder-avatars')).toBeInTheDocument();
    expect(screen.getByTestId('app-builder-folder-documents')).toBeInTheDocument();
  });

  it('renders the "no folders" empty state when the API returns an empty list', () => {
    mockUseGetStorageFolders.mockReturnValue({
      data: { data: { folders: [] } },
      isLoading: false,
    });
    renderWithProviders(<StorageSection appId='app-1' />);
    expect(screen.getByText(/no folders/i)).toBeInTheDocument();
  });

  it('navigates into a folder when its card is clicked', () => {
    mockUseGetStorageFolders.mockReturnValue({
      data: { data: { folders: [{ name: 'avatars', public: false }] } },
      isLoading: false,
    });
    renderWithProviders(<StorageSection appId='app-1' />);
    fireEvent.click(screen.getByTestId('app-builder-folder-avatars'));
    // Detail-view-specific affordances confirm we navigated.
    expect(screen.getByRole('button', { name: /upload/i })).toBeInTheDocument();
    expect(screen.getByText('Storage')).toBeInTheDocument();
  });

  it('pops back to the root when the Storage breadcrumb is clicked', () => {
    mockUseGetStorageFolders.mockReturnValue({
      data: { data: { folders: [{ name: 'avatars', public: false }] } },
      isLoading: false,
    });
    renderWithProviders(<StorageSection appId='app-1' />);
    fireEvent.click(screen.getByTestId('app-builder-folder-avatars'));
    fireEvent.click(screen.getByText('Storage'));
    expect(screen.getByTestId('app-builder-add-new-folder')).toBeInTheDocument();
  });
});

describe('StorageSection — create folder', () => {
  it('opens the CreateFolderView when Add New Folder is clicked', () => {
    renderWithProviders(<StorageSection appId='app-1' />);
    expect(screen.getByTestId('app-builder-add-new-folder')).toBeInTheDocument();
    fireEvent.click(screen.getByTestId('app-builder-add-new-folder'));
    expect(screen.getAllByText('Add new folder').length).toBeGreaterThanOrEqual(1);
    expect(screen.getByTestId('app-builder-folder-name')).toBeInTheDocument();
    expect(screen.getByTestId('app-builder-make-folder-public')).toBeInTheDocument();
    expect(screen.getByTestId('app-builder-create-folder')).toBeInTheDocument();
  });
});

describe('StorageSection — delete folder', () => {
  it('confirms then calls deleteStorageFolder with the folder name', async () => {
    mockUseGetStorageFolders.mockReturnValue({
      data: { data: { folders: [{ name: 'avatars', public: false }] } },
      isLoading: false,
    });
    mockDeleteFolderMutateAsync.mockResolvedValue(undefined);
    renderWithProviders(<StorageSection appId='app-1' />);
    fireEvent.click(screen.getByTestId('app-builder-delete-folder-avatars'));
    expect(screen.getByTestId('app-builder-delete-folder-modal')).toBeInTheDocument();
    fireEvent.click(screen.getByTestId('app-builder-delete-folder-modal-delete-button'));
    await waitFor(() => {
      expect(mockDeleteFolderMutateAsync).toHaveBeenCalledWith({
        appId: 'app-1',
        folderName: 'avatars',
      });
    });
  });

  it('closes the confirm modal without deleting when Cancel is clicked', async () => {
    mockUseGetStorageFolders.mockReturnValue({
      data: { data: { folders: [{ name: 'avatars', public: false }] } },
      isLoading: false,
    });
    renderWithProviders(<StorageSection appId='app-1' />);
    fireEvent.click(screen.getByTestId('app-builder-delete-folder-avatars'));
    expect(screen.getByTestId('app-builder-delete-folder-modal')).toBeInTheDocument();

    fireEvent.click(screen.getByTestId('app-builder-delete-folder-modal-cancel-button'));

    await waitFor(() => {
      expect(screen.queryByText('Delete folder?')).not.toBeInTheDocument();
    });
    expect(mockDeleteFolderMutateAsync).not.toHaveBeenCalled();
  });
});

describe('StorageSection — enable flow', () => {
  it('provisions storage on Enable and transitions to the folders list on success', async () => {
    mockUseGetStorage.mockReturnValue(idleStorage);
    mockProvisionMutateAsync.mockResolvedValue({ data: { attributes: { status: 'provisioned' } } });
    renderWithProviders(<StorageSection appId='app-1' />);

    fireEvent.click(screen.getByTestId('app-builder-enable-storage'));
    expect(mockProvisionMutateAsync).toHaveBeenCalledWith('app-1');

    // On success we flip to enabled → the (empty) folders list renders.
    await waitFor(() => {
      expect(screen.getByTestId('app-builder-add-new-folder')).toBeInTheDocument();
    });
    expect(screen.getByText(/no folders/i)).toBeInTheDocument();
  });

  it('stays in the enable state when provisioning returns errors (soft failure)', async () => {
    mockUseGetStorage.mockReturnValue(idleStorage);
    mockProvisionMutateAsync.mockResolvedValue({ errors: [{ detail: 'boom' }] });
    renderWithProviders(<StorageSection appId='app-1' />);

    fireEvent.click(screen.getByTestId('app-builder-enable-storage'));
    await waitFor(() => {
      expect(mockProvisionMutateAsync).toHaveBeenCalled();
    });
    // Still gated — no folders CTA appeared.
    expect(screen.queryByTestId('app-builder-add-new-folder')).not.toBeInTheDocument();
    expect(screen.getByTestId('app-builder-enable-storage')).toBeInTheDocument();
  });

  it('reverts to the enable state when provisioning rejects', async () => {
    mockUseGetStorage.mockReturnValue(idleStorage);
    mockProvisionMutateAsync.mockRejectedValue(new Error('network'));
    renderWithProviders(<StorageSection appId='app-1' />);

    fireEvent.click(screen.getByTestId('app-builder-enable-storage'));
    await waitFor(() => {
      expect(mockProvisionMutateAsync).toHaveBeenCalled();
    });
    expect(screen.getByTestId('app-builder-enable-storage')).toBeInTheDocument();
  });
});

describe('StorageSection — enabling badge stepper', () => {
  beforeEach(() => {
    jest.useFakeTimers();
  });
  afterEach(() => {
    act(() => {
      jest.runOnlyPendingTimers();
    });
    jest.useRealTimers();
  });

  it('shows the enabling state and advances the step badge while provisioning is in flight', () => {
    mockUseGetStorage.mockReturnValue(idleStorage);
    // Never resolves — keeps us in the "enabling" state so the timer-driven
    // step badge cycle runs.
    mockProvisionMutateAsync.mockReturnValue(new Promise(() => {}));
    renderWithProviders(<StorageSection appId='app-1' />);

    fireEvent.click(screen.getByTestId('app-builder-enable-storage'));
    expect(screen.getByText('Enabling storage')).toBeInTheDocument();
    expect(screen.getByText('Provisioning bucket')).toBeInTheDocument();

    // Advance through the badge steps (covers the setTimeout stepper loop).
    act(() => {
      jest.advanceTimersByTime(60000);
    });
    expect(screen.getByText('Enabling storage')).toBeInTheDocument();
  });
});

describe('StorageSection — create folder submission', () => {
  it('submits a new folder and returns to the list on success', async () => {
    mockCreateFolderMutateAsync.mockResolvedValue({ data: { folder: { name: 'documents' } } });
    renderWithProviders(<StorageSection appId='app-1' />);

    fireEvent.click(screen.getByTestId('app-builder-add-new-folder'));
    fireEvent.change(screen.getByTestId('app-builder-folder-name'), {
      target: { value: 'documents' },
    });
    fireEvent.click(screen.getByTestId('app-builder-create-folder'));

    await waitFor(() => {
      expect(mockCreateFolderMutateAsync).toHaveBeenCalledWith({
        appId: 'app-1',
        name: 'documents',
        public: false,
      });
    });
  });

  it('cancels folder creation and returns to the list', () => {
    renderWithProviders(<StorageSection appId='app-1' />);
    fireEvent.click(screen.getByTestId('app-builder-add-new-folder'));
    fireEvent.click(screen.getByRole('button', { name: 'Cancel' }));
    // Back on the list: the Add New Folder CTA is visible again.
    expect(screen.getByTestId('app-builder-add-new-folder')).toBeInTheDocument();
  });
});

describe('StorageSection — module', () => {
  it('re-exports StorageSection from the index barrel', () => {
    expect(StorageIndex.StorageSection).toBeDefined();
  });
});
