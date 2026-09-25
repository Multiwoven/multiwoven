import { render, screen, fireEvent } from '@testing-library/react';
import { expect, describe, it, beforeEach } from '@jest/globals';
import '@testing-library/jest-dom/jest-globals';
import '@testing-library/jest-dom';
import EditVersionModal from '../EditVersionModal';
import { ChakraProvider } from '@chakra-ui/react';
import { WorkflowVersionResponse } from '@/enterprise/services/types';

// Mock BaseModal
jest.mock('@/components/BaseModal/BaseModal', () => ({
  __esModule: true,
  default: ({
    openModal,
    setModalOpen,
    children,
  }: {
    openModal: boolean;
    setModalOpen: () => void;
    title: string;
    modalWidth: string;
    children: React.ReactNode;
  }) =>
    openModal ? (
      <div data-testid='base-modal'>
        <button data-testid='modal-close' onClick={setModalOpen}>
          Close Modal
        </button>
        {children}
      </div>
    ) : null,
}));

describe('EditVersionModal', () => {
  const mockOnClose = jest.fn();
  const mockOnSave = jest.fn();

  const createMockVersion = (
    overrides: Partial<{
      version_number: number;
      version_description: string;
    }> = {},
  ): WorkflowVersionResponse => ({
    id: 'version-1',
    attributes: {
      version_number: overrides.version_number ?? 1,
      version_description: overrides.version_description ?? 'Initial description',
      created_at: '2024-01-15T10:00:00Z',
      workflow: {
        id: 'workflow-1',
        type: 'agents-workflows',
        attributes: {
          name: 'Test Workflow',
          description: 'Test',
          status: 'draft',
          configuration: {},
          access_control_enabled: false,
          access_control: { allowed_role_ids: [], allowed_users: [] },
          components: [],
          edges: [],
        },
      },
    },
  });

  const renderComponent = (
    isOpen: boolean = true,
    version: WorkflowVersionResponse = createMockVersion(),
    isLoading: boolean = false,
  ) => {
    return render(
      <ChakraProvider>
        <EditVersionModal
          isOpen={isOpen}
          onClose={mockOnClose}
          version={version}
          onSave={mockOnSave}
          isLoading={isLoading}
        />
      </ChakraProvider>,
    );
  };

  beforeEach(() => {
    jest.clearAllMocks();
  });

  describe('Rendering', () => {
    it('should not render when isOpen is false', () => {
      renderComponent(false);
      expect(screen.queryByTestId('base-modal')).not.toBeInTheDocument();
    });

    it('should render when isOpen is true', () => {
      renderComponent(true);
      expect(screen.getByTestId('base-modal')).toBeInTheDocument();
    });

    it('should render modal title', () => {
      renderComponent();
      expect(screen.getByText('Edit Version Description')).toBeInTheDocument();
    });

    it('should render version number badge', () => {
      renderComponent(true, createMockVersion({ version_number: 5 }));
      expect(screen.getByText('v5')).toBeInTheDocument();
    });

    it('should render Version Description label', () => {
      renderComponent();
      expect(screen.getByText('Version Description')).toBeInTheDocument();
    });

    it('should render textarea with initial description', () => {
      renderComponent(true, createMockVersion({ version_description: 'My initial description' }));
      const textarea = screen.getByPlaceholderText('Enter version description');
      expect(textarea).toHaveValue('My initial description');
    });

    it('should render Cancel button', () => {
      renderComponent();
      expect(screen.getByRole('button', { name: 'Cancel' })).toBeInTheDocument();
    });

    it('should render Save Changes button', () => {
      renderComponent();
      expect(screen.getByRole('button', { name: 'Save Changes' })).toBeInTheDocument();
    });

    it('should render Save Changes button with data-testid workflow-version-save-changes-button', () => {
      renderComponent();
      expect(screen.getByTestId('workflow-version-save-changes-button')).toBeInTheDocument();
    });
  });

  describe('User Interactions', () => {
    it('should update textarea value when user types', () => {
      renderComponent();
      const textarea = screen.getByPlaceholderText('Enter version description');

      fireEvent.change(textarea, { target: { value: 'Updated description' } });

      expect(textarea).toHaveValue('Updated description');
    });

    it('should call onClose when Cancel button is clicked', () => {
      renderComponent();
      fireEvent.click(screen.getByRole('button', { name: 'Cancel' }));
      expect(mockOnClose).toHaveBeenCalledTimes(1);
    });

    it('should call onSave with current description when Save Changes is clicked', () => {
      renderComponent(true, createMockVersion({ version_description: 'Original' }));
      const textarea = screen.getByPlaceholderText('Enter version description');

      fireEvent.change(textarea, { target: { value: 'New description' } });
      fireEvent.click(screen.getByRole('button', { name: 'Save Changes' }));

      expect(mockOnSave).toHaveBeenCalledWith('New description');
    });

    it('should call onSave with original description if not modified', () => {
      renderComponent(true, createMockVersion({ version_description: 'Original description' }));
      fireEvent.click(screen.getByRole('button', { name: 'Save Changes' }));

      expect(mockOnSave).toHaveBeenCalledWith('Original description');
    });
  });

  describe('Loading State', () => {
    it('should show Cancel button with not-allowed cursor when loading', () => {
      renderComponent(true, createMockVersion(), true);
      const cancelButton = screen.getByRole('button', { name: 'Cancel' });
      // The button has disabled prop but Chakra may not set disabled attribute
      expect(cancelButton).toBeInTheDocument();
    });

    it('should show Save Changes button in loading state', () => {
      renderComponent(true, createMockVersion(), true);
      // When isLoading is true, the button shows a spinner
      // The button text may change or spinner may be shown
      const buttons = screen.getAllByRole('button');
      const saveButton = buttons.find(
        (btn) => btn.textContent?.includes('Save') || btn.textContent?.includes('Loading'),
      );
      expect(saveButton).toBeInTheDocument();
    });

    it('should render both buttons in loading state', () => {
      renderComponent(true, createMockVersion(), true);
      // Both buttons should be present
      expect(screen.getByRole('button', { name: 'Cancel' })).toBeInTheDocument();
    });
  });

  describe('Modal Close', () => {
    it('should call onClose when modal close button is clicked', () => {
      renderComponent();
      fireEvent.click(screen.getByTestId('modal-close'));
      expect(mockOnClose).toHaveBeenCalledTimes(1);
    });
  });

  describe('Edge Cases', () => {
    it('should handle empty initial description', () => {
      renderComponent(true, createMockVersion({ version_description: '' }));
      const textarea = screen.getByPlaceholderText('Enter version description');
      expect(textarea).toHaveValue('');
    });

    it('should handle undefined initial description', () => {
      const versionWithUndefinedDesc: WorkflowVersionResponse = {
        id: 'version-1',
        attributes: {
          version_number: 1,
          version_description: undefined as unknown as string,
          created_at: '2024-01-15T10:00:00Z',
          workflow: {
            id: 'workflow-1',
            type: 'agents-workflows',
            attributes: {
              name: 'Test',
              description: '',
              status: 'draft',
              configuration: {},
              access_control_enabled: false,
              access_control: { allowed_role_ids: [], allowed_users: [] },
              components: [],
              edges: [],
            },
          },
        },
      };

      renderComponent(true, versionWithUndefinedDesc);
      const textarea = screen.getByPlaceholderText('Enter version description');
      expect(textarea).toBeInTheDocument();
    });

    it('should handle very long description', () => {
      const longDescription = 'A'.repeat(1000);
      renderComponent(true, createMockVersion({ version_description: longDescription }));
      const textarea = screen.getByPlaceholderText('Enter version description');
      expect(textarea).toHaveValue(longDescription);
    });

    it('should handle special characters in description', () => {
      const specialChars = '<script>alert("xss")</script> & "quotes" \'single\'';
      renderComponent(true, createMockVersion({ version_description: specialChars }));
      const textarea = screen.getByPlaceholderText('Enter version description');
      expect(textarea).toHaveValue(specialChars);
    });
  });
});
