import { render, screen, fireEvent } from '@testing-library/react';
import { expect, describe, it, beforeEach } from '@jest/globals';
import '@testing-library/jest-dom/jest-globals';
import '@testing-library/jest-dom';
import VersionDiffModal from '../VersionDiffModal';
import { ChakraProvider } from '@chakra-ui/react';
import { AgentVersion } from '@/enterprise/store/useAgentStore';
import { FlowComponent } from '../../../types';

// Mock react-icons - uses automatic mock from src/__mocks__/react-icons/fi.tsx
jest.mock('react-icons/fi');

// Mock FiAiCard
jest.mock('@/assets/icons/FiAICard', () => ({
  __esModule: true,
  default: () => <span data-testid='fi-ai-card'>AI</span>,
}));

// Mock BaseModal
jest.mock('@/components/BaseModal', () => ({
  __esModule: true,
  default: ({
    openModal,
    setModalOpen,
    children,
    footer,
  }: {
    openModal: boolean;
    setModalOpen: () => void;
    title: string;
    modalWidth: string;
    children: React.ReactNode;
    footer: React.ReactNode;
  }) =>
    openModal ? (
      <div data-testid='base-modal'>
        <button data-testid='modal-close' onClick={setModalOpen}>
          Close
        </button>
        <div data-testid='modal-content'>{children}</div>
        <div data-testid='modal-footer'>{footer}</div>
      </div>
    ) : null,
}));

