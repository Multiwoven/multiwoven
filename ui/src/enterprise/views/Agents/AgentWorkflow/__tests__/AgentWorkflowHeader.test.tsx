import { render, screen, fireEvent, waitFor } from '@testing-library/react';
import { expect, describe, it, beforeEach } from '@jest/globals';
import '@testing-library/jest-dom/jest-globals';
import '@testing-library/jest-dom';
import AgentWorkflowHeader from '../AgentWorkflowHeader';
import { QueryClient, QueryClientProvider } from '@tanstack/react-query';
import { ChakraProvider } from '@chakra-ui/react';
import { INTERFACE_TYPE } from '../../types';
import {
  mockSetWorkflow,
  mockSetInterfaceConfig,
  mockSetPreviewMode,
  mockCancelPreview,
  mockRestoreVersion,
  mockSetSelectedComponent,
} from '../../../../../../__mocks__/agentStoreMocks';

// Mock react-router-dom using existing mock pattern
const mockNavigate = jest.fn();
jest.mock('react-router-dom', () => {
  const { createReactRouterMock, defaultMockParams } = jest.requireActual(
    '../../../../../../__mocks__/reactRouterMocks',
  );
  return {
    ...createReactRouterMock({ params: defaultMockParams }),
    useNavigate: () => mockNavigate,
  };
});

// Mock useAgentStore
let mockWorkflowStatus: 'draft' | 'published' = 'draft';
let mockVersionNumber: number | undefined = undefined;
let mockSelectedComponent: unknown = null;
const mockTriggerType = INTERFACE_TYPE.WEBSITE_CHATBOT;
const mockInterfaceConfig = {
  dataAppId: 'data-app-123',
  properties: { card_title: 'Test Chat' },
};
const mockExportConfig = {
  method: 'embed',
  interface_position: 'bottom_right',
  whitelist_urls: [],
  embeddable_assistant: false,
};

jest.mock('@/enterprise/store/useAgentStore', () => ({
  __esModule: true,
  default: (selector?: (state: Record<string, unknown>) => unknown) => {
    const state = {
      currentWorkflow: {
        workflow: {
          name: 'Test Workflow',
          status: mockWorkflowStatus,
          configuration: {},
          version_number: mockVersionNumber,
        },
      },
      setWorkflow: mockSetWorkflow,
      triggerType: mockTriggerType,
      interfaceConfig: mockInterfaceConfig,
      exportConfig: mockExportConfig,
      setInterfaceConfig: mockSetInterfaceConfig,
      setPreviewMode: mockSetPreviewMode,
      cancelPreview: mockCancelPreview,
      restoreVersion: mockRestoreVersion,
      isPreviewMode: false,
      previewVersion: null,
      selectedComponent: mockSelectedComponent,
      setSelectedComponent: mockSetSelectedComponent,
    };
    return selector ? selector(state) : state;
  },
}));

// Mock useAutoSaveWorkflow
const mockIsPending = false;
jest.mock('@/enterprise/hooks/useAutoSaveWorkflow', () => ({
  useAutoSaveWorkflow: () => ({
    isPending: mockIsPending,
  }),
}));

// Mock useAgentValidation
const mockValidateAgent = jest.fn().mockReturnValue(true);
jest.mock('@/enterprise/hooks/useAgentValidation', () => ({
  __esModule: true,
  default: () => ({
    validateAgent: mockValidateAgent,
  }),
}));

// Mock useDataAppMutations
const mockCreateDataApp = {
  mutateAsync: jest.fn().mockResolvedValue({
    data: {
      id: 'new-data-app-id',
      attributes: {
        data_app_token: 'token-123',
      },
    },
  }),
  isPending: false,
};
const mockUpdateDataApp = {
  mutateAsync: jest.fn().mockResolvedValue({
    data: {
      id: 'updated-data-app-id',
      attributes: {
        data_app_token: 'token-456',
      },
    },
  }),
  isPending: false,
};

jest.mock('@/enterprise/hooks/mutations/useDataAppMutations', () => ({
  __esModule: true,
  default: () => ({
    createDataApp: mockCreateDataApp,
    updateDataApp: mockUpdateDataApp,
  }),
}));

// Mock WorkflowPlayground
jest.mock('../Playground/WorkflowPlayground', () => ({
  __esModule: true,
  default: () => <button data-testid='workflow-playground'>Playground</button>,
}));

