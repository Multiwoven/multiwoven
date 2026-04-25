import React from 'react';
import { render, screen, fireEvent, within } from '@testing-library/react';
import { ChakraProvider } from '@chakra-ui/react';
import { expect } from '@jest/globals';
import '@testing-library/jest-dom/jest-globals';
import '@testing-library/jest-dom';
import { WidgetProps } from '@rjsf/utils';
import ToolSelectorWidget, { ToolSelectorFormContext } from '../ToolSelectorWidget';
import { ToolItem, McpToolItem } from '@/enterprise/views/Tools/ToolsList/types';

// Mock react-icons
jest.mock('react-icons/fi');

// Mock chakra-react-select — renders a native <select> for testability.
jest.mock('chakra-react-select', () => ({
  Select: ({ onChange, options, formatOptionLabel }: any) => (
    <>
      <select
        data-testid='connection-select'
        onChange={(e) => {
          const opt = options?.find((o: any) => o.value === e.target.value);
          if (opt) onChange(opt);
        }}
      >
        {options?.map((opt: any) => (
          <option key={opt.value} value={opt.value}>
            {opt.label}
          </option>
        ))}
      </select>
      {options?.map((opt: any) => (
        <div key={`opt-label-${opt.value}`}>
          {formatOptionLabel ? formatOptionLabel(opt) : null}
        </div>
      ))}
    </>
  ),
}));

// Mock BaseModal
jest.mock('@/components/BaseModal/BaseModal', () => ({
  __esModule: true,
  default: ({
    openModal,
    setModalOpen,
    title,
    children,
    footer,
  }: {
    openModal: boolean;
    setModalOpen: (open: boolean) => void;
    title: string;
    children: React.ReactNode;
    footer?: React.ReactNode;
  }) => (
    <div data-testid='base-modal' data-open={openModal}>
      <div data-testid='modal-title'>{title}</div>
      <div data-testid='modal-content'>{children}</div>
      {footer && <div data-testid='modal-footer'>{footer}</div>}
      <button data-testid='close-modal' onClick={() => setModalOpen(false)}>
        Close
      </button>
    </div>
  ),
}));

// Mock ToolSelector components — ToolSelectionView and ActionSelectionView are no longer used.
jest.mock('../ToolSelector', () => ({
  __esModule: true,
  AddToolButton: ({ onClick }: { onClick: () => void }) => (
    <button data-testid='add-tool-button' onClick={onClick}>
      Add Tool
    </button>
  ),
  ConnectedToolView: ({
    currentTool,
    tools,
    onEditTool,
  }: {
    currentTool: ToolItem | null;
    tools: string[];
    onEditTool: () => void;
  }) => (
    <div data-testid='connected-tool-view'>
      <div data-testid='tool-name'>{currentTool?.attributes.name || 'No tool'}</div>
      <div data-testid='tools-count'>{tools.length}</div>
      <button data-testid='edit-tool' onClick={onEditTool}>
        Edit
      </button>
    </div>
  ),
  ToolIcon: () => <span data-testid='tool-icon' />,
}));

// Mock ToolTip — just renders children
jest.mock('@/components/ToolTip/ToolTip', () => ({
  __esModule: true,
  default: ({ children }: any) => <>{children}</>,
}));

// Mock Loader
jest.mock('@/components/Loader', () => ({
  __esModule: true,
  default: () => <div data-testid='loader' />,
}));

// Mock useToolQueries
const mockUseGetTools = jest.fn();
const mockUseGetMcpToolsList = jest.fn();

jest.mock('@/enterprise/hooks/queries/useToolQueries', () => ({
  __esModule: true,
  default: () => ({
    useGetTools: mockUseGetTools,
    useGetMcpToolsList: mockUseGetMcpToolsList,
  }),
}));

const renderWithChakra = (ui: React.ReactElement) => render(<ChakraProvider>{ui}</ChakraProvider>);

const createMockTool = (id: string, name: string, toolType: string = 'mcp'): ToolItem => ({
  id,
  type: 'tool',
  attributes: {
    name,
    tool_type: toolType,
    enabled: true,
    updated_at: '2024-01-01T00:00:00Z',
    created_at: '2024-01-01T00:00:00Z',
    settings: {
      mcp: {
        url: 'http://example.com',
        transport: 'http',
        auth_type: 'none',
      },
    },
    metadata: {
      icon: '/icon.svg',
    },
  },
});

