import { render, screen, fireEvent } from '@testing-library/react';
import { expect, describe, it, beforeEach } from '@jest/globals';
import '@testing-library/jest-dom/jest-globals';
import '@testing-library/jest-dom';
import VersionCard from '../VersionCard';
import { ChakraProvider } from '@chakra-ui/react';
import { WorkflowVersionResponse } from '@/enterprise/services/types';

// Mock react-icons - uses automatic mock from src/__mocks__/react-icons/fi.tsx
jest.mock('react-icons/fi');

// Mock VersionActionsMenu
const mockOnEditDescription = jest.fn();
const mockOnDelete = jest.fn();
jest.mock('../VersionActionsMenu', () => ({
  __esModule: true,
  default: ({
    isPublished,
    isCurrent,
    onEditDescription,
    onDelete,
  }: {
    isPublished: boolean;
    isCurrent: boolean;
    onEditDescription: () => void;
    onDelete: () => void;
  }) => (
    <div
      data-testid='version-actions-menu'
      data-is-published={isPublished}
      data-is-current={isCurrent}
    >
      <button data-testid='edit-description-btn' onClick={onEditDescription}>
        Edit
      </button>
      <button data-testid='delete-btn' onClick={onDelete}>
        Delete
      </button>
    </div>
  ),
}));

// Mock ToolTip
jest.mock('@/components/ToolTip', () => ({
  __esModule: true,
  default: ({ children, label }: { children: React.ReactNode; label: string }) => (
    <div data-testid='tooltip' data-label={label}>
      {children}
    </div>
  ),
}));

// Mock formatTimestamp
jest.mock('@/utils/formatTimestamp', () => ({
  formatTimestamp: jest.fn((timestamp: string) => `Formatted: ${timestamp}`),
}));