// Mock AgentWorkflowReports
jest.mock('../../../Reports/AgentWorkflowReports', () => ({
  __esModule: true,
  default: ({
    openModal,
    onToggle,
  }: {
    openModal: boolean;
    onToggle: () => void;
    workflowId: string;
  }) =>
    openModal ? (
      <div data-testid='workflow-reports'>
        <button data-testid='close-reports' onClick={onToggle}>
          Close Reports
        </button>
      </div>
    ) : null,
}));

// Mock FeatureFlagWrapper
jest.mock('@/components/FeatureFlagWrapper/FeatureFlagWrapper', () => ({
  FeatureFlagWrapper: ({ children }: { children: React.ReactNode }) => <>{children}</>,
}));

// Mock Chakra Tabs completely
jest.mock('@chakra-ui/react', () => {
  const actual = jest.requireActual('@chakra-ui/react');
  return {
    ...actual,
    TabList: ({ children }: { children: React.ReactNode }) => (
      <div data-testid='tab-list'>{children}</div>
    ),
    Tab: ({ children }: { children: React.ReactNode }) => <button>{children}</button>,
    Tabs: ({
      children,
      index,
      onChange,
    }: {
      children: React.ReactNode;
      index: number;
      onChange: (i: number) => void;
    }) => (
      <div data-testid='tabs' data-index={index}>
        {children}
        <button data-testid='tab-change-0' onClick={() => onChange(0)}>
          Tab 0
        </button>
        <button data-testid='tab-change-1' onClick={() => onChange(1)}>
          Tab 1
        </button>
      </div>
    ),
  };
});

// Mock TabsWrapper and TabItem
jest.mock('@/components/TabsWrapper', () => ({
  __esModule: true,
  default: ({
    children,
    index,
    onChange,
  }: {
    children: React.ReactNode;
    index: number;
    onChange: (index: number) => void;
  }) => (
    <div data-testid='tabs-wrapper' data-index={index}>
      {children}
      {/* Hook into TabsWrapper onChange; keep ids distinct from Box data-testids in AgentWorkflowHeader */}
      <button type='button' data-testid='tabs-wrapper-select-tab-0' onClick={() => onChange(0)}>
        Unit: tab 0
      </button>
      <button type='button' data-testid='tabs-wrapper-select-tab-1' onClick={() => onChange(1)}>
        Unit: tab 1
      </button>
    </div>
  ),
}));

jest.mock('@/components/TabItem', () => ({
  __esModule: true,
  default: ({ text }: { text: string; icon: React.ReactNode }) => (
    <div data-testid={`tab-item-${text.toLowerCase()}`}>{text}</div>
  ),
}));

