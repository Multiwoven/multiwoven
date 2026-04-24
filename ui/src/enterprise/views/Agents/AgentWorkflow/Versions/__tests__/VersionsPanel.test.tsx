import { render, screen, fireEvent, waitFor } from '@testing-library/react';
import { expect, describe, it, beforeEach } from '@jest/globals';
import '@testing-library/jest-dom/jest-globals';
import '@testing-library/jest-dom';
import VersionsPanel from '../VersionsPanel';
import { ChakraProvider } from '@chakra-ui/react';
import { QueryClient, QueryClientProvider } from '@tanstack/react-query';
import { WorkflowVersionResponse } from '@/enterprise/services/types';
import { mockSetPreviewMode } from '../../../../../../../__mocks__/agentStoreMocks';

// Mock react-router-dom using existing mock pattern
jest.mock('react-router-dom', () => {
  const { createReactRouterMock, defaultMockParams } = jest.requireActual(
    '../../../../../../../__mocks__/reactRouterMocks',
  );
  return createReactRouterMock({ params: defaultMockParams });
});

// Mock react-icons - uses automatic mock from src/__mocks__/react-icons/fi.tsx
jest.mock('react-icons/fi');

// Mock IconEntity
jest.mock('@/components/IconEntity', () => ({
  __esModule: true,
  default: ({ onClick, ...props }: { onClick: () => void }) => (
    <button data-testid='close-button' onClick={onClick} {...props}>
      Close
    </button>
  ),
}));

// Mock VersionCard
jest.mock('../VersionCard', () => ({
  __esModule: true,
  default: ({
    version,
    isCurrent,
    isLatestPublished,
    onPreview,
    onEditDescription,
    onDelete,
  }: {
    version: WorkflowVersionResponse;
    isCurrent: boolean;
    isLatestPublished?: boolean;
    onPreview: () => void;
    onEditDescription: () => void;
    onDelete: () => void;
  }) => (
    <div
      data-testid={`version-card-${version.id}`}
      data-is-current={isCurrent}
      data-is-latest-published={isLatestPublished}
      data-version-number={version.attributes.version_number}
    >
      <span>v{version.attributes.version_number}</span>
      <button data-testid={`preview-${version.id}`} onClick={onPreview}>
        Preview
      </button>
      <button data-testid={`edit-${version.id}`} onClick={onEditDescription}>
        Edit
      </button>
      <button data-testid={`delete-${version.id}`} onClick={onDelete}>
        Delete
      </button>
    </div>
  ),
}));

// Mock EditVersionModal
jest.mock('../EditVersionModal', () => ({
  __esModule: true,
  default: ({
    isOpen,
    onClose,
    version,
    onSave,
    isLoading,
  }: {
    isOpen: boolean;
    onClose: () => void;
    version: WorkflowVersionResponse;
    onSave: (description: string) => void;
    isLoading: boolean;
  }) =>
    isOpen ? (
      <div data-testid='edit-version-modal' data-is-loading={isLoading}>
        <span>Editing v{version.attributes.version_number}</span>
        <button data-testid='save-description' onClick={() => onSave('New description')}>
          Save
        </button>
        <button data-testid='close-edit-modal' onClick={onClose}>
          Close
        </button>
      </div>
    ) : null,
}));

// Mock ConfirmDeleteModal
jest.mock('@/components/ConfirmDeleteModal/ConfirmDeleteModal', () => ({
  __esModule: true,
  default: ({
    open,
    onClose,
    onDelete,
    isDeleting,
  }: {
    open: boolean;
    onClose: () => void;
    onDelete: () => void;
    isDeleting: boolean;
    title: string;
    description: string;
  }) =>
    open ? (
      <div data-testid='confirm-delete-modal' data-is-deleting={isDeleting}>
        <button data-testid='confirm-delete' onClick={onDelete}>
          Confirm Delete
        </button>
        <button data-testid='cancel-delete' onClick={onClose}>
          Cancel
        </button>
      </div>
    ) : null,
}));

// Mock constructEdgeId
jest.mock('../../utils', () => ({
  constructEdgeId: jest.fn(
    (edge) =>
      `xy-edge__${edge.source_component_id}-${edge.target_component_id}-${edge.source_handle.field}-${edge.target_handle.field}`,
  ),
}));

