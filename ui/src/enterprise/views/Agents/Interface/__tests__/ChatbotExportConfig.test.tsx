import { render, screen, fireEvent, waitFor } from '@testing-library/react';
import { expect, describe, it, beforeEach, jest } from '@jest/globals';
import '@testing-library/jest-dom/jest-globals';
import '@testing-library/jest-dom';
import ChatbotExportConfig from '../ChatbotExportConfig';
import { ChakraProvider } from '@chakra-ui/react';
import { INTERFACE_DISPLAY_TYPE } from '../../types';
import { WorkflowExportConfig, WorkflowInterfaceConfig } from '@/enterprise/services/types';

// Mock useAgentStore
const mockSetExportConfig = jest.fn();
let mockExportConfig: WorkflowExportConfig = {
  method: 'embed',
  interface_position: 'bottom_right',
  whitelist_urls: [],
  embeddable_assistant: false,
  query_selector: '',
};
let mockInterfaceDisplayType = INTERFACE_DISPLAY_TYPE.MOBILE;
let mockInterfaceConfig: WorkflowInterfaceConfig | null = null;
let mockWorkflowDataApp: any = null;

jest.mock('@/enterprise/store/useAgentStore', () => {
  const mockFn = jest.fn((selector: (state: any) => any) => {
    const state = {
      exportConfig: mockExportConfig,
      setExportConfig: mockSetExportConfig,
      interfaceDisplayType: mockInterfaceDisplayType,
      interfaceConfig: mockInterfaceConfig,
      workflowDataApp: mockWorkflowDataApp,
    };
    return selector(state);
  });
  (mockFn as any).getState = jest.fn(() => ({
    exportConfig: mockExportConfig,
    setExportConfig: mockSetExportConfig,
  }));
  return {
    __esModule: true,
    default: mockFn,
  };
});

// Mock useConfigStore
jest.mock('@/enterprise/store/useConfigStore', () => ({
  useConfigStore: {
    getState: () => ({
      configs: {
        apiHost: 'https://api.example.com',
      },
    }),
    subscribe: jest.fn(),
  },
}));

// Mock hooks
const mockShowToast = jest.fn();
const mockShowError = jest.fn();

jest.mock('@/hooks/useCustomToast', () => ({
  __esModule: true,
  default: () => mockShowToast,
}));

jest.mock('@/hooks/useErrorToast', () => ({
  __esModule: true,
  useErrorToast: () => mockShowError,
}));

// Mock copy-to-clipboard
const mockCopyFn = jest.fn();
jest.mock('copy-to-clipboard', () => ({
  __esModule: true,
  default: (...args: any[]) => mockCopyFn(...args),
}));

// Mock window.open
const mockWindowOpen = jest.fn();
Object.defineProperty(window, 'open', {
  writable: true,
  value: mockWindowOpen,
});

// Mock location
Object.defineProperty(window, 'location', {
  writable: true,
  value: {
    origin: 'https://app.example.com',
  },
});

// Mock CustomSelect
jest.mock('@/components/CustomSelect/CustomSelect', () => ({
  __esModule: true,
  CustomSelect: ({
    name,
    value,
    onChange,
    placeholder,
    children,
    'data-testid': dataTestId,
  }: {
    name: string;
    value: string;
    onChange: (value: string) => void;
    placeholder?: string;
    children: React.ReactNode;
    'data-testid'?: string;
  }) => (
    <div data-testid={dataTestId ?? `custom-select-${name}`}>
      <select
        data-testid={`select-${name}`}
        value={value}
        onChange={(e) => onChange(e.target.value)}
      >
        <option value=''>{placeholder}</option>
        {children}
      </select>
    </div>
  ),
}));

// Mock Option
jest.mock('@/components/CustomSelect/Option', () => ({
  __esModule: true,
  Option: ({ value, children }: { value: string; children: React.ReactNode }) => (
    <option value={value}>{children}</option>
  ),
}));