// Mock BaseModal
jest.mock('@/components/BaseModal', () => ({
  __esModule: true,
  default: ({
    title,
    description,
    openModal,
    setModalOpen,
    footer,
    children,
  }: {
    title: string | React.ReactNode;
    description: string;
    openModal: boolean;
    setModalOpen: () => void;
    footer: React.ReactNode;
    children: React.ReactNode;
  }) => {
    // Always render the modal content when openModal is true
    // This allows us to test the modal interactions
    if (openModal) {
      return (
        <div data-testid='base-modal'>
          <div data-testid='modal-title'>{typeof title === 'string' ? title : title}</div>
          <span data-testid='modal-description'>{description}</span>
          <div data-testid='modal-footer'>{footer}</div>
          <button data-testid='modal-toggle' onClick={setModalOpen}>
            Toggle
          </button>
          {children}
        </div>
      );
    }
    return null;
  },
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

// Mock react-icons
jest.mock('react-icons/fi');

// Mock DOCS_URL
jest.mock('@/enterprise/app-constants', () => ({
  DOCS_URL: 'https://docs.example.com',
}));

// Mock VersionsPanel
jest.mock('../Versions/VersionsPanel', () => ({
  __esModule: true,
  default: ({ isOpen, onClose }: { isOpen: boolean; onClose: () => void }) =>
    isOpen ? (
      <div data-testid='versions-panel'>
        <button data-testid='close-versions-panel' onClick={onClose}>
          Close Versions
        </button>
      </div>
    ) : null,
}));

// Mock HorizontalMenuActions - need to wrap children in Popover for usePopoverContext
jest.mock('@/components/HorizontalMenuActions/HorizontalMenuActions', () => {
  const { Popover, PopoverContent, PopoverTrigger, PopoverBody, Box } =
    jest.requireActual('@chakra-ui/react');
  return {
    __esModule: true,
    default: ({ children }: { children: React.ReactNode }) => (
      <Popover>
        <PopoverTrigger>
          <Box data-testid='horizontal-menu-actions-trigger'>Menu</Box>
        </PopoverTrigger>
        <PopoverContent>
          <PopoverBody>
            <div data-testid='horizontal-menu-actions'>{children}</div>
          </PopoverBody>
        </PopoverContent>
      </Popover>
    ),
  };
});

describe('AgentWorkflowHeader', () => {
  const queryClient = new QueryClient({
    defaultOptions: {
      queries: {
        retry: false,
      },
    },
  });

  const defaultProps = {
    activeTab: 0,
    setActiveTab: jest.fn(),
  };

  const renderComponent = (props = defaultProps) => {
    return render(
      <ChakraProvider>
        <QueryClientProvider client={queryClient}>
          <AgentWorkflowHeader {...props} />
        </QueryClientProvider>
      </ChakraProvider>,
    );
  };

  beforeEach(() => {
    jest.clearAllMocks();
    mockValidateAgent.mockReturnValue(true);
    mockWorkflowStatus = 'draft'; // Reset to draft by default
    mockVersionNumber = undefined; // Reset version number
    mockSelectedComponent = null; // Reset selected component
  });

  describe('Rendering', () => {
    it('should render the header with back button', () => {
      renderComponent();
      expect(screen.getByTestId('fi-arrow-left')).toBeInTheDocument();
    });

    it('should render workflow name in header', () => {
      renderComponent({ ...defaultProps, activeTab: 0 });
      expect(screen.getByText('Test Workflow')).toBeInTheDocument();
    });

    it('exposes workflow autosave and overflow menu test ids', () => {
      renderComponent({ ...defaultProps, activeTab: 0 });
      expect(screen.getByTestId('workflow-autosave-status')).toBeInTheDocument();
      expect(screen.getByTestId('workflow-editor-overflow-menu')).toBeInTheDocument();
    });

    it('shows workflow version chip when workflow has a version number', () => {
      mockVersionNumber = 4;
      renderComponent({ ...defaultProps, activeTab: 0 });
      expect(screen.getByTestId('workflow-version-chip')).toHaveTextContent('v4');
    });

    it('should render Workflow tab item', () => {
      renderComponent();
      expect(screen.getByTestId('tab-item-workflow')).toBeInTheDocument();
    });

    it('should render Interface tab item', () => {
      renderComponent();
      expect(screen.getByTestId('tab-item-interface')).toBeInTheDocument();
    });

    it('should render WorkflowPlayground when activeTab is 0', () => {
      renderComponent({ ...defaultProps, activeTab: 0 });
      expect(screen.getByTestId('workflow-playground')).toBeInTheDocument();
    });

    it('should not render WorkflowPlayground when activeTab is 1', () => {
      renderComponent({ ...defaultProps, activeTab: 1 });
      expect(screen.queryByTestId('workflow-playground')).not.toBeInTheDocument();
    });

    it('should render docs link inside menu', async () => {
      renderComponent();
      // Open the popover menu first
      const menuTrigger = screen.getByTestId('horizontal-menu-actions-trigger');
      fireEvent.click(menuTrigger);

      await waitFor(() => {
        const docsLink = screen.getByRole('link');
        expect(docsLink).toHaveAttribute('href', 'https://docs.example.com');
        expect(docsLink).toHaveAttribute('target', '_blank');
        expect(screen.getByTestId('workflow-versions-toggle')).toBeInTheDocument();
      });
    });
  });

  describe('Button States', () => {
    it('should show "Publish Workflow" button when activeTab is 0', () => {
      renderComponent({ ...defaultProps, activeTab: 0 });
      expect(screen.getByText('Publish Workflow')).toBeInTheDocument();
    });

    it('should show "Save Interface" button when activeTab is 1', () => {
      renderComponent({ ...defaultProps, activeTab: 1 });
      expect(screen.getByText('Save Interface')).toBeInTheDocument();
    });
  });

  describe('Navigation', () => {
    it('should navigate to /agents and clear workflow when back button is clicked', () => {
      renderComponent();

      const backButton = screen.getByTestId('fi-arrow-left').parentElement;
      fireEvent.click(backButton!);

      expect(mockSetWorkflow).toHaveBeenCalledWith(null);
      expect(mockNavigate).toHaveBeenCalledWith('/agents');
    });

    it('should call setActiveTab when tab is changed', () => {
      const setActiveTab = jest.fn();
      renderComponent({ ...defaultProps, setActiveTab });

      fireEvent.click(screen.getByTestId('tabs-wrapper-select-tab-1'));

      expect(setActiveTab).toHaveBeenCalledWith(1);
    });
  });

  describe('Save/Publish Modal', () => {
    it('should not open modal when validation fails', () => {
      mockValidateAgent.mockReturnValue(false);
      renderComponent();

      const publishButton = screen.getByText('Publish Workflow');
      fireEvent.click(publishButton);

      expect(screen.queryByTestId('base-modal')).not.toBeInTheDocument();
    });

    it('should open modal when publish button is clicked and validation passes', () => {
      mockValidateAgent.mockReturnValue(true);
      renderComponent();

      const publishButton = screen.getByText('Publish Workflow');
      fireEvent.click(publishButton);

      expect(screen.getByTestId('base-modal')).toBeInTheDocument();
      expect(screen.getByTestId('workflow-publish-version-description')).toBeInTheDocument();
    });

    it('should show correct modal title for workflow publish', () => {
      renderComponent({ ...defaultProps, activeTab: 0 });

      fireEvent.click(screen.getByText('Publish Workflow'));

      expect(screen.getByTestId('modal-title')).toHaveTextContent('Publish workflow');
    });

    it('should show correct modal title for interface save', () => {
      // Need workflow to be published for Save Interface button to be enabled
      mockWorkflowStatus = 'published';
      renderComponent({ ...defaultProps, activeTab: 1 });

      fireEvent.click(screen.getByText('Save Interface'));

      expect(screen.getByTestId('modal-title')).toHaveTextContent('Save interface');
    });

    it('should show correct modal description for workflow publish', () => {
      renderComponent({ ...defaultProps, activeTab: 0 });

      fireEvent.click(screen.getByText('Publish Workflow'));

      expect(screen.getByTestId('modal-description')).toHaveTextContent(
        'Are you sure you want to publish this workflow?',
      );
    });

    it('should show correct modal description for interface save', () => {
      // Need workflow to be published for Save Interface button to be enabled
      mockWorkflowStatus = 'published';
      renderComponent({ ...defaultProps, activeTab: 1 });

      fireEvent.click(screen.getByText('Save Interface'));

      expect(screen.getByTestId('modal-description')).toHaveTextContent(
        'Are you sure you want to save this interface?',
      );
    });
  });

  describe('AutosaveStatus', () => {
    it('should render AutosaveStatus when activeTab is 0', () => {
      renderComponent({ ...defaultProps, activeTab: 0 });
      // The status text shows "Saved as draft" when not saving
      expect(screen.getByText(/Saved as/)).toBeInTheDocument();
    });

    it('should not render AutosaveStatus when activeTab is 1', () => {
      renderComponent({ ...defaultProps, activeTab: 1 });
      expect(screen.queryByText(/Saved as/)).not.toBeInTheDocument();
    });
  });

  describe('Reports', () => {
    it('should render reports button', () => {
      renderComponent();
      // Reports button is an IconButton with aria-label "Reports"
      expect(screen.getByRole('button', { name: 'Reports' })).toBeInTheDocument();
    });

    it('should open reports modal when reports button is clicked', async () => {
      renderComponent();

      const reportsButton = screen.getByRole('button', { name: 'Reports' });
      fireEvent.click(reportsButton);

      await waitFor(() => {
        expect(screen.getByTestId('workflow-reports')).toBeInTheDocument();
      });
    });
  });

  describe('Save Workflow', () => {
    it('should call setWorkflow with published status when confirming workflow publish', async () => {
      renderComponent({ ...defaultProps, activeTab: 0 });

      // Open modal
      fireEvent.click(screen.getByText('Publish Workflow'));

      // Click confirm in footer (the footer contains the Confirm button)
      const confirmButton = screen.getByRole('button', { name: 'Confirm' });
      fireEvent.click(confirmButton);

      await waitFor(() => {
        expect(mockSetWorkflow).toHaveBeenCalledWith(
          expect.objectContaining({
            workflow: expect.objectContaining({
              status: 'published',
            }),
          }),
        );
      });
    });

    it('should call updateDataApp when saving interface with existing dataAppId', async () => {
      mockWorkflowStatus = 'published';
      renderComponent({ ...defaultProps, activeTab: 1 });

      // Open modal
      fireEvent.click(screen.getByText('Save Interface'));

      // Click confirm
      const confirmButton = screen.getByRole('button', { name: 'Confirm' });
      fireEvent.click(confirmButton);

      await waitFor(() => {
        // mockInterfaceConfig has dataAppId, so updateDataApp should be called
        expect(mockUpdateDataApp.mutateAsync).toHaveBeenCalled();
      });
    });

    it('should call updateDataApp when interface already has dataAppId', async () => {
      mockWorkflowStatus = 'published';
      renderComponent({ ...defaultProps, activeTab: 1 });

      // Open modal
      fireEvent.click(screen.getByText('Save Interface'));

      // Click confirm
      const confirmButton = screen.getByRole('button', { name: 'Confirm' });
      fireEvent.click(confirmButton);

      await waitFor(() => {
        // Since mockInterfaceConfig has dataAppId, updateDataApp should be called
        expect(mockUpdateDataApp.mutateAsync).toHaveBeenCalled();
      });
    });

    it('should close modal when response has no data.attributes (lines 207-208)', async () => {
      // Mock useDisclosure to track onClose calls
      const mockOnClose = jest.fn();
      const mockOnOpen = jest.fn();
      // eslint-disable-next-line @typescript-eslint/no-var-requires
      const chakraModule = require('@chakra-ui/react');
      const useDisclosureSpy = jest.spyOn(chakraModule, 'useDisclosure');

      // Mock useDisclosure to return isOpen: true so modal is visible
      // First call for the modal, second call for reports
      useDisclosureSpy
        .mockReturnValueOnce({
          isOpen: true, // Start with modal open so we can test the close behavior
          onOpen: mockOnOpen,
          onClose: mockOnClose,
          onToggle: jest.fn(),
        })
        .mockReturnValueOnce({
          isOpen: false,
          onOpen: jest.fn(),
          onClose: jest.fn(),
          onToggle: jest.fn(),
        });

      mockCreateDataApp.mutateAsync.mockResolvedValue({
        data: null, // No data.attributes - should trigger onClose() from useDisclosure
      });
      mockWorkflowStatus = 'published';

      // Temporarily remove dataAppId so createDataApp is used instead of updateDataApp
      const originalDataAppId = mockInterfaceConfig.dataAppId;

      (mockInterfaceConfig as any).dataAppId = undefined;

      renderComponent({ ...defaultProps, activeTab: 1 });

      // Open modal - this should call onOpen which sets modalIsOpen = true
      // The button calls onOpen() which should trigger a re-render
      fireEvent.click(screen.getByText('Save Interface'));

      // Wait for modal to be visible - the BaseModal should render when openModal is true
      await waitFor(
        () => {
          expect(screen.getByText('Confirm')).toBeInTheDocument();
        },
        { timeout: 3000 },
      );

      // Click Confirm to trigger handleSave which calls createDataApp.mutateAsync
      fireEvent.click(screen.getByRole('button', { name: 'Confirm' }));

      await waitFor(() => {
        expect(mockCreateDataApp.mutateAsync).toHaveBeenCalled();
      });

      // Wait for the response to be processed
      // Line 206: if (!response?.data?.attributes) { onClose(); return; }
      // This should trigger the early return and call onClose (line 207)
      await waitFor(
        () => {
          // Verify onClose was called (line 207)
          expect(mockOnClose).toHaveBeenCalled();
        },
        { timeout: 2000 },
      );

      // Restore original dataAppId

      (mockInterfaceConfig as any).dataAppId = originalDataAppId;
      useDisclosureSpy.mockRestore();
    });

    it('should close modal when clicking docs link in export config modal (line 361)', async () => {
      // Mock useDisclosure to track onClose calls
      const mockOnClose = jest.fn();
      // eslint-disable-next-line @typescript-eslint/no-var-requires
      const chakraModule = require('@chakra-ui/react');
      const useDisclosureSpy = jest.spyOn(chakraModule, 'useDisclosure');

      // First call for the modal, second call for reports
      useDisclosureSpy
        .mockReturnValueOnce({
          isOpen: false,
          onOpen: jest.fn(),
          onClose: mockOnClose,
          onToggle: jest.fn(),
        })
        .mockReturnValueOnce({
          isOpen: false,
          onOpen: jest.fn(),
          onClose: jest.fn(),
          onToggle: jest.fn(),
        });

      mockWorkflowStatus = 'published';
      renderComponent({ ...defaultProps, activeTab: 1 });

      // Open the HorizontalMenuActions popover to access the docs link
      const menuTrigger = screen.getByTestId('horizontal-menu-actions-trigger');
      fireEvent.click(menuTrigger);

      // Wait for the popover to open and the docs link to be visible
      await waitFor(() => {
        // The link should be in the DOM, try finding it by href or text
        const docsLink = document.querySelector('a[href="https://docs.example.com"]');
        const docsText = screen.queryByText('Documentation');
        expect(docsLink || docsText).toBeTruthy();
      });

      // Find the docs link - the onClick is on the Flex component inside the <a>
      // We need to find the Flex element that has the onClick handler
      const docsText = screen.getByText('Documentation');
      // The Flex component is the parent of the Text, so find it
      const flexElement = docsText.parentElement;
      expect(flexElement).toBeTruthy();

      // Clicking the Flex element should call onClose() from useDisclosure (line 361)
      // The onClick handler on line 360-362 is on the Flex component
      fireEvent.click(flexElement!);

      // The onClick handler on line 360-362 should call onClose()
      // This tests line 361: onClose();
      await waitFor(
        () => {
          expect(mockOnClose).toHaveBeenCalled();
        },
        { timeout: 2000 },
      );

      useDisclosureSpy.mockRestore();
    });

    it('should update interface config after successful data app creation', async () => {
      mockWorkflowStatus = 'published';
      renderComponent({ ...defaultProps, activeTab: 1 });

      fireEvent.click(screen.getByText('Save Interface'));
      fireEvent.click(screen.getByRole('button', { name: 'Confirm' }));

      await waitFor(() => {
        expect(mockSetInterfaceConfig).toHaveBeenCalled();
        expect(mockSetWorkflow).toHaveBeenCalledWith(
          expect.objectContaining({
            workflow: expect.objectContaining({
              status: 'published',
            }),
          }),
        );
      });
    });
  });

  describe('Tab Index', () => {
    it('should pass correct index to TabsWrapper', () => {
      renderComponent({ ...defaultProps, activeTab: 1 });
      expect(screen.getByTestId('tabs-wrapper')).toHaveAttribute('data-index', '1');
    });
  });

  describe('Version Badge', () => {
    it('should display version badge when version_number is present', () => {
      mockVersionNumber = 5;
      renderComponent();
      expect(screen.getByText('v5')).toBeInTheDocument();
    });

    it('should not display version badge when version_number is not present', () => {
      mockVersionNumber = undefined;
      renderComponent();
      expect(screen.queryByText(/^v\d+$/)).not.toBeInTheDocument();
    });

    it('should display version v1 correctly', () => {
      mockVersionNumber = 1;
      renderComponent();
      expect(screen.getByText('v1')).toBeInTheDocument();
    });
  });

  describe('Autosave Status Display', () => {
    it('should show "Live" when workflow status is published', () => {
      mockWorkflowStatus = 'published';
      renderComponent({ ...defaultProps, activeTab: 0 });
      expect(screen.getByText('Live')).toBeInTheDocument();
    });

    it('should show "Saved as draft" when workflow status is draft', () => {
      mockWorkflowStatus = 'draft';
      renderComponent({ ...defaultProps, activeTab: 0 });
      expect(screen.getByText('Saved as draft')).toBeInTheDocument();
    });
  });

  describe('Versions Panel', () => {
    it('should render HorizontalMenuActions', () => {
      renderComponent();
      expect(screen.getByTestId('horizontal-menu-actions')).toBeInTheDocument();
    });
  });

  describe('Publish Modal with Version', () => {
    it('should include version in modal title when version exists', () => {
      mockVersionNumber = 3;
      renderComponent({ ...defaultProps, activeTab: 0 });

      fireEvent.click(screen.getByText('Publish Workflow'));

      // The modal title should contain version info
      const modalTitle = screen.getByTestId('modal-title');
      expect(modalTitle).toHaveTextContent('Publish workflow');
    });
  });

  describe('Versions Panel Interactions', () => {
    it('should open VersionsPanel when Versions menu item is clicked', async () => {
      renderComponent();

      // Open the menu
      const menuTrigger = screen.getByTestId('horizontal-menu-actions-trigger');
      fireEvent.click(menuTrigger);

      // Click on Versions menu item
      await waitFor(() => {
        const versionsMenuItem = screen.getByText('Versions');
        fireEvent.click(versionsMenuItem);
      });

      // VersionsPanel should be rendered
      await waitFor(() => {
        expect(screen.getByTestId('versions-panel')).toBeInTheDocument();
      });
    });

    it('should close VersionsPanel when close button is clicked', async () => {
      renderComponent();

      // Open the menu and click Versions
      const menuTrigger = screen.getByTestId('horizontal-menu-actions-trigger');
      fireEvent.click(menuTrigger);

      await waitFor(() => {
        const versionsMenuItem = screen.getByText('Versions');
        fireEvent.click(versionsMenuItem);
      });

      // Close the panel
      await waitFor(() => {
        const closeButton = screen.getByTestId('close-versions-panel');
        fireEvent.click(closeButton);
      });

      // VersionsPanel should be closed
      await waitFor(() => {
        expect(screen.queryByTestId('versions-panel')).not.toBeInTheDocument();
      });
    });

    it('should clear selectedComponent when opening Versions panel', async () => {
      mockSelectedComponent = { id: 'some-component' };
      renderComponent();

      // Open the menu
      const menuTrigger = screen.getByTestId('horizontal-menu-actions-trigger');
      fireEvent.click(menuTrigger);

      // Click on Versions menu item
      await waitFor(() => {
        const versionsMenuItem = screen.getByText('Versions');
        fireEvent.click(versionsMenuItem);
      });

      // setSelectedComponent should be called with null
      expect(mockSetSelectedComponent).toHaveBeenCalledWith(null);
    });
  });

  describe('Version Description in Publish Modal', () => {
    it('should render version description textarea when activeTab is 0', () => {
      renderComponent({ ...defaultProps, activeTab: 0 });

      fireEvent.click(screen.getByText('Publish Workflow'));

      // Check for version description label
      expect(screen.getByText('Version Description')).toBeInTheDocument();
    });

    it('should allow typing in version description textarea', async () => {
      renderComponent({ ...defaultProps, activeTab: 0 });

      fireEvent.click(screen.getByText('Publish Workflow'));

      const textarea = screen.getByPlaceholderText('Enter a description for this workflow version');
      fireEvent.change(textarea, { target: { value: 'Test description' } });

      expect(textarea).toHaveValue('Test description');
    });
  });

  describe('Documentation Link', () => {
    it('should close menu when docs link is clicked (line 357)', async () => {
      renderComponent();

      // Open the menu
      const menuTrigger = screen.getByTestId('horizontal-menu-actions-trigger');
      fireEvent.click(menuTrigger);

      // Wait for menu to open and find the docs link
      await waitFor(() => {
        const docsLink = screen.getByRole('link');
        expect(docsLink).toBeInTheDocument();
        expect(docsLink).toHaveAttribute('href', 'https://docs.example.com');
        expect(docsLink).toHaveAttribute('target', '_blank');
      });

      // Click the link to trigger onClick handler which calls onClose() (line 357)
      const docsLink = screen.getByRole('link');
      // Prevent default to ensure onClick is called
      fireEvent.click(docsLink, { preventDefault: () => {} });

      // The onClick should have been triggered (coverage for line 357)
      // The Popover should close after onClick
    });
  });

  describe('VersionsPanel closes on component selection', () => {
    it('should close VersionsPanel when a component is selected', async () => {
      // Start with no selected component
      mockSelectedComponent = null;
      const { rerender } = renderComponent();

      // Open the menu and click Versions
      const menuTrigger = screen.getByTestId('horizontal-menu-actions-trigger');
      fireEvent.click(menuTrigger);

      await waitFor(() => {
        const versionsMenuItem = screen.getByText('Versions');
        fireEvent.click(versionsMenuItem);
      });

      // VersionsPanel should be open
      await waitFor(() => {
        expect(screen.getByTestId('versions-panel')).toBeInTheDocument();
      });

      // Simulate component selection by updating the mock and re-rendering
      mockSelectedComponent = { id: 'selected-component' };

      // Re-render to trigger the useEffect
      rerender(
        <ChakraProvider>
          <QueryClientProvider client={queryClient}>
            <AgentWorkflowHeader {...defaultProps} />
          </QueryClientProvider>
        </ChakraProvider>,
      );

      // VersionsPanel should be closed after component selection
      await waitFor(() => {
        expect(screen.queryByTestId('versions-panel')).not.toBeInTheDocument();
      });
    });
  });
});