// Mock useAgentStore using existing mock
const mockCurrentWorkflow = {
  workflow: {
    version_number: 2,
  },
};

const mockUseAgentStore = jest.fn(() => ({
  setPreviewMode: mockSetPreviewMode,
  currentWorkflow: mockCurrentWorkflow,
}));

jest.mock('@/enterprise/store/useAgentStore', () => ({
  __esModule: true,
  default: () => mockUseAgentStore(),
}));

// Mock useAgentQueries
const mockRefetch = jest.fn();
const mockUseGetWorkflowVersions = jest.fn();

jest.mock('@/enterprise/hooks/queries/useAgentQueries', () => ({
  __esModule: true,
  default: () => ({
    useGetWorkflowVersions: mockUseGetWorkflowVersions,
  }),
}));

// Mock useAgentMutations
const mockUpdateVersionDescription = {
  mutateAsync: jest.fn(),
  isPending: false,
};
const mockDeleteVersion = {
  mutateAsync: jest.fn(),
  isPending: false,
};

jest.mock('@/enterprise/hooks/mutations/useAgentMutations', () => ({
  __esModule: true,
  default: () => ({
    updateVersionDescription: mockUpdateVersionDescription,
    deleteVersion: mockDeleteVersion,
  }),
}));

describe('VersionsPanel', () => {
  const queryClient = new QueryClient({
    defaultOptions: {
      queries: {
        retry: false,
      },
    },
  });

  const mockOnClose = jest.fn();

  const createMockVersion = (
    id: string,
    versionNumber: number,
    status: 'draft' | 'published' = 'draft',
  ): WorkflowVersionResponse => ({
    id,
    attributes: {
      version_number: versionNumber,
      version_description: `Description for v${versionNumber}`,
      created_at: '2024-01-15T10:00:00Z',
      workflow: {
        id: 'workflow-1',
        type: 'agents-workflows',
        attributes: {
          name: 'Test Workflow',
          description: 'Test',
          status,
          configuration: {},
          access_control_enabled: false,
          access_control: { allowed_role_ids: [], allowed_users: [] },
          components: [
            {
              id: 'comp-1',
              component_category: 'generic_component',
              component_type: 'llm_model',
              position: { x: 100, y: 100 },
            } as any,
          ],
          edges: [
            {
              source_component_id: 'comp-1',
              target_component_id: 'comp-2',
              source_handle: { field: 'output', type: 'string' },
              target_handle: { field: 'input', type: 'string' },
            },
          ],
        },
      },
    },
  });

  const renderComponent = (isOpen: boolean = true) => {
    return render(
      <ChakraProvider>
        <QueryClientProvider client={queryClient}>
          <VersionsPanel isOpen={isOpen} onClose={mockOnClose} />
        </QueryClientProvider>
      </ChakraProvider>,
    );
  };

  beforeEach(() => {
    jest.clearAllMocks();
    mockUseGetWorkflowVersions.mockReturnValue({
      data: {
        data: [createMockVersion('v1', 1), createMockVersion('v2', 2), createMockVersion('v3', 3)],
      },
      isLoading: false,
      error: null,
      refetch: mockRefetch,
    });
  });

  describe('Rendering', () => {
    it('should not render when isOpen is false', () => {
      renderComponent(false);
      expect(screen.queryByText('Versions')).not.toBeInTheDocument();
    });

    it('should render when isOpen is true', () => {
      renderComponent(true);
      expect(screen.getByText('Versions')).toBeInTheDocument();
      expect(screen.getByTestId('workflow-versions-panel')).toBeInTheDocument();
      expect(screen.getByTestId('workflow-versions-container')).toBeInTheDocument();
    });

    it('should render version count correctly', () => {
      renderComponent();
      expect(screen.getByText('3 versions available')).toBeInTheDocument();
    });

    it('should render singular version text when only one version', () => {
      mockUseGetWorkflowVersions.mockReturnValue({
        data: { data: [createMockVersion('v1', 1)] },
        isLoading: false,
        error: null,
        refetch: mockRefetch,
      });
      renderComponent();
      expect(screen.getByText('1 version available')).toBeInTheDocument();
    });

    it('should render all version cards', () => {
      renderComponent();
      expect(screen.getByTestId('version-card-v1')).toBeInTheDocument();
      expect(screen.getByTestId('version-card-v2')).toBeInTheDocument();
      expect(screen.getByTestId('version-card-v3')).toBeInTheDocument();
    });

    it('should mark current version correctly', () => {
      renderComponent();
      // Version 2 is current (matches mockCurrentWorkflow.workflow.version_number)
      expect(screen.getByTestId('version-card-v2')).toHaveAttribute('data-is-current', 'true');
      expect(screen.getByTestId('version-card-v1')).toHaveAttribute('data-is-current', 'false');
      expect(screen.getByTestId('version-card-v3')).toHaveAttribute('data-is-current', 'false');
    });
  });

  describe('Loading State', () => {
    it('should show spinner when loading', () => {
      mockUseGetWorkflowVersions.mockReturnValue({
        data: null,
        isLoading: true,
        error: null,
        refetch: mockRefetch,
      });
      renderComponent();
      expect(screen.getByText('Versions')).toBeInTheDocument();
      // Spinner should be present (Chakra Spinner)
    });
  });

  describe('Error State', () => {
    it('should show error message when fetch fails', () => {
      mockUseGetWorkflowVersions.mockReturnValue({
        data: null,
        isLoading: false,
        error: new Error('Failed to fetch'),
        refetch: mockRefetch,
      });
      renderComponent();
      expect(screen.getByText('Failed to load versions')).toBeInTheDocument();
    });
  });

  describe('Empty State', () => {
    it('should show empty message when no versions', () => {
      mockUseGetWorkflowVersions.mockReturnValue({
        data: { data: [] },
        isLoading: false,
        error: null,
        refetch: mockRefetch,
      });
      renderComponent();
      expect(screen.getByText('No versions available')).toBeInTheDocument();
    });
  });

  describe('Close Panel', () => {
    it('should call onClose when close button is clicked', () => {
      renderComponent();
      fireEvent.click(screen.getByTestId('close-button'));
      expect(mockOnClose).toHaveBeenCalledTimes(1);
    });
  });

  describe('Preview Version', () => {
    it('should call setPreviewMode when preview is clicked', () => {
      renderComponent();
      fireEvent.click(screen.getByTestId('preview-v1'));
      expect(mockSetPreviewMode).toHaveBeenCalled();
    });

    it('should transform version data correctly for preview', () => {
      renderComponent();
      fireEvent.click(screen.getByTestId('preview-v1'));

      expect(mockSetPreviewMode).toHaveBeenCalledWith(
        expect.objectContaining({
          id: 'v1',
          versionNumber: 'v1',
          description: 'Description for v1',
          configuration: expect.objectContaining({
            components: expect.any(Array),
            edges: expect.any(Array),
          }),
        }),
      );
    });
  });

  describe('Edit Description', () => {
    it('should open edit modal when edit is clicked', () => {
      renderComponent();
      fireEvent.click(screen.getByTestId('edit-v1'));
      expect(screen.getByTestId('edit-version-modal')).toBeInTheDocument();
    });

    it('should close edit modal when close is clicked', () => {
      renderComponent();
      fireEvent.click(screen.getByTestId('edit-v1'));
      expect(screen.getByTestId('edit-version-modal')).toBeInTheDocument();

      fireEvent.click(screen.getByTestId('close-edit-modal'));
      expect(screen.queryByTestId('edit-version-modal')).not.toBeInTheDocument();
    });

    it('should call updateVersionDescription when save is clicked', async () => {
      mockUpdateVersionDescription.mutateAsync.mockResolvedValue({});
      renderComponent();

      fireEvent.click(screen.getByTestId('edit-v1'));
      fireEvent.click(screen.getByTestId('save-description'));

      await waitFor(() => {
        expect(mockUpdateVersionDescription.mutateAsync).toHaveBeenCalledWith({
          workflowId: 'workflow-123',
          versionId: 'v1',
          description: 'New description',
        });
      });
    });

    it('should refetch versions after successful update', async () => {
      mockUpdateVersionDescription.mutateAsync.mockResolvedValue({});
      renderComponent();

      fireEvent.click(screen.getByTestId('edit-v1'));
      fireEvent.click(screen.getByTestId('save-description'));

      await waitFor(() => {
        expect(mockRefetch).toHaveBeenCalled();
      });
    });

    it('should close modal after successful update', async () => {
      mockUpdateVersionDescription.mutateAsync.mockResolvedValue({});
      renderComponent();

      fireEvent.click(screen.getByTestId('edit-v1'));
      fireEvent.click(screen.getByTestId('save-description'));

      await waitFor(() => {
        expect(screen.queryByTestId('edit-version-modal')).not.toBeInTheDocument();
      });
    });
  });

  describe('Delete Version', () => {
    it('should open delete confirmation modal when delete is clicked', () => {
      renderComponent();
      fireEvent.click(screen.getByTestId('delete-v1'));
      expect(screen.getByTestId('confirm-delete-modal')).toBeInTheDocument();
    });

    it('should close delete modal when cancel is clicked', () => {
      renderComponent();
      fireEvent.click(screen.getByTestId('delete-v1'));
      expect(screen.getByTestId('confirm-delete-modal')).toBeInTheDocument();

      fireEvent.click(screen.getByTestId('cancel-delete'));
      expect(screen.queryByTestId('confirm-delete-modal')).not.toBeInTheDocument();
    });

    it('should call deleteVersion when confirm is clicked', async () => {
      mockDeleteVersion.mutateAsync.mockResolvedValue({});
      renderComponent();

      fireEvent.click(screen.getByTestId('delete-v1'));
      fireEvent.click(screen.getByTestId('confirm-delete'));

      await waitFor(() => {
        expect(mockDeleteVersion.mutateAsync).toHaveBeenCalledWith({
          workflowId: 'workflow-123',
          versionId: 'v1',
        });
      });
    });

    it('should refetch versions after successful delete', async () => {
      mockDeleteVersion.mutateAsync.mockResolvedValue({});
      renderComponent();

      fireEvent.click(screen.getByTestId('delete-v1'));
      fireEvent.click(screen.getByTestId('confirm-delete'));

      await waitFor(() => {
        expect(mockRefetch).toHaveBeenCalled();
      });
    });

    it('should close modal after successful delete', async () => {
      mockDeleteVersion.mutateAsync.mockResolvedValue({});
      renderComponent();

      fireEvent.click(screen.getByTestId('delete-v1'));
      fireEvent.click(screen.getByTestId('confirm-delete'));

      await waitFor(() => {
        expect(screen.queryByTestId('confirm-delete-modal')).not.toBeInTheDocument();
      });
    });
  });

  describe('Edge Cases', () => {
    it('should handle version without workflow gracefully', () => {
      const versionWithoutWorkflow: WorkflowVersionResponse = {
        id: 'v-no-workflow',
        attributes: {
          version_number: 1,
          version_description: 'Test',
          created_at: '2024-01-15T10:00:00Z',
          workflow: undefined as unknown as WorkflowVersionResponse['attributes']['workflow'],
        },
      };

      mockUseGetWorkflowVersions.mockReturnValue({
        data: { data: [versionWithoutWorkflow] },
        isLoading: false,
        error: null,
        refetch: mockRefetch,
      });

      renderComponent();
      expect(screen.getByTestId('version-card-v-no-workflow')).toBeInTheDocument();

      // Preview should not call setPreviewMode with null
      fireEvent.click(screen.getByTestId('preview-v-no-workflow'));
      expect(mockSetPreviewMode).not.toHaveBeenCalled();
    });

    it('should handle null versionsData gracefully', () => {
      mockUseGetWorkflowVersions.mockReturnValue({
        data: null,
        isLoading: false,
        error: null,
        refetch: mockRefetch,
      });

      renderComponent();
      expect(screen.getByText('No versions available')).toBeInTheDocument();
    });

    it('should handle empty workflowId', () => {
      // This tests the case where params.id is undefined
      // The component should still render but with empty state
      renderComponent();
      expect(screen.getByText('Versions')).toBeInTheDocument();
    });
  });

  describe('Version Status Transformation', () => {
    it('should set status to live when versionStatus is published (line 46)', () => {
      const publishedVersion = createMockVersion('v1', 1, 'published');
      mockUseGetWorkflowVersions.mockReturnValue({
        data: { data: [publishedVersion] },
        isLoading: false,
        error: null,
        refetch: mockRefetch,
      });

      renderComponent();

      // Click preview to trigger transformVersionToPreview which sets status='live' when versionStatus === 'published' (line 46)
      const previewButton = screen.getByTestId('preview-v1');
      fireEvent.click(previewButton);

      // Verify setPreviewMode was called with the transformed version
      expect(mockSetPreviewMode).toHaveBeenCalled();
    });

    it('should set status to draft when isCurrent is true and versionStatus is draft (line 48)', () => {
      const draftVersion = createMockVersion('v2', 2, 'draft');
      mockUseGetWorkflowVersions.mockReturnValue({
        data: { data: [draftVersion] },
        isLoading: false,
        error: null,
        refetch: mockRefetch,
      });

      // Set current workflow version to 2 to make this version current
      mockUseAgentStore.mockReturnValueOnce({
        setPreviewMode: mockSetPreviewMode,
        currentWorkflow: {
          workflow: {
            version_number: 2,
          },
        },
      });

      renderComponent();

      // Click preview to trigger transformVersionToPreview which sets status='draft' when isCurrent && versionStatus === 'draft' (line 48)
      const previewButton = screen.getByTestId('preview-v2');
      fireEvent.click(previewButton);

      // Verify setPreviewMode was called with the transformed version
      expect(mockSetPreviewMode).toHaveBeenCalled();
    });

    it('should identify latest published version correctly', () => {
      // Create versions with different statuses and version numbers
      const v1 = createMockVersion('v1', 1, 'draft');
      const v2 = createMockVersion('v2', 2, 'published');
      const v3 = createMockVersion('v3', 3, 'published');
      const v4 = createMockVersion('v4', 4, 'draft');

      mockUseGetWorkflowVersions.mockReturnValue({
        data: { data: [v1, v2, v3, v4] },
        isLoading: false,
        error: null,
        refetch: mockRefetch,
      });

      renderComponent();

      // v3 should be marked as latest published (highest version number with published status)
      expect(screen.getByTestId('version-card-v3')).toHaveAttribute(
        'data-is-latest-published',
        'true',
      );
      // v2 is published but not the latest
      expect(screen.getByTestId('version-card-v2')).toHaveAttribute(
        'data-is-latest-published',
        'false',
      );
      // Draft versions should not be latest published
      expect(screen.getByTestId('version-card-v1')).toHaveAttribute(
        'data-is-latest-published',
        'false',
      );
      expect(screen.getByTestId('version-card-v4')).toHaveAttribute(
        'data-is-latest-published',
        'false',
      );
    });

    it('should handle version with empty edges array', () => {
      const versionWithEmptyEdges = {
        ...createMockVersion('v-empty-edges', 1),
        attributes: {
          ...createMockVersion('v-empty-edges', 1).attributes,
          workflow: {
            ...createMockVersion('v-empty-edges', 1).attributes.workflow!,
            attributes: {
              ...createMockVersion('v-empty-edges', 1).attributes.workflow!.attributes,
              edges: [],
            },
          },
        },
      };

      mockUseGetWorkflowVersions.mockReturnValue({
        data: { data: [versionWithEmptyEdges] },
        isLoading: false,
        error: null,
        refetch: mockRefetch,
      });

      renderComponent();
      fireEvent.click(screen.getByTestId('preview-v-empty-edges'));
      expect(mockSetPreviewMode).toHaveBeenCalled();
    });

    it('should handle version with empty components array', () => {
      const versionWithEmptyComponents = {
        ...createMockVersion('v-empty-components', 1),
        attributes: {
          ...createMockVersion('v-empty-components', 1).attributes,
          workflow: {
            ...createMockVersion('v-empty-components', 1).attributes.workflow!,
            attributes: {
              ...createMockVersion('v-empty-components', 1).attributes.workflow!.attributes,
              components: [],
            },
          },
        },
      };

      mockUseGetWorkflowVersions.mockReturnValue({
        data: { data: [versionWithEmptyComponents] },
        isLoading: false,
        error: null,
        refetch: mockRefetch,
      });

      renderComponent();
      fireEvent.click(screen.getByTestId('preview-v-empty-components'));
      expect(mockSetPreviewMode).toHaveBeenCalled();
    });

    it('should handle version with components without position', () => {
      const versionWithoutPosition = {
        ...createMockVersion('v-no-position', 1),
        attributes: {
          ...createMockVersion('v-no-position', 1).attributes,
          workflow: {
            ...createMockVersion('v-no-position', 1).attributes.workflow!,
            attributes: {
              ...createMockVersion('v-no-position', 1).attributes.workflow!.attributes,
              components: [
                {
                  id: 'comp-1',
                  component_category: 'generic_component',
                  component_type: 'llm_model',
                  // No position property
                } as any,
              ],
            },
          },
        },
      };

      mockUseGetWorkflowVersions.mockReturnValue({
        data: { data: [versionWithoutPosition] },
        isLoading: false,
        error: null,
        refetch: mockRefetch,
      });

      renderComponent();
      fireEvent.click(screen.getByTestId('preview-v-no-position'));
      expect(mockSetPreviewMode).toHaveBeenCalled();
    });

    it('should handle version with components without component_category', () => {
      const versionWithoutCategory = {
        ...createMockVersion('v-no-category', 1),
        attributes: {
          ...createMockVersion('v-no-category', 1).attributes,
          workflow: {
            ...createMockVersion('v-no-category', 1).attributes.workflow!,
            attributes: {
              ...createMockVersion('v-no-category', 1).attributes.workflow!.attributes,
              components: [
                {
                  id: 'comp-1',
                  component_type: 'llm_model',
                  position: { x: 100, y: 100 },
                  // No component_category - should default to 'generic_component'
                } as any,
              ],
            },
          },
        },
      };

      mockUseGetWorkflowVersions.mockReturnValue({
        data: { data: [versionWithoutCategory] },
        isLoading: false,
        error: null,
        refetch: mockRefetch,
      });

      renderComponent();
      fireEvent.click(screen.getByTestId('preview-v-no-category'));
      expect(mockSetPreviewMode).toHaveBeenCalled();
    });

    it('should handle version with missing version_description', () => {
      const versionWithoutDescription = {
        ...createMockVersion('v-no-desc', 1),
        attributes: {
          ...createMockVersion('v-no-desc', 1).attributes,
          version_description: undefined,
        },
      };

      mockUseGetWorkflowVersions.mockReturnValue({
        data: { data: [versionWithoutDescription] },
        isLoading: false,
        error: null,
        refetch: mockRefetch,
      });

      renderComponent();
      fireEvent.click(screen.getByTestId('preview-v-no-desc'));
      expect(mockSetPreviewMode).toHaveBeenCalledWith(
        expect.objectContaining({
          description: '',
        }),
      );
    });

    it('should handle version with missing whodunnit', () => {
      const versionWithoutAuthor = {
        ...createMockVersion('v-no-author', 1),
        attributes: {
          ...createMockVersion('v-no-author', 1).attributes,
          whodunnit: undefined,
        },
      };

      mockUseGetWorkflowVersions.mockReturnValue({
        data: { data: [versionWithoutAuthor] },
        isLoading: false,
        error: null,
        refetch: mockRefetch,
      });

      renderComponent();
      fireEvent.click(screen.getByTestId('preview-v-no-author'));
      expect(mockSetPreviewMode).toHaveBeenCalledWith(
        expect.objectContaining({
          author: '-',
        }),
      );
    });

    it('should handle version with missing created_at', () => {
      const versionWithoutTimestamp = {
        ...createMockVersion('v-no-timestamp', 1),
        attributes: {
          ...createMockVersion('v-no-timestamp', 1).attributes,
          created_at: undefined,
        },
      };

      mockUseGetWorkflowVersions.mockReturnValue({
        data: { data: [versionWithoutTimestamp] },
        isLoading: false,
        error: null,
        refetch: mockRefetch,
      });

      renderComponent();
      fireEvent.click(screen.getByTestId('preview-v-no-timestamp'));
      expect(mockSetPreviewMode).toHaveBeenCalledWith(
        expect.objectContaining({
          timestamp: '',
        }),
      );
    });
  });
});