describe('VersionDiffModal', () => {
  const mockOnClose = jest.fn();
  const mockOnRestore = jest.fn();
  const mockOnBackToDraft = jest.fn();

  const createMockPreviewVersion = (overrides: Partial<AgentVersion> = {}): AgentVersion => ({
    id: 'version-1',
    versionNumber: 'v1',
    status: 'archived',
    description: 'Test version description',
    author: 'Test Author',
    timestamp: '2024-01-15T10:00:00Z',
    isCurrent: false,
    configuration: {
      components: [
        {
          id: 'comp-1',
          component_type: 'llm_model',
          component_category: 'generic_component',
          data: { label: 'LLM Component' },
          configuration: { model: 'gpt-4' },
        } as any,
      ],
      edges: [],
    },
    ...overrides,
  });

  const createMockOriginalComponents = (): FlowComponent[] => [
    {
      id: 'comp-1',
      component_type: 'llm_model',
      component_category: 'generic_component',
      data: { label: 'LLM Component' },
      configuration: { model: 'gpt-3.5' },
    } as any,
  ];

  const renderComponent = (
    isOpen: boolean = true,
    previewVersion: AgentVersion = createMockPreviewVersion(),
    currentVersionNumber?: number,
    originalComponents?: FlowComponent[],
  ) => {
    return render(
      <ChakraProvider>
        <VersionDiffModal
          isOpen={isOpen}
          onClose={mockOnClose}
          previewVersion={previewVersion}
          currentVersionNumber={currentVersionNumber}
          originalComponents={originalComponents}
          onRestore={mockOnRestore}
          onBackToDraft={mockOnBackToDraft}
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

    it('should render Back to current draft button', () => {
      renderComponent();
      expect(screen.getByRole('button', { name: 'Back to current draft' })).toBeInTheDocument();
    });

    it('should render Replace draft with this version button', () => {
      renderComponent();
      expect(
        screen.getByRole('button', { name: /Replace draft with this version/i }),
      ).toBeInTheDocument();
    });

    it('should render Replace draft button with data-testid workflow-version-replace-draft-button', () => {
      renderComponent();
      expect(screen.getByTestId('workflow-version-replace-draft-button')).toBeInTheDocument();
    });

    it('should render version description in footer', () => {
      renderComponent(true, createMockPreviewVersion({ description: 'My custom description' }));
      expect(screen.getByText('My custom description')).toBeInTheDocument();
    });

    it('should show "No description" when description is empty', () => {
      renderComponent(true, createMockPreviewVersion({ description: '' }));
      expect(screen.getByText('No description')).toBeInTheDocument();
    });

    it('should display current version number', () => {
      renderComponent(true, createMockPreviewVersion(), 5);
      expect(screen.getByText('v5')).toBeInTheDocument();
    });

    it('should display "Draft" when no current version number', () => {
      renderComponent(true, createMockPreviewVersion(), undefined);
      expect(screen.getByText('Draft')).toBeInTheDocument();
    });

    it('should display preview version number', () => {
      renderComponent(true, createMockPreviewVersion({ versionNumber: 'v3' }));
      expect(screen.getByText('v3')).toBeInTheDocument();
    });
  });

  describe('Changes Detection', () => {
    it('should show no changes message when no differences', () => {
      const sameComponents: FlowComponent[] = [
        {
          id: 'comp-1',
          component_type: 'llm_model',
          component_category: 'generic_component',
          data: { label: 'LLM Component' },
          configuration: { model: 'gpt-4' },
        } as any,
      ];

      renderComponent(true, createMockPreviewVersion(), 1, sameComponents);
      expect(
        screen.getByText('No component changes detected between versions'),
      ).toBeInTheDocument();
    });

    it('should detect updated components', () => {
      const originalComponents = createMockOriginalComponents();
      renderComponent(true, createMockPreviewVersion(), 1, originalComponents);

      // Should show the component name and UPDATED badge
      expect(screen.getByText('LLM Component')).toBeInTheDocument();
      expect(screen.getByText('UPDATED')).toBeInTheDocument();
    });

    it('should detect added components', () => {
      const previewVersion = createMockPreviewVersion({
        configuration: {
          components: [
            {
              id: 'comp-1',
              component_type: 'llm_model',
              component_category: 'generic_component',
              data: { label: 'LLM Component' },
              configuration: { model: 'gpt-4' },
            } as any,
            {
              id: 'comp-2',
              component_type: 'output',
              component_category: 'generic_component',
              data: { label: 'New Output' },
              configuration: {},
            } as any,
          ],
          edges: [],
        },
      });

      const originalComponents: FlowComponent[] = [
        {
          id: 'comp-1',
          component_type: 'llm_model',
          component_category: 'generic_component',
          data: { label: 'LLM Component' },
          configuration: { model: 'gpt-4' },
        } as any,
      ];

      renderComponent(true, previewVersion, 1, originalComponents);
      expect(screen.getByText('New Output')).toBeInTheDocument();
      expect(screen.getByText('ADDED')).toBeInTheDocument();
    });

    it('should detect removed components', () => {
      const previewVersion = createMockPreviewVersion({
        configuration: {
          components: [],
          edges: [],
        },
      });

      const originalComponents: FlowComponent[] = [
        {
          id: 'comp-1',
          component_type: 'llm_model',
          component_category: 'generic_component',
          data: { label: 'Removed Component' },
          configuration: {},
        } as any,
      ];

      renderComponent(true, previewVersion, 1, originalComponents);
      expect(screen.getByText('Removed Component')).toBeInTheDocument();
      expect(screen.getByText('REMOVED')).toBeInTheDocument();
    });

    it('should handle undefined original components', () => {
      renderComponent(true, createMockPreviewVersion(), 1, undefined);
      expect(
        screen.getByText('No component changes detected between versions'),
      ).toBeInTheDocument();
    });

    it('should handle undefined preview components', () => {
      const previewVersion = createMockPreviewVersion({
        configuration: undefined,
      });

      renderComponent(true, previewVersion, 1, createMockOriginalComponents());
      expect(
        screen.getByText('No component changes detected between versions'),
      ).toBeInTheDocument();
    });
  });

  describe('User Interactions', () => {
    it('should call onBackToDraft when Back to current draft is clicked', () => {
      renderComponent();
      fireEvent.click(screen.getByRole('button', { name: 'Back to current draft' }));
      expect(mockOnBackToDraft).toHaveBeenCalledTimes(1);
    });

    it('should call onRestore when Replace draft with this version is clicked', () => {
      renderComponent();
      fireEvent.click(screen.getByRole('button', { name: /Replace draft with this version/i }));
      expect(mockOnRestore).toHaveBeenCalledTimes(1);
    });

    it('should call onClose when modal close is clicked', () => {
      renderComponent();
      fireEvent.click(screen.getByTestId('modal-close'));
      expect(mockOnClose).toHaveBeenCalledTimes(1);
    });
  });

  describe('Accordion Behavior', () => {
    it('should render accordion items for each change', () => {
      const originalComponents = createMockOriginalComponents();
      renderComponent(true, createMockPreviewVersion(), 1, originalComponents);

      // The accordion button should be clickable
      const accordionButton = screen.getByText('LLM Component').closest('button');
      expect(accordionButton).toBeInTheDocument();
    });

    it('should show change details when accordion is expanded', () => {
      const originalComponents = createMockOriginalComponents();
      renderComponent(true, createMockPreviewVersion(), 1, originalComponents);

      // Click to expand accordion
      const accordionButton = screen.getByText('LLM Component').closest('button');
      if (accordionButton) {
        fireEvent.click(accordionButton);
      }

      // Should show configuration diff details
      expect(screen.getByText(/Configuration changed/)).toBeInTheDocument();
    });
  });

  describe('Edge Cases', () => {
    it('should handle component without data.label', () => {
      const previewVersion = createMockPreviewVersion({
        configuration: {
          components: [
            {
              id: 'comp-1',
              component_type: 'llm_model',
              component_category: 'generic_component',
              configuration: { model: 'gpt-4' },
            } as any,
          ],
          edges: [],
        },
      });

      const originalComponents: FlowComponent[] = [
        {
          id: 'comp-2',
          component_type: 'output',
          component_category: 'generic_component',
          configuration: {},
        } as any,
      ];

      renderComponent(true, previewVersion, 1, originalComponents);
      // Should use component_type as fallback
      expect(screen.getByText('llm_model')).toBeInTheDocument();
      expect(screen.getByText('output')).toBeInTheDocument();
    });

    it('should handle component without component_type', () => {
      const previewVersion = createMockPreviewVersion({
        configuration: {
          components: [
            {
              id: 'comp-new',
              configuration: {},
            } as FlowComponent,
          ],
          edges: [],
        },
      });

      renderComponent(true, previewVersion, 1, []);
      // Should use 'Component' as fallback
      expect(screen.getByText('Component')).toBeInTheDocument();
    });
  });
});
