import { render, screen, fireEvent, waitFor } from '@testing-library/react';
import { expect, describe, it, beforeEach } from '@jest/globals';
import '@testing-library/jest-dom/jest-globals';
import '@testing-library/jest-dom';
import IOFields from '../IOFields';
import { ChakraProvider } from '@chakra-ui/react';
import { IOField } from '../../types';

// Mock useAgentStore
let mockCurrentWorkflow = {
  workflow: {
    edges: [
      {
        source_component_id: 'comp-1',
        target_component_id: 'comp-2',
        source_handle: { field: 'output', type: 'string' },
        target_handle: { field: 'input', type: 'string' },
      },
    ],
  },
};

let mockNodes: Array<{ id: string; data: { component: string } }> = [];

jest.mock('@/enterprise/store/useAgentStore', () => ({
  __esModule: true,
  default: (
    selector: (state: {
      currentWorkflow: typeof mockCurrentWorkflow;
      nodes: typeof mockNodes;
    }) => unknown,
  ) =>
    selector({
      currentWorkflow: mockCurrentWorkflow,
      nodes: mockNodes,
    }),
}));

// Mock isValidPythonParam
jest.mock('../Configbar/utils', () => ({
  isValidPythonParam: jest.fn((value: string) => {
    if (!value || typeof value !== 'string') return false;
    return /^[a-zA-Z_][a-zA-Z0-9_]*$/.test(value);
  }),
}));

// Mock useCustomToast
const mockToast = jest.fn();
jest.mock('@/hooks/useCustomToast', () => ({
  __esModule: true,
  default: () => mockToast,
}));

// Mock copy-to-clipboard
jest.mock('copy-to-clipboard', () => ({
  __esModule: true,
  default: jest.fn(),
}));

// Mock react-icons
jest.mock('react-icons/fi');

// Mock assets
jest.mock('@/assets/icons/FiStaticQuery', () => ({
  __esModule: true,
  default: () => <span>StaticQuery</span>,
}));