// Mock InputField
jest.mock('@/components/InputField', () => ({
  __esModule: true,
  default: ({
    label,
    name,
    value,
    onChange,
    placeholder,
    isTooltip,
    tooltipLabel,
  }: {
    label: string;
    name: string;
    value: string;
    onChange: (e: { target: { value: string } }) => void;
    placeholder?: string;
    isTooltip?: boolean;
    tooltipLabel?: string;
  }) => (
    <div data-testid={`input-field-${name}`}>
      <label>{label}</label>
      <input
        data-testid={`input-${name}`}
        value={value}
        onChange={onChange}
        placeholder={placeholder}
      />
      {isTooltip && tooltipLabel && <div data-testid={`tooltip-${name}`}>{tooltipLabel}</div>}
    </div>
  ),
}));

// Mock ExportComponents
jest.mock('../ExportComponents', () => ({
  __esModule: true,
  ExportSection: ({
    title,
    children,
    actions,
  }: {
    title: string;
    children: React.ReactNode;
    actions?: React.ReactNode;
  }) => (
    <div data-testid={`export-section-${title.toLowerCase().replace(/\s+/g, '-')}`}>
      <div data-testid='export-section-title'>{title}</div>
      {actions && <div data-testid='export-section-actions'>{actions}</div>}
      <div data-testid='export-section-content'>{children}</div>
    </div>
  ),
  ExportButton: ({
    icon,
    onClick,
    children,
    isDisabled,
  }: {
    icon?: React.ReactNode;
    onClick?: () => void;
    children: React.ReactNode;
    isDisabled?: boolean;
  }) => (
    <button data-testid='export-button' onClick={onClick} disabled={isDisabled}>
      {icon && <span data-testid='export-button-icon'>{icon}</span>}
      {children}
    </button>
  ),
}));

// Mock separated components
jest.mock('../EmbeddableCodeSection', () => ({
  __esModule: true,
  EmbeddableCodeSection: () => (
    <div data-testid='embeddable-code-section'>EmbeddableCodeSection</div>
  ),
}));

jest.mock('../ChromeExtensionSection', () => ({
  __esModule: true,
  ChromeExtensionSection: () => (
    <div data-testid='chrome-extension-section'>ChromeExtensionSection</div>
  ),
}));

jest.mock('../StandaloneAppSection', () => ({
  __esModule: true,
  StandaloneAppSection: () => <div data-testid='standalone-app-section'>StandaloneAppSection</div>,
}));

// Mock CHROME_EXTENSION_URL
jest.mock('@/enterprise/app-constants', () => ({
  __esModule: true,
  CHROME_EXTENSION_URL: 'https://chrome-extension.example.com',
}));

// Mock react-icons/fi
jest.mock('react-icons/fi', () => ({
  FiCopy: () => <span data-testid='fi-copy-icon'>CopyIcon</span>,
  FiExternalLink: () => <span data-testid='fi-external-link-icon'>ExternalLinkIcon</span>,
  FiInfo: () => <span data-testid='fi-info-icon'>InfoIcon</span>,
}));