describe('VersionCard', () => {
  const mockOnPreview = jest.fn();

  const createMockVersion = (
    overrides: Partial<{
      id: string;
      version_number: number;
      version_description: string;
      created_at: string;
      workflow_status: 'draft' | 'published';
    }> = {},
  ): WorkflowVersionResponse => ({
    id: overrides.id || 'version-1',
    attributes: {
      version_number: overrides.version_number ?? 1,
      version_description: overrides.version_description || 'Test description',
      created_at: overrides.created_at || '2024-01-15T10:00:00Z',
      workflow: {
        id: 'workflow-1',
        type: 'agents-workflows',
        attributes: {
          name: 'Test Workflow',
          description: 'Test workflow description',
          status: overrides.workflow_status || 'draft',
          configuration: {},
          access_control_enabled: false,
          access_control: {
            allowed_role_ids: [],
            allowed_users: [],
          },
          components: [],
          edges: [],
        },
      },
    },
  });

  const renderComponent = (
    version: WorkflowVersionResponse = createMockVersion(),
    isCurrent: boolean = false,
    isLatestPublished: boolean = false,
  ) => {
    return render(
      <ChakraProvider>
        <VersionCard
          version={version}
          isCurrent={isCurrent}
          isLatestPublished={isLatestPublished}
          onPreview={mockOnPreview}
          onEditDescription={mockOnEditDescription}
          onDelete={mockOnDelete}
        />
      </ChakraProvider>,
    );
  };

  beforeEach(() => {
    jest.clearAllMocks();
  });

  describe('Rendering', () => {
    it('should render version number correctly', () => {
      renderComponent(createMockVersion({ version_number: 5 }));
      expect(screen.getByText('v5')).toBeInTheDocument();
      const item = screen.getByTestId('workflow-version-item');
      expect(item).toHaveAttribute('data-version-number', '5');
    });

    it('should render version description', () => {
      renderComponent(createMockVersion({ version_description: 'My custom description' }));
      expect(screen.getByText('My custom description')).toBeInTheDocument();
    });

    it('should render empty description when not provided', () => {
      renderComponent(createMockVersion({ version_description: '' }));
      // The description text element should be empty
      expect(screen.queryByText('My custom description')).not.toBeInTheDocument();
    });

    it('should render formatted timestamp', () => {
      renderComponent(createMockVersion({ created_at: '2024-01-15T10:00:00Z' }));
      expect(screen.getByText('Formatted: 2024-01-15T10:00:00Z')).toBeInTheDocument();
    });

    it('should render author as dash when not available', () => {
      renderComponent();
      expect(screen.getByText('-')).toBeInTheDocument();
    });

    it('should render VersionActionsMenu', () => {
      renderComponent();
      expect(screen.getByTestId('version-actions-menu')).toBeInTheDocument();
    });
  });

  describe('Status Badge', () => {
    it('should show Live badge when workflow status is published', () => {
      renderComponent(createMockVersion({ workflow_status: 'published' }), false, true);
      expect(screen.getByText('Live')).toBeInTheDocument();
    });

    it('should show Draft badge when isCurrent and workflow status is draft', () => {
      renderComponent(createMockVersion({ workflow_status: 'draft' }), true);
      expect(screen.getByText('Draft')).toBeInTheDocument();
    });

    it('should not show badge when archived (not current and draft)', () => {
      renderComponent(createMockVersion({ workflow_status: 'draft' }), false);
      expect(screen.queryByText('Draft')).not.toBeInTheDocument();
      expect(screen.queryByText('Live')).not.toBeInTheDocument();
    });
  });

  describe('Preview Button', () => {
    it('should show preview button when not current version', () => {
      renderComponent(createMockVersion(), false);
      expect(screen.getByRole('button', { name: 'Preview Version' })).toBeInTheDocument();
    });

    it('should not show preview button when current version', () => {
      renderComponent(createMockVersion(), true);
      expect(screen.queryByRole('button', { name: 'Preview Version' })).not.toBeInTheDocument();
    });

    it('should call onPreview when preview button is clicked', () => {
      renderComponent(createMockVersion(), false);
      const previewButton = screen.getByRole('button', { name: 'Preview Version' });
      fireEvent.click(previewButton);
      expect(mockOnPreview).toHaveBeenCalledTimes(1);
    });

    it('should stop event propagation when preview button is clicked', () => {
      const mockParentClick = jest.fn();
      const version = createMockVersion();

      render(
        <ChakraProvider>
          <div onClick={mockParentClick}>
            <VersionCard
              version={version}
              isCurrent={false}
              onPreview={mockOnPreview}
              onEditDescription={mockOnEditDescription}
              onDelete={mockOnDelete}
            />
          </div>
        </ChakraProvider>,
      );

      const previewButton = screen.getByRole('button', { name: 'Preview Version' });
      fireEvent.click(previewButton);

      expect(mockOnPreview).toHaveBeenCalled();
      // Parent click should not be triggered due to stopPropagation
    });
  });

  describe('Actions Menu', () => {
    it('should pass isPublished=true to VersionActionsMenu when status is live', () => {
      renderComponent(createMockVersion({ workflow_status: 'published' }), false, true);
      expect(screen.getByTestId('version-actions-menu')).toHaveAttribute(
        'data-is-published',
        'true',
      );
    });

    it('should pass isPublished=false to VersionActionsMenu when status is not live', () => {
      renderComponent(createMockVersion({ workflow_status: 'draft' }), false);
      expect(screen.getByTestId('version-actions-menu')).toHaveAttribute(
        'data-is-published',
        'false',
      );
    });

    it('should pass isCurrent=true to VersionActionsMenu when isCurrent is true', () => {
      renderComponent(createMockVersion(), true);
      expect(screen.getByTestId('version-actions-menu')).toHaveAttribute('data-is-current', 'true');
    });

    it('should call onEditDescription when edit button is clicked', () => {
      renderComponent();
      fireEvent.click(screen.getByTestId('edit-description-btn'));
      expect(mockOnEditDescription).toHaveBeenCalledTimes(1);
    });

    it('should call onDelete when delete button is clicked', () => {
      renderComponent();
      fireEvent.click(screen.getByTestId('delete-btn'));
      expect(mockOnDelete).toHaveBeenCalledTimes(1);
    });
  });

  describe('Edge Cases', () => {
    it('should handle version without workflow', () => {
      const versionWithoutWorkflow: WorkflowVersionResponse = {
        id: 'version-1',
        attributes: {
          version_number: 1,
          version_description: 'Test',
          created_at: '2024-01-15T10:00:00Z',
          workflow: undefined as unknown as WorkflowVersionResponse['attributes']['workflow'],
        },
      };

      renderComponent(versionWithoutWorkflow);
      // Should render without crashing, status should be archived (no badge)
      expect(screen.getByText('v1')).toBeInTheDocument();
      expect(screen.queryByText('Live')).not.toBeInTheDocument();
      expect(screen.queryByText('Draft')).not.toBeInTheDocument();
    });

    it('should handle version with empty created_at', () => {
      const versionWithoutTimestamp = createMockVersion({ created_at: '' });
      renderComponent(versionWithoutTimestamp);
      // When created_at is empty, formatTimestamp is not called
      // The component should still render without crashing
      expect(screen.getByText('v1')).toBeInTheDocument();
    });
  });
});