const createMockAction = (name: string): McpToolItem => ({
  name,
  description: `Description for ${name}`,
  input_schema: { type: 'object' },
});

describe('ToolSelectorWidget', () => {
  const createBaseProps = (
    overrides: Partial<WidgetProps & { formContext?: ToolSelectorFormContext }> = {},
  ) => ({
    id: 'tool-selector',
    name: 'tool_selector',
    value: '',
    schema: {},
    uiSchema: {},
    formData: {},
    formContext: {
      currentTools: [],
      onToolSelectorChange: jest.fn(),
    },
    registry: {} as any,
    onChange: jest.fn(),
    onBlur: jest.fn(),
    onFocus: jest.fn(),
    rawErrors: [],
    ...overrides,
  });

  beforeEach(() => {
    jest.clearAllMocks();
    mockUseGetTools.mockReturnValue({ data: { data: [] }, isLoading: false });
    // Default: no tools actions — prevents the auto-init useEffect from firing on render.
    mockUseGetMcpToolsList.mockReturnValue({ data: { tools: [] }, isLoading: false });
  });

  // Opens the modal then selects a connection via the native select mock.
  const openModalAndSelectTool = (toolId: string) => {
    fireEvent.click(screen.getByTestId('add-tool-button'));
    fireEvent.change(screen.getByTestId('connection-select'), { target: { value: toolId } });
  };

  // ─── Initial render ────────────────────────────────────────────────────────

  describe('Initial render', () => {
    it('renders AddToolButton when value is empty', () => {
      renderWithChakra(<ToolSelectorWidget {...createBaseProps({ value: '' })} />);
      expect(screen.getByTestId('add-tool-button')).toBeInTheDocument();
    });

    it('renders ConnectedToolView when value is a tool id', () => {
      const tool = createMockTool('tool-1', 'Test Tool');
      mockUseGetTools.mockReturnValue({ data: { data: [tool] }, isLoading: false });

      renderWithChakra(<ToolSelectorWidget {...createBaseProps({ value: 'tool-1' })} />);
      expect(screen.getByTestId('connected-tool-view')).toBeInTheDocument();
    });

    it('shows the correct tool name in ConnectedToolView', () => {
      const tool = createMockTool('tool-1', 'My Test Tool');
      mockUseGetTools.mockReturnValue({ data: { data: [tool] }, isLoading: false });

      renderWithChakra(<ToolSelectorWidget {...createBaseProps({ value: 'tool-1' })} />);
      expect(screen.getByTestId('tool-name')).toHaveTextContent('My Test Tool');
    });

    it('shows the correct tools-count from currentTools', () => {
      const tool = createMockTool('tool-1', 'Test Tool');
      mockUseGetTools.mockReturnValue({ data: { data: [tool] }, isLoading: false });

      renderWithChakra(
        <ToolSelectorWidget
          {...createBaseProps({
            value: 'tool-1',
            formContext: {
              currentTools: ['action1', 'action2'],
              onToolSelectorChange: jest.fn(),
            },
          })}
        />,
      );
      expect(screen.getByTestId('tools-count')).toHaveTextContent('2');
    });

    it('handles non-string value gracefully — falls back to empty string, shows AddToolButton', () => {
      renderWithChakra(<ToolSelectorWidget {...createBaseProps({ value: 123 as any })} />);
      expect(screen.getByTestId('add-tool-button')).toBeInTheDocument();
    });

    it('handles non-existent toolId — shows ConnectedToolView with "No tool"', () => {
      mockUseGetTools.mockReturnValue({ data: { data: [] }, isLoading: false });

      renderWithChakra(
        <ToolSelectorWidget
          {...createBaseProps({
            value: 'non-existent-tool',
            formContext: { currentTools: [], onToolSelectorChange: jest.fn() },
          })}
        />,
      );
      expect(screen.getByTestId('connected-tool-view')).toBeInTheDocument();
      expect(screen.getByTestId('tool-name')).toHaveTextContent('No tool');
    });

    it('handles undefined formContext without crashing', () => {
      const tool = createMockTool('tool-1', 'Test Tool');
      mockUseGetTools.mockReturnValue({ data: { data: [tool] }, isLoading: false });

      renderWithChakra(
        <ToolSelectorWidget {...createBaseProps({ value: 'tool-1', formContext: undefined })} />,
      );
      expect(screen.getByTestId('connected-tool-view')).toBeInTheDocument();
    });
  });

  // ─── Modal open / close ───────────────────────────────────────────────────

  describe('Modal open / close', () => {
    it('opens modal with "Add Tool" title when AddToolButton is clicked', () => {
      renderWithChakra(<ToolSelectorWidget {...createBaseProps()} />);
      fireEvent.click(screen.getByTestId('add-tool-button'));

      expect(screen.getByTestId('base-modal')).toHaveAttribute('data-open', 'true');
      expect(screen.getByTestId('modal-title')).toHaveTextContent('Add Tool');
    });

    it('opens modal when edit button is clicked', () => {
      const tool = createMockTool('tool-1', 'Test Tool');
      mockUseGetTools.mockReturnValue({ data: { data: [tool] }, isLoading: false });

      renderWithChakra(
        <ToolSelectorWidget
          {...createBaseProps({
            value: 'tool-1',
            formContext: { currentTools: ['action1'], onToolSelectorChange: jest.fn() },
          })}
        />,
      );
      fireEvent.click(screen.getByTestId('edit-tool'));
      expect(screen.getByTestId('base-modal')).toHaveAttribute('data-open', 'true');
    });

    it('closes modal when Cancel button is clicked', () => {
      renderWithChakra(<ToolSelectorWidget {...createBaseProps()} />);
      fireEvent.click(screen.getByTestId('add-tool-button'));
      fireEvent.click(screen.getByText('Cancel'));

      expect(screen.getByTestId('base-modal')).toHaveAttribute('data-open', 'false');
    });

    it('closes modal when X (close-modal) button is clicked', () => {
      renderWithChakra(<ToolSelectorWidget {...createBaseProps()} />);
      fireEvent.click(screen.getByTestId('add-tool-button'));
      fireEvent.click(screen.getByTestId('close-modal'));

      expect(screen.getByTestId('base-modal')).toHaveAttribute('data-open', 'false');
    });

    it('resets state after closing: Tools section does not appear on reopen without new selection', () => {
      const tool = createMockTool('tool-1', 'Test Tool');
      mockUseGetTools.mockReturnValue({ data: { data: [tool] }, isLoading: false });

      renderWithChakra(<ToolSelectorWidget {...createBaseProps()} />);

      // Select a connection so the Tools section appears
      openModalAndSelectTool('tool-1');
      expect(screen.getByText('Select All')).toBeInTheDocument();

      // Close the modal — state should be reset
      fireEvent.click(screen.getByText('Cancel'));

      // Reopen without selecting a connection
      fireEvent.click(screen.getByTestId('add-tool-button'));
      expect(screen.queryByText('Select All')).not.toBeInTheDocument();
    });
  });

  // ─── Connection dropdown ──────────────────────────────────────────────────

  describe('Connection dropdown', () => {
    it('renders the connection select inside the modal', () => {
      renderWithChakra(<ToolSelectorWidget {...createBaseProps()} />);
      fireEvent.click(screen.getByTestId('add-tool-button'));

      expect(screen.getByTestId('connection-select')).toBeInTheDocument();
      expect(screen.getByTestId('workflow-tool-connection-select')).toBeInTheDocument();
      expect(screen.getByTestId('workflow-tool-modal-cancel')).toBeInTheDocument();
      expect(screen.getByTestId('workflow-tool-modal-connect')).toBeInTheDocument();
    });

    it('renders each connection option with icon + name (formatOptionLabel path)', () => {
      const tool = createMockTool('tool-1', 'MCP Server Alpha');
      mockUseGetTools.mockReturnValue({ data: { data: [tool] }, isLoading: false });

      renderWithChakra(<ToolSelectorWidget {...createBaseProps()} />);
      fireEvent.click(screen.getByTestId('add-tool-button'));

      const row = screen.getByTestId('workflow-tool-connection-option-tool-1');
      expect(row).toBeInTheDocument();
      expect(row).toHaveTextContent('MCP Server Alpha');
      expect(within(row).getByTestId('tool-icon')).toBeInTheDocument();
    });

    it('hides the Tools section before a connection is selected', () => {
      renderWithChakra(<ToolSelectorWidget {...createBaseProps()} />);
      fireEvent.click(screen.getByTestId('add-tool-button'));

      expect(screen.queryByText('Select All')).not.toBeInTheDocument();
    });

    it('shows the Tools section after a connection is selected', () => {
      const tool = createMockTool('tool-1', 'Test Tool');
      mockUseGetTools.mockReturnValue({ data: { data: [tool] }, isLoading: false });

      renderWithChakra(<ToolSelectorWidget {...createBaseProps()} />);
      openModalAndSelectTool('tool-1');

      expect(screen.getByText('Select All')).toBeInTheDocument();
    });
  });

  // ─── Tools section loading ────────────────────────────────────────────────

  describe('Tools section loading', () => {
    it('shows a loader and no switches when isLoadingActions is true', () => {
      const tool = createMockTool('tool-1', 'Test Tool');
      mockUseGetTools.mockReturnValue({ data: { data: [tool] }, isLoading: false });
      mockUseGetMcpToolsList.mockReturnValue({ data: undefined, isLoading: true });

      const { container } = renderWithChakra(<ToolSelectorWidget {...createBaseProps()} />);
      openModalAndSelectTool('tool-1');

      expect(screen.getByTestId('loader')).toBeInTheDocument();
      // No checkbox inputs (switch inputs) should be rendered while loading
      expect(container.querySelectorAll('input[type="checkbox"]')).toHaveLength(0);
    });
  });

  // ─── Select All / Deselect All ────────────────────────────────────────────
  //
  // Auto-init behaviour: when a tool is selected, mcpToolsResponse changes from
  // undefined → { tools: [...] }, triggering the useEffect which sets all actions
  // to true. Therefore immediately after selecting a connection, all switches are
  // CHECKED (allSelected=true), Select All is DISABLED, Deselect All is ENABLED.

  describe('Select All / Deselect All', () => {
    const setupWithActions = () => {
      const tool = createMockTool('tool-1', 'Test Tool');
      const actions = [createMockAction('action1'), createMockAction('action2')];
      mockUseGetTools.mockReturnValue({ data: { data: [tool] }, isLoading: false });
      // Stable object references are critical: mcpToolsResponse must change from
      // noDataResult → withDataResult exactly once (when tool is selected), so the
      // auto-init useEffect fires exactly once and not again on subsequent renders.
      const noDataResult = { data: undefined, isLoading: false };
      const withDataResult = { data: { tools: actions }, isLoading: false };
      mockUseGetMcpToolsList.mockImplementation((toolId: string, shouldFetch: boolean) => {
        if (!toolId || !shouldFetch) return noDataResult;
        return withDataResult;
      });
      return { tool, actions };
    };

    it('shows Select All and Deselect All buttons once a connection is selected', () => {
      setupWithActions();
      renderWithChakra(<ToolSelectorWidget {...createBaseProps()} />);
      openModalAndSelectTool('tool-1');

      expect(screen.getByText('Select All')).toBeInTheDocument();
      expect(screen.getByText('Deselect All')).toBeInTheDocument();
    });

    it('all actions are auto-selected right after tool selection — Select All disabled, Deselect All enabled', () => {
      setupWithActions();
      renderWithChakra(<ToolSelectorWidget {...createBaseProps()} />);
      openModalAndSelectTool('tool-1');

      expect(screen.getByText('Select All')).toBeDisabled();
      expect(screen.getByText('Deselect All')).not.toBeDisabled();
    });

    it('clicking Deselect All then Select All re-checks all switches, disables Select All, enables Deselect All', () => {
      setupWithActions();
      renderWithChakra(<ToolSelectorWidget {...createBaseProps()} />);
      openModalAndSelectTool('tool-1');
      // Auto-init: all selected. Deselect All first, then Select All.
      fireEvent.click(screen.getByText('Deselect All'));
      fireEvent.click(screen.getByText('Select All'));

      // Verify state via button enabled/disabled (allSelected = true)
      expect(screen.getByText('Select All')).toBeDisabled();
      expect(screen.getByText('Deselect All')).not.toBeDisabled();
      // Connect should be enabled because selectedActionsCount > 0
      expect(screen.getByText('Connect')).not.toBeDisabled();
    });

    it('clicking Deselect All unchecks all switches, re-enables Select All, disables Deselect All', () => {
      setupWithActions();
      renderWithChakra(<ToolSelectorWidget {...createBaseProps()} />);
      openModalAndSelectTool('tool-1');
      // Auto-init: all selected. Go straight to Deselect All.
      fireEvent.click(screen.getByText('Deselect All'));

      // Verify state via button enabled/disabled (nothing selected)
      expect(screen.getByText('Select All')).not.toBeDisabled();
      expect(screen.getByText('Deselect All')).toBeDisabled();
      // Connect should be disabled because selectedActionsCount === 0
      expect(screen.getByText('Connect')).toBeDisabled();
    });

    it('toggling one switch off after Select All puts component in someSelected state — both buttons enabled', () => {
      // Chakra Switch renders <input type="checkbox"> without role attr; query by type
      setupWithActions();
      const { container } = renderWithChakra(<ToolSelectorWidget {...createBaseProps()} />);
      openModalAndSelectTool('tool-1');
      // Auto-init: all selected. Toggle directly from that state.

      // Toggle the first switch off → partial selection (someSelected=true)
      const checkboxes = container.querySelectorAll('input[type="checkbox"]');
      fireEvent.click(checkboxes[0]);

      // someSelected=true → both buttons enabled
      expect(screen.getByText('Select All')).not.toBeDisabled();
      expect(screen.getByText('Deselect All')).not.toBeDisabled();
    });

    it('clicking Deselect All after partial selection disables Deselect All and Connect', () => {
      setupWithActions();
      const { container } = renderWithChakra(<ToolSelectorWidget {...createBaseProps()} />);
      openModalAndSelectTool('tool-1');
      // Auto-init: all selected. Reach partial selection by toggling one switch off.

      // Reach partial selection by toggling one switch off
      const checkboxes = container.querySelectorAll('input[type="checkbox"]');
      fireEvent.click(checkboxes[0]);
      fireEvent.click(screen.getByText('Deselect All'));

      // After Deselect All: nothing selected → Deselect All disabled, Connect disabled
      expect(screen.getByText('Deselect All')).toBeDisabled();
      expect(screen.getByText('Connect')).toBeDisabled();
    });
  });

  // ─── Connect button ───────────────────────────────────────────────────────

  describe('Connect button', () => {
    it('is disabled when no connection has been selected', () => {
      renderWithChakra(<ToolSelectorWidget {...createBaseProps()} />);
      fireEvent.click(screen.getByTestId('add-tool-button'));

      expect(screen.getByText('Connect')).toBeDisabled();
    });

    it('is disabled while isLoadingActions is true', () => {
      const tool = createMockTool('tool-1', 'Test Tool');
      mockUseGetTools.mockReturnValue({ data: { data: [tool] }, isLoading: false });
      mockUseGetMcpToolsList.mockReturnValue({ data: undefined, isLoading: true });

      renderWithChakra(<ToolSelectorWidget {...createBaseProps()} />);
      openModalAndSelectTool('tool-1');

      expect(screen.getByText('Connect')).toBeDisabled();
    });

    it('is enabled immediately after tool selection due to auto-init', () => {
      const tool = createMockTool('tool-1', 'Test Tool');
      const actions = [createMockAction('action1')];
      mockUseGetTools.mockReturnValue({ data: { data: [tool] }, isLoading: false });
      const noDataResult = { data: undefined, isLoading: false };
      const withDataResult = { data: { tools: actions }, isLoading: false };
      mockUseGetMcpToolsList.mockImplementation((toolId: string, shouldFetch: boolean) => {
        if (!toolId || !shouldFetch) return noDataResult;
        return withDataResult;
      });

      renderWithChakra(<ToolSelectorWidget {...createBaseProps()} />);
      openModalAndSelectTool('tool-1');

      expect(screen.getByText('Connect')).not.toBeDisabled();
    });

    it('is enabled after auto-init selects all actions on tool selection', () => {
      const tool = createMockTool('tool-1', 'Test Tool');
      const actions = [createMockAction('action1')];
      mockUseGetTools.mockReturnValue({ data: { data: [tool] }, isLoading: false });
      const noDataResult = { data: undefined, isLoading: false };
      const withDataResult = { data: { tools: actions }, isLoading: false };
      mockUseGetMcpToolsList.mockImplementation((toolId: string, shouldFetch: boolean) => {
        if (!toolId || !shouldFetch) return noDataResult;
        return withDataResult;
      });

      renderWithChakra(<ToolSelectorWidget {...createBaseProps()} />);
      openModalAndSelectTool('tool-1');

      // Auto-init already enables Connect; no need to click Select All
      expect(screen.getByText('Connect')).not.toBeDisabled();
    });

    it('calls onToolSelectorChange with correct args and closes modal', () => {
      const tool = createMockTool('tool-1', 'Test Tool');
      const actions = [createMockAction('action1'), createMockAction('action2')];
      const onToolSelectorChange = jest.fn();
      mockUseGetTools.mockReturnValue({ data: { data: [tool] }, isLoading: false });
      const noDataResult = { data: undefined, isLoading: false };
      const withDataResult = { data: { tools: actions }, isLoading: false };
      mockUseGetMcpToolsList.mockImplementation((toolId: string, shouldFetch: boolean) => {
        if (!toolId || !shouldFetch) return noDataResult;
        return withDataResult;
      });

      renderWithChakra(
        <ToolSelectorWidget
          {...createBaseProps({
            formContext: { currentTools: [], onToolSelectorChange },
          })}
        />,
      );
      openModalAndSelectTool('tool-1');
      // Auto-init already selects all actions; Connect is immediately enabled.
      fireEvent.click(screen.getByText('Connect'));

      expect(onToolSelectorChange).toHaveBeenCalledWith('tool-1', ['action1', 'action2']);
      expect(screen.getByTestId('base-modal')).toHaveAttribute('data-open', 'false');
    });
  });

  // ─── Edit mode ────────────────────────────────────────────────────────────

  describe('Edit mode', () => {
    it('pre-checks actions listed in currentTools when edit button is clicked', () => {
      // currentTools=['action1','action2'] out of [action1,action2,action3]
      // → switches 0,1 checked; switch 2 unchecked; someSelected=true
      const tool = createMockTool('tool-1', 'Test Tool');
      const actions = [
        createMockAction('action1'),
        createMockAction('action2'),
        createMockAction('action3'),
      ];
      mockUseGetTools.mockReturnValue({ data: { data: [tool] }, isLoading: false });
      const noDataResult = { data: undefined, isLoading: false };
      const withDataResult = { data: { tools: actions }, isLoading: false };
      mockUseGetMcpToolsList.mockImplementation((toolId: string, shouldFetch: boolean) => {
        if (!toolId || !shouldFetch) return noDataResult;
        return withDataResult;
      });

      const { container } = renderWithChakra(
        <ToolSelectorWidget
          {...createBaseProps({
            value: 'tool-1',
            formContext: {
              currentTools: ['action1', 'action2'],
              onToolSelectorChange: jest.fn(),
            },
          })}
        />,
      );
      fireEvent.click(screen.getByTestId('edit-tool'));

      // Verify pre-checked state via checkbox inputs and button states
      const checkboxes = container.querySelectorAll('input[type="checkbox"]');
      expect(checkboxes[0]).toBeChecked(); // action1 ∈ currentTools
      expect(checkboxes[1]).toBeChecked(); // action2 ∈ currentTools
      expect(checkboxes[2]).not.toBeChecked(); // action3 ∉ currentTools

      // someSelected=true → Connect enabled, both bulk buttons enabled
      expect(screen.getByText('Connect')).not.toBeDisabled();
      expect(screen.getByText('Select All')).not.toBeDisabled();
      expect(screen.getByText('Deselect All')).not.toBeDisabled();
    });

    it('does nothing and keeps modal closed when currentTool is null', () => {
      mockUseGetTools.mockReturnValue({ data: { data: [] }, isLoading: false });

      renderWithChakra(
        <ToolSelectorWidget
          {...createBaseProps({
            value: 'non-existent-tool',
            formContext: { currentTools: ['action1'], onToolSelectorChange: jest.fn() },
          })}
        />,
      );
      fireEvent.click(screen.getByTestId('edit-tool'));

      expect(screen.getByTestId('base-modal')).toHaveAttribute('data-open', 'false');
    });
  });
});