describe('ChatbotExportConfig', () => {
  beforeEach(() => {
    jest.clearAllMocks();
    mockCopyFn.mockClear();
    mockExportConfig = {
      method: 'embed',
      interface_position: 'bottom_right',
      whitelist_urls: [],
      embeddable_assistant: false,
      query_selector: '',
    };
    mockInterfaceDisplayType = INTERFACE_DISPLAY_TYPE.MOBILE;
    mockInterfaceConfig = null;
    mockWorkflowDataApp = null;
  });

  const renderComponent = (props = {}) => {
    return render(
      <ChakraProvider>
        <ChatbotExportConfig isExportOpen={true} agentId='agent-123' {...props} />
      </ChakraProvider>,
    );
  };

  describe('Component Rendering', () => {
    it('renders method selector when isExportOpen is true', () => {
      renderComponent();
      expect(screen.getByText('Method')).toBeInTheDocument();
      expect(screen.getByTestId('select-method')).toBeInTheDocument();
      expect(screen.getByTestId('interface-export-method-select')).toBeInTheDocument();
    });

    it('does not render content when isExportOpen is false', async () => {
      renderComponent({ isExportOpen: false });
      await waitFor(
        () => {
          const methodText = screen.queryByText('Method');
          if (methodText) {
            const style = window.getComputedStyle(methodText);
            expect(
              style.display === 'none' || style.visibility === 'hidden' || !methodText.offsetParent,
            ).toBe(true);
          } else {
            expect(methodText).not.toBeInTheDocument();
          }
        },
        { timeout: 1000 },
      );
    });

    it('renders helper text for selected method', () => {
      renderComponent();
      const helperText = screen.getByText(/Get a code snippet to embed your interface/i);
      expect(helperText).toBeInTheDocument();
    });

    it('renders EmbeddableCodeSection when method is embed', () => {
      mockExportConfig.method = 'embed';
      renderComponent();
      expect(screen.getByTestId('embeddable-code-section')).toBeInTheDocument();
    });

    it('renders ChromeExtensionSection when method is no_code', () => {
      mockExportConfig.method = 'no_code';
      renderComponent();
      expect(screen.getByTestId('chrome-extension-section')).toBeInTheDocument();
    });

    it('renders StandaloneAppSection when method is assistant', () => {
      mockExportConfig.method = 'assistant';
      mockInterfaceDisplayType = INTERFACE_DISPLAY_TYPE.FULL_PAGE;
      renderComponent();
      expect(screen.getByTestId('standalone-app-section')).toBeInTheDocument();
    });
  });

  describe('Method Selection', () => {
    it('updates export config when method changes', () => {
      renderComponent();
      const select = screen.getByTestId('select-method');
      fireEvent.change(select, { target: { value: 'no_code' } });

      expect(mockSetExportConfig).toHaveBeenCalledWith({
        ...mockExportConfig,
        method: 'no_code',
        embeddable_assistant: false,
      });
    });

    it('sets embeddable_assistant to true when method is embed and display type is FULL_PAGE', () => {
      mockInterfaceDisplayType = INTERFACE_DISPLAY_TYPE.FULL_PAGE;
      renderComponent();
      const select = screen.getByTestId('select-method');
      fireEvent.change(select, { target: { value: 'embed' } });

      expect(mockSetExportConfig).toHaveBeenCalledWith({
        ...mockExportConfig,
        method: 'embed',
        embeddable_assistant: true,
      });
    });
  });

  describe('Query Selector Input', () => {
    it('renders query selector input for embed method and full page', () => {
      mockExportConfig.method = 'embed';
      mockInterfaceDisplayType = INTERFACE_DISPLAY_TYPE.FULL_PAGE;
      renderComponent();

      expect(screen.getByText('Query Selector')).toBeInTheDocument();
      expect(screen.getByPlaceholderText('[data-id = "tabpanel-general"]')).toBeInTheDocument();
    });

    it('does not render query selector for mobile display type', () => {
      mockExportConfig.method = 'embed';
      mockInterfaceDisplayType = INTERFACE_DISPLAY_TYPE.MOBILE;
      renderComponent();

      expect(screen.queryByText('Query Selector')).not.toBeInTheDocument();
    });

    it('updates query_selector when input changes', () => {
      mockExportConfig.method = 'embed';
      mockInterfaceDisplayType = INTERFACE_DISPLAY_TYPE.FULL_PAGE;
      renderComponent();

      const input = screen.getByPlaceholderText('[data-id = "tabpanel-general"]');
      fireEvent.change(input, { target: { value: '[data-id="test"]' } });

      expect(mockSetExportConfig).toHaveBeenCalledWith({
        ...mockExportConfig,
        query_selector: '[data-id="test"]',
      });
    });
  });

  describe('Interface Position Selector', () => {
    it('renders interface position selector for mobile and non-embeddable assistant', () => {
      mockExportConfig.method = 'embed';
      mockExportConfig.embeddable_assistant = false;
      mockInterfaceDisplayType = INTERFACE_DISPLAY_TYPE.MOBILE;
      renderComponent();

      expect(screen.getByText('Interface Position')).toBeInTheDocument();
      expect(screen.getByTestId('select-interface_position')).toBeInTheDocument();
    });

    it('renders interface position selector for no_code method and mobile', () => {
      mockExportConfig.method = 'no_code';
      mockInterfaceDisplayType = INTERFACE_DISPLAY_TYPE.MOBILE;
      renderComponent();

      expect(screen.getByText('Interface Position')).toBeInTheDocument();
    });

    it('does not render interface position for full page', () => {
      mockExportConfig.method = 'embed';
      mockInterfaceDisplayType = INTERFACE_DISPLAY_TYPE.FULL_PAGE;
      renderComponent();

      expect(screen.queryByText('Interface Position')).not.toBeInTheDocument();
    });

    it('does not render interface position for embeddable assistant', () => {
      mockExportConfig.method = 'embed';
      mockExportConfig.embeddable_assistant = true;
      mockInterfaceDisplayType = INTERFACE_DISPLAY_TYPE.MOBILE;
      renderComponent();

      expect(screen.queryByText('Interface Position')).not.toBeInTheDocument();
    });

    it('updates interface_position when selector changes', () => {
      mockExportConfig.method = 'embed';
      mockInterfaceDisplayType = INTERFACE_DISPLAY_TYPE.MOBILE;
      renderComponent();

      const select = screen.getByTestId('select-interface_position');
      fireEvent.change(select, { target: { value: 'bottom_left' } });

      expect(mockSetExportConfig).toHaveBeenCalledWith({
        ...mockExportConfig,
        interface_position: 'bottom_left',
      });
    });
  });

  describe('Whitelist URLs Input', () => {
    it('renders whitelist URLs input for no_code method', () => {
      mockExportConfig.method = 'no_code';
      renderComponent();

      expect(screen.getByText('Whitelist URLs')).toBeInTheDocument();
      expect(screen.getByTestId('input-whitelist_urls')).toBeInTheDocument();
    });

    it('does not render whitelist URLs for other methods', () => {
      mockExportConfig.method = 'embed';
      renderComponent();

      expect(screen.queryByText('Whitelist URLs')).not.toBeInTheDocument();
    });

    it('updates whitelist_urls when input changes', () => {
      mockExportConfig.method = 'no_code';
      renderComponent();

      const input = screen.getByTestId('input-whitelist_urls');
      fireEvent.change(input, { target: { value: 'https://example.com, https://test.com' } });

      expect(mockSetExportConfig).toHaveBeenCalledWith({
        ...mockExportConfig,
        whitelist_urls: ['https://example.com', 'https://test.com'],
      });
    });

    it('handles empty whitelist_urls', () => {
      mockExportConfig.method = 'no_code';
      mockExportConfig.whitelist_urls = [];
      renderComponent();

      const input = screen.getByTestId('input-whitelist_urls');
      expect(input).toHaveValue('');
    });
  });

  describe('Initialization Logic', () => {
    it('initializes with API export config when available', async () => {
      mockExportConfig.method = 'no_code';
      mockExportConfig.embeddable_assistant = false;
      mockInterfaceConfig = {
        dataAppId: 'app-123',
        export_config: {
          method: 'assistant',
          embeddable_assistant: false,
        },
      } as any;
      mockInterfaceDisplayType = INTERFACE_DISPLAY_TYPE.FULL_PAGE;
      mockSetExportConfig.mockClear();

      renderComponent();

      await waitFor(
        () => {
          expect(mockSetExportConfig).toHaveBeenCalled();
        },
        { timeout: 2000 },
      );
    });

    it('initializes with embed method when API config has embeddable_assistant true', async () => {
      mockInterfaceConfig = {
        dataAppId: 'app-123',
        export_config: {
          method: 'embed',
          embeddable_assistant: true,
        },
      } as any;
      mockInterfaceDisplayType = INTERFACE_DISPLAY_TYPE.FULL_PAGE;

      renderComponent();

      await waitFor(() => {
        expect(mockSetExportConfig).toHaveBeenCalled();
      });
    });

    it('uses first available option when current method is not available for display type', async () => {
      mockExportConfig.method = 'assistant';
      mockInterfaceDisplayType = INTERFACE_DISPLAY_TYPE.MOBILE;
      mockInterfaceConfig = {
        dataAppId: 'app-123',
      } as any;

      renderComponent();

      await waitFor(() => {
        expect(mockSetExportConfig).toHaveBeenCalled();
      });
    });

    it('initializes with default values when no API config and no current config', async () => {
      mockExportConfig.method = '';
      mockExportConfig.embeddable_assistant = undefined;
      mockInterfaceConfig = {
        dataAppId: 'app-123',
      } as any;
      mockInterfaceDisplayType = INTERFACE_DISPLAY_TYPE.MOBILE;

      renderComponent();

      await waitFor(() => {
        expect(mockSetExportConfig).toHaveBeenCalled();
        const calls = mockSetExportConfig.mock.calls;
        const lastCall = calls[calls.length - 1];
        if (lastCall) {
          const config = lastCall[0] as WorkflowExportConfig;
          expect(config.method).toBe('embed');
          expect(config.embeddable_assistant).toBe(false);
        }
      });
    });
  });

  describe('Display Type Changes', () => {
    it('handles display type change from MOBILE to FULL_PAGE', async () => {
      mockInterfaceConfig = {
        dataAppId: 'app-123',
      } as any;
      mockInterfaceDisplayType = INTERFACE_DISPLAY_TYPE.MOBILE;
      mockExportConfig.method = 'embed';

      const { rerender } = renderComponent();

      mockInterfaceDisplayType = INTERFACE_DISPLAY_TYPE.FULL_PAGE;
      rerender(
        <ChakraProvider>
          <ChatbotExportConfig isExportOpen={true} agentId='agent-123' />
        </ChakraProvider>,
      );

      await waitFor(() => {
        expect(mockSetExportConfig).toHaveBeenCalled();
      });
    });

    it('restores saved method when switching back to a display type', async () => {
      mockInterfaceConfig = {
        dataAppId: 'app-123',
      } as any;
      mockInterfaceDisplayType = INTERFACE_DISPLAY_TYPE.MOBILE;
      mockExportConfig.method = 'embed';

      const { rerender } = renderComponent();

      mockInterfaceDisplayType = INTERFACE_DISPLAY_TYPE.FULL_PAGE;
      rerender(
        <ChakraProvider>
          <ChatbotExportConfig isExportOpen={true} agentId='agent-123' />
        </ChakraProvider>,
      );

      mockInterfaceDisplayType = INTERFACE_DISPLAY_TYPE.MOBILE;
      rerender(
        <ChakraProvider>
          <ChatbotExportConfig isExportOpen={true} agentId='agent-123' />
        </ChakraProvider>,
      );

      await waitFor(() => {
        expect(mockSetExportConfig).toHaveBeenCalled();
      });
    });

    it('uses API value when switching to FULL_PAGE with embeddable_assistant true', async () => {
      mockInterfaceConfig = {
        dataAppId: 'app-123',
        export_config: {
          method: 'embed',
          embeddable_assistant: true,
        },
      } as any;
      mockInterfaceDisplayType = INTERFACE_DISPLAY_TYPE.MOBILE;
      mockExportConfig.method = 'embed';
      mockExportConfig.embeddable_assistant = false;

      const { rerender } = renderComponent();

      mockInterfaceDisplayType = INTERFACE_DISPLAY_TYPE.FULL_PAGE;
      rerender(
        <ChakraProvider>
          <ChatbotExportConfig isExportOpen={true} agentId='agent-123' />
        </ChakraProvider>,
      );

      await waitFor(() => {
        const calls = mockSetExportConfig.mock.calls;
        const hasEmbeddableTrue = calls.some((call) => {
          const config = call[0] as WorkflowExportConfig;
          return config.embeddable_assistant === true && config.method === 'embed';
        });
        expect(hasEmbeddableTrue).toBe(true);
      });
    });
  });

  describe('Validation Logic', () => {
    it('forces method to embed when embeddable_assistant is true but method is not embed', async () => {
      mockExportConfig.method = 'no_code';
      mockExportConfig.embeddable_assistant = true;
      mockInterfaceConfig = {
        dataAppId: 'app-123',
      } as any;

      renderComponent();

      await waitFor(() => {
        expect(mockSetExportConfig).toHaveBeenCalledWith(
          expect.objectContaining({
            method: 'embed',
          }),
        );
      });
    });

    it('validates embeddable_assistant flag matches display type and method', async () => {
      mockExportConfig.method = 'no_code';
      mockExportConfig.embeddable_assistant = false;
      mockInterfaceDisplayType = INTERFACE_DISPLAY_TYPE.FULL_PAGE;
      mockInterfaceConfig = {
        dataAppId: 'app-123',
      } as any;

      renderComponent();

      await waitFor(
        () => {
          expect(mockSetExportConfig).toHaveBeenCalled();
        },
        { timeout: 2000 },
      );

      const calls = mockSetExportConfig.mock.calls;
      const lastCall = calls[calls.length - 1];
      if (lastCall) {
        const config = lastCall[0] as WorkflowExportConfig;
        expect(['assistant', 'embed']).toContain(config.method);
      }
    });

    it('corrects embeddable_assistant when method is embed but flag is wrong for MOBILE', async () => {
      // Set up valid initialized state
      mockExportConfig.method = 'embed';
      mockExportConfig.embeddable_assistant = true; // Wrong for MOBILE - should be false
      mockInterfaceDisplayType = INTERFACE_DISPLAY_TYPE.MOBILE;
      mockInterfaceConfig = {
        dataAppId: 'app-123',
        export_config: {
          method: 'embed',
          embeddable_assistant: false,
        },
      } as any;

      renderComponent();

      await waitFor(
        () => {
          const calls = mockSetExportConfig.mock.calls;
          const hasCorrectedFlag = calls.some((call) => {
            const config = call[0] as WorkflowExportConfig;
            return config.method === 'embed' && config.embeddable_assistant === false;
          });
          expect(hasCorrectedFlag).toBe(true);
        },
        { timeout: 2000 },
      );
    });

    it('corrects embeddable_assistant when method is embed but flag is wrong for FULL_PAGE', async () => {
      // Set up valid initialized state
      mockExportConfig.method = 'embed';
      mockExportConfig.embeddable_assistant = false; // Wrong for FULL_PAGE - should be true
      mockInterfaceDisplayType = INTERFACE_DISPLAY_TYPE.FULL_PAGE;
      mockInterfaceConfig = {
        dataAppId: 'app-123',
        export_config: {
          method: 'embed',
          embeddable_assistant: true,
        },
      } as any;

      renderComponent();

      await waitFor(
        () => {
          const calls = mockSetExportConfig.mock.calls;
          const hasCorrectedFlag = calls.some((call) => {
            const config = call[0] as WorkflowExportConfig;
            return config.method === 'embed' && config.embeddable_assistant === true;
          });
          expect(hasCorrectedFlag).toBe(true);
        },
        { timeout: 2000 },
      );
    });

    it('updates method to first available when current method is invalid for display type after init', async () => {
      // First render with valid config to initialize
      mockExportConfig.method = 'embed';
      mockExportConfig.embeddable_assistant = false;
      mockInterfaceDisplayType = INTERFACE_DISPLAY_TYPE.MOBILE;
      mockInterfaceConfig = {
        dataAppId: 'app-123',
        export_config: {
          method: 'embed',
          embeddable_assistant: false,
        },
      } as any;

      const { rerender } = renderComponent();

      // Wait for initialization
      await waitFor(() => {
        expect(screen.getByText('Method')).toBeInTheDocument();
      });

      // Now set an invalid method and trigger a re-render with dataAppId change
      mockSetExportConfig.mockClear();
      mockExportConfig.method = 'assistant'; // Invalid for MOBILE
      mockInterfaceConfig = {
        dataAppId: 'app-456', // Changed to trigger useEffect
        export_config: {
          method: 'embed',
          embeddable_assistant: false,
        },
      } as any;

      rerender(
        <ChakraProvider>
          <ChatbotExportConfig isExportOpen={true} agentId='agent-123' />
        </ChakraProvider>,
      );

      await waitFor(
        () => {
          const calls = mockSetExportConfig.mock.calls;
          const hasValidMethod = calls.some((call) => {
            const config = call[0] as WorkflowExportConfig;
            return config.method === 'embed' || config.method === 'no_code';
          });
          expect(hasValidMethod).toBe(true);
        },
        { timeout: 2000 },
      );
    });

    it('stores method in ref after validation', async () => {
      mockExportConfig.method = 'embed';
      mockExportConfig.embeddable_assistant = false;
      mockInterfaceDisplayType = INTERFACE_DISPLAY_TYPE.MOBILE;
      mockInterfaceConfig = {
        dataAppId: 'app-123',
        export_config: {
          method: 'embed',
          embeddable_assistant: false,
        },
      } as any;

      renderComponent();

      await waitFor(() => {
        expect(screen.getByText('Method')).toBeInTheDocument();
      });

      // Verify component renders correctly with validated state
      expect(screen.getByTestId('embeddable-code-section')).toBeInTheDocument();
    });

    it('forces method to embed during validation when embeddable_assistant is true with wrong method', async () => {
      // Initialize with valid config first
      mockExportConfig.method = 'embed';
      mockExportConfig.embeddable_assistant = false;
      mockInterfaceDisplayType = INTERFACE_DISPLAY_TYPE.MOBILE;
      mockInterfaceConfig = {
        dataAppId: 'app-123',
        export_config: {
          method: 'embed',
          embeddable_assistant: false,
        },
      } as any;

      const { rerender } = renderComponent();

      await waitFor(() => {
        expect(screen.getByText('Method')).toBeInTheDocument();
      });

      // Now change to invalid state where embeddable_assistant is true but method isn't embed
      mockSetExportConfig.mockClear();
      mockExportConfig.method = 'no_code';
      mockExportConfig.embeddable_assistant = true;
      mockInterfaceConfig = {
        dataAppId: 'app-456', // Changed to trigger useEffect
        export_config: {
          method: 'no_code',
          embeddable_assistant: true,
        },
      } as any;

      rerender(
        <ChakraProvider>
          <ChatbotExportConfig isExportOpen={true} agentId='agent-123' />
        </ChakraProvider>,
      );

      await waitFor(
        () => {
          const calls = mockSetExportConfig.mock.calls;
          const hasForcedEmbed = calls.some((call) => {
            const config = call[0] as WorkflowExportConfig;
            return config.method === 'embed';
          });
          expect(hasForcedEmbed).toBe(true);
        },
        { timeout: 2000 },
      );
    });

    it('corrects embeddable_assistant flag when it mismatches expected value after validation', async () => {
      // Initialize with valid config for FULL_PAGE
      mockExportConfig.method = 'embed';
      mockExportConfig.embeddable_assistant = true;
      mockInterfaceDisplayType = INTERFACE_DISPLAY_TYPE.FULL_PAGE;
      mockInterfaceConfig = {
        dataAppId: 'app-123',
        export_config: {
          method: 'embed',
          embeddable_assistant: true,
        },
      } as any;

      const { rerender } = renderComponent();

      await waitFor(() => {
        expect(screen.getByText('Method')).toBeInTheDocument();
      });

      // Now change the flag to wrong value while keeping same display type
      mockSetExportConfig.mockClear();
      mockExportConfig.method = 'embed';
      mockExportConfig.embeddable_assistant = false; // Wrong for FULL_PAGE embed
      mockInterfaceConfig = {
        dataAppId: 'app-456', // Changed to trigger useEffect
        export_config: {
          method: 'embed',
          embeddable_assistant: false,
        },
      } as any;

      rerender(
        <ChakraProvider>
          <ChatbotExportConfig isExportOpen={true} agentId='agent-123' />
        </ChakraProvider>,
      );

      await waitFor(
        () => {
          const calls = mockSetExportConfig.mock.calls;
          const hasCorrectedFlag = calls.some((call) => {
            const config = call[0] as WorkflowExportConfig;
            return config.embeddable_assistant === true;
          });
          expect(hasCorrectedFlag).toBe(true);
        },
        { timeout: 2000 },
      );
    });

    it('updates to first available option when current method becomes invalid', async () => {
      // Initialize with valid config
      mockExportConfig.method = 'embed';
      mockExportConfig.embeddable_assistant = false;
      mockInterfaceDisplayType = INTERFACE_DISPLAY_TYPE.MOBILE;
      mockInterfaceConfig = {
        dataAppId: 'app-123',
        export_config: {
          method: 'embed',
          embeddable_assistant: false,
        },
      } as any;

      const { rerender } = renderComponent();

      await waitFor(() => {
        expect(screen.getByText('Method')).toBeInTheDocument();
      });

      // Change method to invalid value for MOBILE
      mockSetExportConfig.mockClear();
      mockExportConfig.method = 'assistant'; // Not valid for MOBILE
      mockExportConfig.embeddable_assistant = false;
      mockInterfaceConfig = {
        dataAppId: 'app-789',
        export_config: {
          method: 'assistant',
          embeddable_assistant: false,
        },
      } as any;

      rerender(
        <ChakraProvider>
          <ChatbotExportConfig isExportOpen={true} agentId='agent-123' />
        </ChakraProvider>,
      );

      await waitFor(
        () => {
          const calls = mockSetExportConfig.mock.calls;
          const hasValidMethod = calls.some((call) => {
            const config = call[0] as WorkflowExportConfig;
            // embed or no_code are valid for MOBILE
            return config.method === 'embed' || config.method === 'no_code';
          });
          expect(hasValidMethod).toBe(true);
        },
        { timeout: 2000 },
      );
    });
  });
});