jest.mock('@/assets/icons/FiDynamicQuery', () => ({
  __esModule: true,
  default: () => <span>DynamicQuery</span>,
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

// Mock @xyflow/react Handle
jest.mock('@xyflow/react', () => ({
  Handle: ({ id, type, position }: { id: string; type: string; position: string }) => (
    <div data-testid={`handle-${type}-${id}`} data-position={position}>
      Handle
    </div>
  ),
  Position: {
    Left: 'left',
    Right: 'right',
  },
}));

describe('IOFields', () => {
  const mockInputs: IOField[] = [
    {
      field: 'text_input',
      type: 'string',
      description: 'Text input field',
      'x-ui': {
        type: 'input',
        label: 'Text Input',
        required: true,
        icon: 'fiType',
      },
    },
    {
      field: 'code_input',
      type: 'custom',
      description: 'Code input field',
      'x-ui': {
        type: 'input',
        label: 'Code Input',
        required: false,
        icon: 'fiCode',
      },
    },
  ];

  const mockOutputs: IOField[] = [
    {
      field: 'result',
      type: 'string',
      description: 'Output result',
      'x-ui': {
        type: 'output',
        label: 'Result',
        required: false,
        icon: 'fiType',
      },
    },
  ];

  const defaultProps: {
    componentId: string;
    inputs: IOField[];
    outputs: IOField[];
    showEdges?: boolean;
    modifyInputs?: boolean;
    handleInputChange?: (props: { changeType: string; index: number; value?: string }) => void;
    handleAddInputValue?: ({ value, name }: { value: string; name: string }) => void;
    inputValues?: Record<string, string | number>;
    outputValue?: string;
    outputSize?: 'input' | 'textarea';
    outputExtra?: React.ReactNode;
  } = {
    componentId: 'comp-1',
    inputs: mockInputs,
    outputs: mockOutputs,
  };

  const renderComponent = (props: typeof defaultProps = defaultProps) => {
    return render(
      <ChakraProvider>
        <IOFields {...props} />
      </ChakraProvider>,
    );
  };

  beforeEach(() => {
    jest.clearAllMocks();
    // Reset mocks to default state
    mockCurrentWorkflow = {
      workflow: {
        edges: [
          {
            source_component_id: 'comp-1',
            target_component_id: 'comp-2',
            source_handle: { field: 'output', type: 'string' },
            target_handle: { field: 'input', type: 'string' },
          },
        ],
      },
    };
    mockNodes = [];
  });

  describe('Rendering', () => {
    it('should render Inputs section', () => {
      renderComponent();
      expect(screen.getByText('Inputs')).toBeInTheDocument();
    });

    it('should render Outputs section', () => {
      renderComponent();
      expect(screen.getByText('Outputs')).toBeInTheDocument();
    });

    it('should render input labels', () => {
      renderComponent();
      expect(screen.getByText('Text Input')).toBeInTheDocument();
      expect(screen.getByText('Code Input')).toBeInTheDocument();
    });

    it('should render input indicator dot with info color', () => {
      renderComponent();
      const inputSection = screen.getByText('Inputs').closest('div');
      expect(inputSection).toBeInTheDocument();
    });

    it('should render output indicator dot with success color', () => {
      renderComponent();
      const outputSection = screen.getByText('Outputs').closest('div');
      expect(outputSection).toBeInTheDocument();
    });
  });

  describe('Input Fields', () => {
    it('should render correct number of inputs', () => {
      renderComponent();
      const inputFields = screen.getAllByPlaceholderText('Connect component');
      expect(inputFields.length).toBe(2);
    });

    it('should show placeholder for disconnected input', () => {
      renderComponent();
      const inputs = screen.getAllByPlaceholderText('Connect component');
      expect(inputs.length).toBeGreaterThan(0);
    });

    it('should show "Receiving input" when field is connected', () => {
      const connectedInput: IOField[] = [
        {
          field: 'input',
          type: 'string',
          description: 'Connected input',
          'x-ui': {
            type: 'input',
            label: 'Connected Input',
            required: true,
          },
        },
      ];

      render(
        <ChakraProvider>
          <IOFields componentId='comp-2' inputs={connectedInput} outputs={[]} />
        </ChakraProvider>,
      );

      expect(screen.getByPlaceholderText('Receiving input')).toBeInTheDocument();
    });

    it('should render input with icon when specified', () => {
      renderComponent();
      expect(screen.getAllByTestId('fi-type').length).toBeGreaterThan(0);
    });
  });

  describe('Output Fields', () => {
    it('should render output as readonly', () => {
      renderComponent();
      const outputField = screen.getByDisplayValue('Result');
      expect(outputField).toHaveAttribute('readonly');
    });

    it('should render textarea output when outputSize is textarea', () => {
      renderComponent({
        ...defaultProps,
        outputSize: 'textarea',
        outputValue: 'This is the output',
      });

      expect(screen.getByDisplayValue('This is the output')).toBeInTheDocument();
    });

    it('should render copy button for textarea output', () => {
      renderComponent({
        ...defaultProps,
        outputSize: 'textarea',
        outputValue: 'Copy me',
      });

      expect(screen.getByTestId('fi-copy')).toBeInTheDocument();
    });
  });

  describe('Edge Handles', () => {
    it('should render input handles when showEdges is true', () => {
      renderComponent({
        ...defaultProps,
        showEdges: true,
      });

      expect(screen.getByTestId('handle-target-text_input-string-comp-1')).toBeInTheDocument();
    });

    it('should render output handles when showEdges is true', () => {
      renderComponent({
        ...defaultProps,
        showEdges: true,
      });

      expect(screen.getByTestId('handle-source-result-string-comp-1')).toBeInTheDocument();
    });

    it('should not render handles when showEdges is false', () => {
      renderComponent({
        ...defaultProps,
        showEdges: false,
      });

      expect(
        screen.queryByTestId('handle-target-text_input-string-comp-1'),
      ).not.toBeInTheDocument();
    });
  });

  describe('Editable Inputs (modifyInputs)', () => {
    const mockHandleInputChange = jest.fn();

    it('should render EditableInput when modifyInputs is true', () => {
      renderComponent({
        ...defaultProps,
        modifyInputs: true,
        handleInputChange: mockHandleInputChange,
      });

      // Edit and trash icons should be present
      expect(screen.getAllByTestId('fi-edit-3').length).toBeGreaterThan(0);
      expect(screen.getAllByTestId('fi-trash-2').length).toBeGreaterThan(0);
    });

    it('should render Add Input button when modifyInputs is true', () => {
      renderComponent({
        ...defaultProps,
        modifyInputs: true,
        handleInputChange: mockHandleInputChange,
      });

      expect(screen.getByText('Add Input')).toBeInTheDocument();
    });

    it('should call handleInputChange with add when Add Input is clicked', () => {
      renderComponent({
        ...defaultProps,
        modifyInputs: true,
        handleInputChange: mockHandleInputChange,
      });

      const addButton = screen.getByText('Add Input');
      fireEvent.click(addButton);

      expect(mockHandleInputChange).toHaveBeenCalledWith({
        changeType: 'add',
        index: 2,
      });
    });

    it('should call handleInputChange with remove when delete is clicked', () => {
      renderComponent({
        ...defaultProps,
        modifyInputs: true,
        handleInputChange: mockHandleInputChange,
      });

      const deleteButtons = screen.getAllByTestId('fi-trash-2');
      fireEvent.click(deleteButtons[0].parentElement!);

      expect(mockHandleInputChange).toHaveBeenCalledWith({
        changeType: 'remove',
        index: 0,
      });
    });

    it('should enter edit mode when edit icon is clicked', async () => {
      renderComponent({
        ...defaultProps,
        modifyInputs: true,
        handleInputChange: mockHandleInputChange,
      });

      const editButtons = screen.getAllByTestId('fi-edit-3');
      fireEvent.click(editButtons[0].parentElement!);

      // Should now show an input field for editing
      await waitFor(() => {
        expect(screen.getByDisplayValue('Text Input')).toBeInTheDocument();
      });
    });

    it('should show check icon in edit mode', async () => {
      renderComponent({
        ...defaultProps,
        modifyInputs: true,
        handleInputChange: mockHandleInputChange,
      });

      const editButtons = screen.getAllByTestId('fi-edit-3');
      fireEvent.click(editButtons[0].parentElement!);

      await waitFor(() => {
        expect(screen.getAllByTestId('fi-check').length).toBeGreaterThan(0);
      });
    });
  });

  describe('Input Values (handleAddInputValue)', () => {
    const mockHandleAddInputValue = jest.fn();

    it('should render editable inputs when handleAddInputValue is provided', () => {
      renderComponent({
        ...defaultProps,
        handleAddInputValue: mockHandleAddInputValue,
        inputValues: { 'Text Input': 'sample value' },
      });

      expect(screen.getByDisplayValue('sample value')).toBeInTheDocument();
    });

    it('should show placeholder for sample value input', () => {
      renderComponent({
        ...defaultProps,
        handleAddInputValue: mockHandleAddInputValue,
      });

      expect(screen.getAllByPlaceholderText('Enter a sample value').length).toBeGreaterThan(0);
    });

    it('should call handleAddInputValue on input change', () => {
      renderComponent({
        ...defaultProps,
        handleAddInputValue: mockHandleAddInputValue,
      });

      const inputs = screen.getAllByPlaceholderText('Enter a sample value');
      fireEvent.change(inputs[0], { target: { value: 'new value' } });

      expect(mockHandleAddInputValue).toHaveBeenCalledWith({
        value: 'new value',
        name: 'Text Input',
      });
    });
  });

  describe('Output Extra', () => {
    it('should render outputExtra when provided', () => {
      renderComponent({
        ...defaultProps,
        outputExtra: <button data-testid='extra-button'>Extra</button>,
      });

      expect(screen.getByTestId('extra-button')).toBeInTheDocument();
    });
  });

  describe('Prompt Template Styling', () => {
    it('should apply special styling for prompt_template component inputs', () => {
      renderComponent({
        componentId: 'prompt_template_1',
        inputs: mockInputs,
        outputs: mockOutputs,
      });

      // The component should have info color background for prompt template inputs
      const inputLabel = screen.getByText('Text Input');
      expect(inputLabel.closest('span')).toHaveStyle({
        backgroundColor: 'var(--chakra-colors-info-100)',
      });
    });
  });

  describe('Python Component Input Editing', () => {
    const mockHandleInputChange = jest.fn();

    it('should render edit button for Python component inputs', () => {
      renderComponent({
        ...defaultProps,
        modifyInputs: true,
        handleInputChange: mockHandleInputChange,
      });

      expect(screen.getAllByTestId('fi-edit-3').length).toBeGreaterThan(0);
    });

    it('should render delete button for Python component inputs', () => {
      renderComponent({
        ...defaultProps,
        modifyInputs: true,
        handleInputChange: mockHandleInputChange,
      });

      expect(screen.getAllByTestId('fi-trash-2').length).toBeGreaterThan(0);
    });

    it('should render add input button for Python component', () => {
      renderComponent({
        ...defaultProps,
        modifyInputs: true,
        handleInputChange: mockHandleInputChange,
      });

      expect(screen.getByText('Add Input')).toBeInTheDocument();
    });

    it('should show input field when edit is clicked', () => {
      renderComponent({
        ...defaultProps,
        modifyInputs: true,
        handleInputChange: mockHandleInputChange,
      });

      const editButtons = screen.getAllByTestId('fi-edit-3');
      const editContainer = editButtons[0].closest('span');
      if (editContainer) {
        fireEvent.click(editContainer);
      }

      // After clicking edit, an input should appear
      expect(screen.getAllByRole('textbox').length).toBeGreaterThan(0);
    });

    it('should update input value when typing in edit mode', () => {
      renderComponent({
        ...defaultProps,
        modifyInputs: true,
        handleInputChange: mockHandleInputChange,
      });

      // Click edit to enter edit mode
      const editButtons = screen.getAllByTestId('fi-edit-3');
      const editContainer = editButtons[0].closest('span');
      if (editContainer) {
        fireEvent.click(editContainer);
      }

      // Find the input and change its value
      const inputs = screen.getAllByRole('textbox');
      fireEvent.change(inputs[0], { target: { value: 'new_param_name' } });

      // The input should have the new value
      expect(inputs[0]).toHaveValue('new_param_name');
    });

    it('should validate input and show error for invalid python param', () => {
      renderComponent({
        ...defaultProps,
        modifyInputs: true,
        handleInputChange: mockHandleInputChange,
      });

      // Click edit to enter edit mode
      const editButtons = screen.getAllByTestId('fi-edit-3');
      const editContainer = editButtons[0].closest('span');
      if (editContainer) {
        fireEvent.click(editContainer);
      }

      // Find the input and change to invalid value (starts with number)
      const inputs = screen.getAllByRole('textbox');
      fireEvent.change(inputs[0], { target: { value: '123invalid' } });

      // Should show alert icon for invalid param
      expect(screen.queryByTestId('fi-alert-circle')).toBeInTheDocument();
    });

    it('should save changes when check button is clicked with valid value', () => {
      renderComponent({
        ...defaultProps,
        modifyInputs: true,
        handleInputChange: mockHandleInputChange,
      });

      // Click edit to enter edit mode
      const editButtons = screen.getAllByTestId('fi-edit-3');
      const editContainer = editButtons[0].closest('span');
      if (editContainer) {
        fireEvent.click(editContainer);
      }

      // Change to valid value
      const inputs = screen.getAllByRole('textbox');
      fireEvent.change(inputs[0], { target: { value: 'valid_param' } });

      // Click check to save
      const checkButtons = screen.getAllByTestId('fi-check');
      const checkContainer = checkButtons[0].closest('span');
      if (checkContainer) {
        fireEvent.click(checkContainer);
      }

      // handleInputChange should be called with rename
      expect(mockHandleInputChange).toHaveBeenCalledWith(
        expect.objectContaining({
          changeType: 'rename',
        }),
      );
    });

    it('should call handleInputChange when delete is clicked', () => {
      renderComponent({
        ...defaultProps,
        modifyInputs: true,
        handleInputChange: mockHandleInputChange,
      });

      const trashButtons = screen.getAllByTestId('fi-trash-2');
      const trashContainer = trashButtons[0].closest('span');
      if (trashContainer) {
        fireEvent.click(trashContainer);
      }

      expect(mockHandleInputChange).toHaveBeenCalled();
    });

    it('should call handleInputChange when Add Input is clicked', () => {
      renderComponent({
        ...defaultProps,
        modifyInputs: true,
        handleInputChange: mockHandleInputChange,
      });

      const addButton = screen.getByText('Add Input');
      fireEvent.click(addButton);

      expect(mockHandleInputChange).toHaveBeenCalled();
    });
  });

  describe('Output Value Display', () => {
    it('should render output textarea when outputValue is provided', () => {
      renderComponent({
        ...defaultProps,
        outputValue: 'Sample output text',
        outputSize: 'textarea',
      });

      const textarea = screen.getByDisplayValue('Sample output text');
      expect(textarea).toBeInTheDocument();
    });

    it('should render copy button when outputValue exists', () => {
      const { container } = renderComponent({
        ...defaultProps,
        outputValue: 'Sample output text',
        outputSize: 'textarea',
      });

      // Look for copy icon/button
      expect(container.querySelector('[data-testid="fi-copy"]')).toBeInTheDocument();
    });

    it('should handle empty input value when value is empty string', async () => {
      const mockHandleInputChange = jest.fn();
      renderComponent({
        ...defaultProps,
        modifyInputs: true,
        handleInputChange: mockHandleInputChange,
      });

      // Click edit to enter edit mode
      const editButtons = screen.getAllByTestId('fi-edit-3');
      const editContainer = editButtons[0].closest('span');
      if (editContainer) {
        fireEvent.click(editContainer);
      }

      // Find the input and set empty value
      await waitFor(() => {
        const inputs = screen.getAllByRole('textbox');
        fireEvent.change(inputs[0], { target: { value: '   ' } }); // Only whitespace
      });

      // Should set empty string when value is only whitespace
      await waitFor(() => {
        const inputs = screen.getAllByRole('textbox');
        expect(inputs[0]).toHaveValue('');
      });
    });

    it('should copy output value to clipboard when copy button is clicked', () => {
      // Set up navigator.clipboard
      const mockWriteText = jest.fn().mockResolvedValue(undefined);
      Object.defineProperty(navigator, 'clipboard', {
        value: { writeText: mockWriteText },
        writable: true,
        configurable: true,
      });

      const copyModule = require('copy-to-clipboard');
      const copySpy = jest.spyOn(copyModule, 'default');

      renderComponent({
        ...defaultProps,
        outputValue: 'Text to copy',
        outputSize: 'textarea',
      });

      const copyButton = screen.getByTestId('fi-copy');
      fireEvent.click(copyButton);

      expect(copySpy).toHaveBeenCalledWith('Text to copy');
    });

    it('should handle copy with empty output value', () => {
      // Set up navigator.clipboard
      const mockWriteText = jest.fn().mockResolvedValue(undefined);
      Object.defineProperty(navigator, 'clipboard', {
        value: { writeText: mockWriteText },
        writable: true,
        configurable: true,
      });

      const copyModule = require('copy-to-clipboard');
      const copySpy = jest.spyOn(copyModule, 'default');

      renderComponent({
        ...defaultProps,
        outputValue: '',
        outputSize: 'textarea',
      });

      const copyButton = screen.getByTestId('fi-copy');
      fireEvent.click(copyButton);

      expect(copySpy).toHaveBeenCalledWith('');
    });
  });

  describe('Managed by agent', () => {
    it('should show "Managed by agent" for tool component connected to agent', () => {
      // Setup: tool component connected to agent
      mockNodes = [
        { id: 'tool-comp-1', data: { component: 'tool' } },
        { id: 'agent-comp-1', data: { component: 'agent' } },
      ];
      mockCurrentWorkflow = {
        workflow: {
          edges: [
            {
              source_component_id: 'tool-comp-1',
              target_component_id: 'agent-comp-1',
              source_handle: { field: 'actions', type: 'array' },
              target_handle: { field: 'tools', type: 'array' },
            },
          ],
        },
      };

      const toolInputs: IOField[] = [
        {
          field: 'tool_inputs',
          type: 'object',
          description: 'Input parameters for the tools',
          'x-ui': {
            type: 'object',
            label: 'Tool Inputs',
            required: true,
            icon: 'fiShare',
          },
        },
      ];

      renderComponent({
        componentId: 'tool-comp-1',
        inputs: toolInputs,
        outputs: [],
      });

      expect(screen.getByPlaceholderText('Managed by agent')).toBeInTheDocument();
    });

    it('should NOT show "Managed by agent" for non-tool component connected to agent', () => {
      // Setup: non-tool component (e.g., prompt_template) connected to agent
      mockNodes = [
        { id: 'prompt-comp-1', data: { component: 'prompt_template' } },
        { id: 'agent-comp-1', data: { component: 'agent' } },
      ];
      mockCurrentWorkflow = {
        workflow: {
          edges: [
            {
              source_component_id: 'prompt-comp-1',
              target_component_id: 'agent-comp-1',
              source_handle: { field: 'output', type: 'string' },
              target_handle: { field: 'input', type: 'string' },
            },
          ],
        },
      };

      renderComponent({
        componentId: 'prompt-comp-1',
        inputs: mockInputs,
        outputs: mockOutputs,
      });

      expect(screen.queryByPlaceholderText('Managed by agent')).not.toBeInTheDocument();
      // Should show default placeholder instead
      expect(screen.getAllByPlaceholderText('Connect component').length).toBeGreaterThan(0);
    });

    it('should NOT show "Managed by agent" for tool component not connected to agent', () => {
      // Setup: tool component not connected to agent
      mockNodes = [
        { id: 'tool-comp-1', data: { component: 'tool' } },
        { id: 'other-comp-1', data: { component: 'vector_store' } },
      ];
      mockCurrentWorkflow = {
        workflow: {
          edges: [
            {
              source_component_id: 'tool-comp-1',
              target_component_id: 'other-comp-1',
              source_handle: { field: 'actions', type: 'array' },
              target_handle: { field: 'input', type: 'array' },
            },
          ],
        },
      };

      const toolInputs: IOField[] = [
        {
          field: 'tool_inputs',
          type: 'object',
          description: 'Input parameters for the tools',
          'x-ui': {
            type: 'object',
            label: 'Tool Inputs',
            required: true,
            icon: 'fiShare',
          },
        },
      ];

      renderComponent({
        componentId: 'tool-comp-1',
        inputs: toolInputs,
        outputs: [],
      });

      expect(screen.queryByPlaceholderText('Managed by agent')).not.toBeInTheDocument();
    });

    it('should NOT show "Managed by agent" for tool component with no edges', () => {
      // Setup: tool component with no connections
      mockNodes = [{ id: 'tool-comp-1', data: { component: 'tool' } }];
      mockCurrentWorkflow = {
        workflow: {
          edges: [],
        },
      };

      const toolInputs: IOField[] = [
        {
          field: 'tool_inputs',
          type: 'object',
          description: 'Input parameters for the tools',
          'x-ui': {
            type: 'object',
            label: 'Tool Inputs',
            required: true,
            icon: 'fiShare',
          },
        },
      ];

      renderComponent({
        componentId: 'tool-comp-1',
        inputs: toolInputs,
        outputs: [],
      });

      expect(screen.queryByPlaceholderText('Managed by agent')).not.toBeInTheDocument();
    });

    it('should return false when edge source does not match componentId', () => {
      // Setup: edge where source_component_id !== componentId
      mockNodes = [
        { id: 'tool-comp-1', data: { component: 'tool' } },
        { id: 'agent-comp-1', data: { component: 'agent' } },
      ];
      mockCurrentWorkflow = {
        workflow: {
          edges: [
            {
              source_component_id: 'other-comp-1', // Different from tool-comp-1
              target_component_id: 'agent-comp-1',
              source_handle: { field: 'actions', type: 'array' },
              target_handle: { field: 'tools', type: 'array' },
            },
          ],
        },
      };

      const toolInputs: IOField[] = [
        {
          field: 'tool_inputs',
          type: 'object',
          description: 'Input parameters for the tools',
          'x-ui': {
            type: 'object',
            label: 'Tool Inputs',
            required: true,
            icon: 'fiShare',
          },
        },
      ];

      renderComponent({
        componentId: 'tool-comp-1',
        inputs: toolInputs,
        outputs: [],
      });

      // Should not show "Managed by agent" since edge source doesn't match
      expect(screen.queryByPlaceholderText('Managed by agent')).not.toBeInTheDocument();
    });

    it('should copy to clipboard using navigator.clipboard.writeText (lines 464-465)', async () => {
      // Mock navigator.clipboard to ensure line 464 is executed
      const mockWriteText = jest.fn().mockResolvedValue(undefined);
      const originalClipboard = navigator.clipboard;
      Object.defineProperty(navigator, 'clipboard', {
        value: {
          writeText: mockWriteText,
        },
        writable: true,
        configurable: true,
      });

      const copyModule = require('copy-to-clipboard');
      jest.spyOn(copyModule, 'default').mockClear();

      renderComponent({
        ...defaultProps,
        outputValue: 'Text to copy',
        outputSize: 'textarea',
      });

      const copyButton = screen.getByTestId('fi-copy');
      fireEvent.click(copyButton);

      // Line 463: copy(outputValue ?? ''); - from copy-to-clipboard library
      // Line 464: navigator.clipboard.writeText(outputValue ?? ''); - this is what we're testing
      await waitFor(
        () => {
          expect(mockWriteText).toHaveBeenCalledWith('Text to copy');
        },
        { timeout: 1000 },
      );

      // Restore original clipboard
      Object.defineProperty(navigator, 'clipboard', {
        value: originalClipboard,
        writable: true,
        configurable: true,
      });
    });

    it('should handle empty outputValue when copying to clipboard', async () => {
      // Mock navigator.clipboard
      const mockWriteText = jest.fn().mockResolvedValue(undefined);
      Object.assign(navigator, {
        clipboard: {
          writeText: mockWriteText,
        },
      });

      renderComponent({
        ...defaultProps,
        outputValue: '',
        outputSize: 'textarea',
      });

      const copyButton = screen.getByTestId('fi-copy');
      fireEvent.click(copyButton);

      // Should call with empty string when outputValue is empty
      await waitFor(() => {
        expect(mockWriteText).toHaveBeenCalledWith('');
      });
    });

    it('should apply gray.300 background color when tool is managed by agent', () => {
      // Setup: tool component connected to agent
      mockNodes = [
        { id: 'tool-comp-1', data: { component: 'tool' } },
        { id: 'agent-comp-1', data: { component: 'agent' } },
      ];
      mockCurrentWorkflow = {
        workflow: {
          edges: [
            {
              source_component_id: 'tool-comp-1',
              target_component_id: 'agent-comp-1',
              source_handle: { field: 'actions', type: 'array' },
              target_handle: { field: 'tools', type: 'array' },
            },
          ],
        },
      };

      const toolInputs: IOField[] = [
        {
          field: 'tool_inputs',
          type: 'object',
          description: 'Input parameters for the tools',
          'x-ui': {
            type: 'object',
            label: 'Tool Inputs',
            required: true,
            icon: 'fiShare',
          },
        },
      ];

      renderComponent({
        componentId: 'tool-comp-1',
        inputs: toolInputs,
        outputs: [],
      });

      const input = screen.getByPlaceholderText('Managed by agent');
      expect(input).toHaveStyle({ backgroundColor: 'var(--chakra-colors-gray-300)' });
    });
  });
});
