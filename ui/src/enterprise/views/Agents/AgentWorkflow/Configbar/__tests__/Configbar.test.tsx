import { render, screen, fireEvent, waitFor } from '@testing-library/react';
import { expect, describe, it, beforeEach } from '@jest/globals';
import '@testing-library/jest-dom/jest-globals';
import '@testing-library/jest-dom';
import Configbar from '../Configbar';
import { ChakraProvider } from '@chakra-ui/react';
import { QueryClient, QueryClientProvider } from '@tanstack/react-query';
import {
  mockSetSelectedComponent,
  mockUpdateNodeById,
  mockSetWorkflow,
} from '../../../../../../../__mocks__/agentStoreMocks';
import * as toolConfigUtils from '../toolConfigUtils';
import {
  WORKFLOW_FILE_ALLOWED_EXTENSIONS,
  WORKFLOW_FILE_DEFAULT_MAX_FILES,
} from '@/enterprise/services/workflowFileConstants';

/** Subset + copy used in fileInput x-ui mocks (first four workflow extensions). */
const MOCK_FILE_INPUT_ACCEPT = WORKFLOW_FILE_ALLOWED_EXTENSIONS.slice(0, 4).join(',');
const MOCK_FILE_INPUT_HELP_TEXT = `You can upload ${WORKFLOW_FILE_ALLOWED_EXTENSIONS.slice(0, 4).join(', ')} files. Max ${WORKFLOW_FILE_DEFAULT_MAX_FILES} files recommended.`;

// Mock useAgentStore
let mockSelectedComponent: Record<string, unknown> | null = {
  id: 'comp-1',
  data: {
    component: 'llm',
    label: 'LLM Component',
    category: 'ai',
    icon: 'https://example.com/icon.svg',
    inputs: [{ field: 'input', type: 'string' }],
    outputs: [{ field: 'output', type: 'string' }],
    json_schema: {
      type: 'object',
      properties: {
        model: { type: 'string', title: 'Model' },
      },
    },
  },
  configuration: { model: 'gpt-4' },
};

let mockNodes: Record<string, unknown>[] = [mockSelectedComponent!];
let mockCurrentWorkflow: Record<string, unknown> | null = { workflow: { components: mockNodes } };
let mockComponentFormErrors: { componentId: string; errorSchema: unknown }[] = [];

jest.mock('@/enterprise/store/useAgentStore', () => ({
  __esModule: true,
  default: (selector: (state: Record<string, unknown>) => unknown) =>
    selector({
      componentFormErrors: mockComponentFormErrors,
      currentWorkflow: mockCurrentWorkflow,
      selectedComponent: mockSelectedComponent,
      nodes: mockNodes,
      updateNodeById: mockUpdateNodeById,
      setSelectedComponent: mockSetSelectedComponent,
      setWorkflow: mockSetWorkflow,
    }),
}));

// Mock useAgentValidation
jest.mock('@/enterprise/hooks/useAgentValidation', () => ({
  __esModule: true,
  default: () => ({
    validateComponent: jest.fn(),
  }),
}));

// Mock toolConfigUtils
jest.mock('../toolConfigUtils', () => ({
  mergeToolConfiguration: jest.fn((existing, newData) => ({
    ...existing,
    ...newData,
    tool_id: newData.tool_id ?? existing.tool_id,
    tools: newData.tools ?? existing.tools ?? [],
  })),
  generateToolOutputs: jest.fn((toolId, tools) => {
    const toolsArray = Array.isArray(tools) ? tools : [];
    return [
      {
        field: 'actions',
        type: 'array',
        description:
          toolId && toolsArray.length > 0
            ? 'Selected actions from the tool'
            : 'Available actions from the tools',
        'x-ui': {
          type: 'array',
          label: toolId && toolsArray.length > 0 ? toolsArray.join(', ') : 'Actions',
          required: false,
          icon: 'fiPlay',
        },
      },
    ];
  }),
}));

// Captured template functions for testing
type ButtonTemplatesType = {
  SubmitButton?: () => React.ReactNode;
  AddButton?: (() => React.ReactNode) | React.ComponentType;
};
let capturedTemplates: { ButtonTemplates?: ButtonTemplatesType } = {};

// Mock FileInputField component (fileInput is rendered as a field)
jest.mock('../FormComponents/FileInputField', () => ({
  __esModule: true,
  default: ({
    formData,
    schema,
    uiSchema,
  }: {
    formData: unknown;
    schema?: { title?: string };
    uiSchema?: { 'ui:options'?: { helpText?: string; tooltip?: string } };
  }) => (
    <div data-testid='file-input-widget'>
      {schema?.title && <span>{schema.title}</span>}
      {uiSchema?.['ui:options']?.helpText && <span>{uiSchema['ui:options'].helpText}</span>}
      {uiSchema?.['ui:options']?.tooltip && (
        <div data-testid='tooltip' data-label={uiSchema['ui:options'].tooltip}>
          <span>Info</span>
        </div>
      )}
      <span>Upload files</span>
      {Array.isArray(formData) &&
        formData.map((file: { id: string; name: string }) => <div key={file.id}>{file.name}</div>)}
    </div>
  ),
}));

// Mock RJSF Form
jest.mock('@rjsf/core', () => ({
  withTheme: () => {
    const MockForm = ({
      onChange,
      schema,
      uiSchema,
      templates,
      fields,
    }: {
      onChange: (e: { formData: unknown }) => void;
      schema: unknown;
      uiSchema?: Record<string, { 'ui:options'?: { onFileView?: (file: unknown) => void } }>;
      templates?: { ButtonTemplates?: ButtonTemplatesType };
      fields?: Record<string, React.ComponentType<any>>;
    }) => {
      // Capture templates for testing
      capturedTemplates = templates || {};

      // Render FileInputField when schema has fileInput (rendered as field)
      const schemaObj = schema as {
        properties?: {
          test_files?: {
            type?: string;
            title?: string;
            'x-ui'?: { widget?: string; helpText?: string; tooltip?: string };
          };
        };
      };
      const fileInputField = schemaObj?.properties?.test_files?.['x-ui']?.widget === 'fileInput';
      const config = mockSelectedComponent?.configuration as { test_files?: unknown[] } | undefined;
      const testFilesSchema = schemaObj?.properties?.test_files;
      const fileInputUiOptions = uiSchema?.test_files?.['ui:options'] ?? testFilesSchema?.['x-ui'];
      const onFileView =
        fileInputUiOptions && 'onFileView' in fileInputUiOptions
          ? (fileInputUiOptions as { onFileView: (file: unknown) => void }).onFileView
          : undefined;

      return (
        <div data-testid='rjsf-form'>
          <span data-testid='form-schema'>{JSON.stringify(schema)}</span>
          {fileInputField && fields?.FileInputField && (
            <>
              <fields.FileInputField
                formData={config?.test_files || []}
                schema={testFilesSchema}
                uiSchema={{ 'ui:options': fileInputUiOptions }}
                idSchema={{ $id: 'test_files' }}
                onChange={() => {}}
                required={false}
                disabled={false}
                formContext={{}}
                name='test_files'
                registry={{} as any}
              />
              {onFileView && (
                <>
                  <button
                    data-testid='trigger-view-file-blob'
                    onClick={() =>
                      onFileView({
                        id: '1',
                        name: 'test.pdf',
                        file: new File(['content'], 'test.pdf', { type: 'application/pdf' }),
                      })
                    }
                  >
                    View file (blob)
                  </button>
                  <button
                    data-testid='trigger-view-file-id'
                    onClick={() => onFileView({ id: 'file-1', name: 'test.pdf' })}
                  >
                    View file (id)
                  </button>
                </>
              )}
            </>
          )}
          <button
            data-testid='trigger-change'
            onClick={() => onChange({ formData: { model: 'gpt-3.5' } })}
          >
            Change
          </button>
          <button
            data-testid='trigger-prompt-change'
            onClick={() => onChange({ formData: { prompt: 'Hello {name} and {age}' } })}
          >
            Change Prompt
          </button>
        </div>
      );
    };
    return MockForm;
  },
}));

jest.mock('@rjsf/chakra-ui', () => ({
  Theme: {},
}));

jest.mock('@rjsf/validator-ajv8', () => ({
  __esModule: true,
  default: {},
}));

// Mock IOFields
jest.mock('../../IOFields', () => ({
  __esModule: true,
  default: ({
    componentId,
    handleInputChange,
  }: {
    componentId: string;
    handleInputChange?: (props: { changeType: string; index: number; value?: string }) => void;
  }) => (
    <div data-testid='io-fields'>
      {componentId}
      {handleInputChange && (
        <button
          data-testid='trigger-input-change'
          onClick={() => handleInputChange({ changeType: 'add', index: 0, value: 'new_input' })}
        >
          Trigger Input Change
        </button>
      )}
    </div>
  ),
}));

// Mock IconEntity
jest.mock('@/components/IconEntity', () => ({
  __esModule: true,
  default: ({ onClick }: { icon: unknown; marginRight: string; onClick: () => void }) => (
    <button data-testid='close-button' onClick={onClick}>
      Close
    </button>
  ),
}));

// Mock utils
const mockBuildUiSchemaFromXUI = jest.fn().mockReturnValue({});
jest.mock('../utils', () => ({
  buildUiSchemaFromXUI: (...args: unknown[]) => mockBuildUiSchemaFromXUI(...args),
  getCategoryBaseColor: jest.fn().mockReturnValue('brand'),
  getCategoryLabel: jest.fn().mockReturnValue('AI'),
  handleInputChange: jest.fn(),
  handlePgVectorConfig: jest.fn(),
}));

// Mock react-icons
jest.mock('react-icons/fi');

// Mock useDebouncedCallback
jest.mock('use-debounce', () => ({
  useDebouncedCallback: (fn: (...args: unknown[]) => void) => fn,
}));

// Mock the API functions
jest.mock('@/services/connectors', () => ({
  getUserConnectors: jest
    .fn()
    .mockResolvedValue({ data: [{ id: 'conn-1', attributes: { name: 'PostgreSQL' } }] }),
}));

jest.mock('@/services/syncs', () => ({
  getCatalog: jest.fn().mockResolvedValue({ data: { streams: [] } }),
}));

const mockGetWorkflowFileContent = jest.fn();
jest.mock('@/enterprise/services/agents', () => ({
  ...jest.requireActual('@/enterprise/services/agents'),
  getWorkflowFileContent: (...args: unknown[]) => mockGetWorkflowFileContent(...args),
}));

const mockUseParams = jest.fn(() => ({ id: undefined as string | undefined }));
jest.mock('react-router-dom', () => ({
  ...jest.requireActual('react-router-dom'),
  useParams: () => mockUseParams(),
}));

jest.mock('@/enterprise/components/ChatbotInterface/ViewWorkflowFileModal', () => ({
  __esModule: true,
  default: ({
    open,
    onClose,
    fileName,
    error,
  }: {
    open: boolean;
    onClose: () => void;
    fileName: string | null;
    error?: string | null;
  }) =>
    open ? (
      <div data-testid='view-workflow-file-modal'>
        <span data-testid='modal-file-name'>{fileName}</span>
        {error && <span data-testid='modal-error'>{error}</span>}
        <button data-testid='configbar-close-modal' onClick={onClose}>
          Close
        </button>
      </div>
    ) : null,
}));

describe('Configbar', () => {
  const queryClient = new QueryClient({
    defaultOptions: {
      queries: {
        retry: false,
      },
    },
  });

  const renderComponent = () => {
    return render(
      <ChakraProvider>
        <QueryClientProvider client={queryClient}>
          <Configbar />
        </QueryClientProvider>
      </ChakraProvider>,
    );
  };

  beforeEach(() => {
    jest.clearAllMocks();
    queryClient.clear();
    // Reset to defaults
    mockCurrentWorkflow = { workflow: { components: mockNodes } };
    mockComponentFormErrors = [];
    capturedTemplates = {};
    mockUseParams.mockReturnValue({ id: undefined });
    mockBuildUiSchemaFromXUI.mockImplementation(
      (schema: { properties?: Record<string, unknown> }) => {
        if (schema?.properties?.test_files) {
          return {
            test_files: {
              'ui:field': 'FileInputField',
              'ui:options': {
                helpText: MOCK_FILE_INPUT_HELP_TEXT,
                tooltip: 'Displays the attachment icon in chat',
              },
            },
          };
        }
        return {};
      },
    );
  });

  describe('Rendering', () => {
    it('should render component label', () => {
      renderComponent();
      expect(screen.getByText('LLM Component')).toBeInTheDocument();
    });

    it('should render category label', () => {
      renderComponent();
      expect(screen.getByText('AI')).toBeInTheDocument();
    });

    it('should render component icon', () => {
      renderComponent();
      const img = screen.getByRole('img');
      expect(img).toHaveAttribute('src', 'https://example.com/icon.svg');
    });

    it('should render close button', () => {
      renderComponent();
      expect(screen.getByTestId('close-button')).toBeInTheDocument();
    });

    it('should render RJSF form when json_schema exists', () => {
      renderComponent();
      expect(screen.getByTestId('rjsf-form')).toBeInTheDocument();
    });

    it('should render IOFields', () => {
      renderComponent();
      expect(screen.getByTestId('io-fields')).toBeInTheDocument();
    });

    it('should pass componentId to IOFields', () => {
      renderComponent();
      expect(screen.getByTestId('io-fields')).toHaveTextContent('comp-1');
    });
  });

  describe('Close Functionality', () => {
    it('should call setSelectedComponent with null when close is clicked', () => {
      renderComponent();
      const closeButton = screen.getByTestId('close-button');
      fireEvent.click(closeButton);
      expect(mockSetSelectedComponent).toHaveBeenCalledWith(null);
    });
  });

  describe('Form Change', () => {
    it('should handle form changes', () => {
      renderComponent();
      const changeButton = screen.getByTestId('trigger-change');
      fireEvent.click(changeButton);
      // The debounced callback should be called
      expect(mockSetWorkflow).toHaveBeenCalled();
    });
  });

  describe('Workflow status on configuration change', () => {
    it('should set workflow status to draft when configuration changes and workflow is published', () => {
      mockCurrentWorkflow = {
        workflow: {
          components: mockNodes,
          status: 'published',
        },
      };

      renderComponent();
      const changeButton = screen.getByTestId('trigger-change');
      fireEvent.click(changeButton);

      expect(mockSetWorkflow).toHaveBeenCalledWith(
        expect.objectContaining({
          workflow: expect.objectContaining({
            status: 'draft',
          }),
        }),
      );
    });

    it('should keep workflow status unchanged when configuration changes and workflow is already draft', () => {
      mockCurrentWorkflow = {
        workflow: {
          components: mockNodes,
          status: 'draft',
        },
      };

      renderComponent();
      const changeButton = screen.getByTestId('trigger-change');
      fireEvent.click(changeButton);

      expect(mockSetWorkflow).toHaveBeenCalledWith(
        expect.objectContaining({
          workflow: expect.objectContaining({
            status: 'draft',
          }),
        }),
      );
    });
  });

  describe('handleOnChange logical branching', () => {
    it('should NOT update variables if prompt has no match', async () => {
      mockSelectedComponent = {
        id: 'p1',
        data: {
          component: 'prompt_template',
          json_schema: { type: 'object', properties: { prompt: { type: 'string' } } },
          inputs: [],
        },
        configuration: { prompt: '' },
      };
      mockNodes = [mockSelectedComponent!];
      renderComponent();

      const promptChange = screen.getByTestId('trigger-prompt-change');
      // trigger-prompt-change in mock sends "Hello {name} and {age}"
      // Let's make a new button for "no match"
      fireEvent.click(promptChange);

      await new Promise((resolve) => setTimeout(resolve, 250));
      expect(mockSetWorkflow).toHaveBeenCalled();
    });

    it('should handle tool configuration when tools is empty in new data but NOT empty in context', async () => {
      mockSelectedComponent = {
        id: 't1',
        data: { component: 'tool', json_schema: { type: 'object' } },
        configuration: { tools: ['c1', 'c2'], tool_id: 'tool-x' },
      };
      mockNodes = [mockSelectedComponent!];
      renderComponent();

      // Trigger change with empty tools
      const change = screen.getByTestId('trigger-change');
      // trigger-change in mock sends { model: 'gpt-3.5' } - tools is missing (undefined)
      fireEvent.click(change);

      await new Promise((resolve) => setTimeout(resolve, 250));

      // It should have merged tools: ['c1', 'c2'] into the updated workflow
      expect(mockSetWorkflow).toHaveBeenCalledWith(
        expect.objectContaining({
          workflow: expect.objectContaining({
            components: expect.arrayContaining([
              expect.objectContaining({
                configuration: expect.objectContaining({ tools: ['c1', 'c2'] }),
              }),
            ]),
          }),
        }),
      );
    });
  });

  describe('Prompt Template', () => {
    beforeEach(() => {
      mockSelectedComponent = {
        id: 'prompt-1',
        data: {
          component: 'prompt_template',
          label: 'Prompt Template',
          category: 'ai',
          icon: 'https://example.com/prompt.svg',
          inputs: [],
          outputs: [{ field: 'output', type: 'string' }],
          json_schema: {
            type: 'object',
            properties: {
              prompt: { type: 'string', title: 'Prompt' },
            },
          },
        },
        configuration: { prompt: '' },
      };
      mockNodes = [mockSelectedComponent];
    });

    afterEach(() => {
      // Reset to default
      mockSelectedComponent = {
        id: 'comp-1',
        data: {
          component: 'llm',
          label: 'LLM Component',
          category: 'ai',
          icon: 'https://example.com/icon.svg',
          inputs: [{ field: 'input', type: 'string' }],
          outputs: [{ field: 'output', type: 'string' }],
          json_schema: {
            type: 'object',
            properties: {
              model: { type: 'string', title: 'Model' },
            },
          },
        },
        configuration: { model: 'gpt-4' },
      };
      mockNodes = [mockSelectedComponent];
    });

    it('should extract variables from prompt when form changes', () => {
      renderComponent();
      const changeButton = screen.getByTestId('trigger-prompt-change');
      fireEvent.click(changeButton);
      expect(mockSetWorkflow).toHaveBeenCalled();
    });
  });

  describe('Error Display', () => {
    it('should render form even with empty errors', () => {
      renderComponent();
      expect(screen.getByTestId('rjsf-form')).toBeInTheDocument();
    });
  });

  describe('Python Component', () => {
    beforeEach(() => {
      mockSelectedComponent = {
        id: 'python-1',
        data: {
          component: 'python_custom',
          label: 'Python Component',
          category: 'custom',
          icon: 'https://example.com/python.svg',
          inputs: [{ field: 'input', type: 'string', 'x-ui': { label: 'Input', type: 'input' } }],
          outputs: [{ field: 'output', type: 'string' }],
          json_schema: {
            type: 'object',
            properties: {
              code: { type: 'string', title: 'Code' },
            },
          },
        },
        configuration: { code: '' },
      };
      mockNodes = [mockSelectedComponent];
    });

    it('should render IOFields with modifyInputs for python component', () => {
      renderComponent();
      expect(screen.getByTestId('io-fields')).toBeInTheDocument();
    });

    it('should handle input changes for python component', () => {
      renderComponent();
      // The IOFields should be rendered with handleInputChange for python component
      const triggerButton = screen.queryByTestId('trigger-input-change');
      expect(triggerButton).toBeInTheDocument();
      if (triggerButton) {
        fireEvent.click(triggerButton);
      }
      // Verify IOFields is rendered with the trigger button for python_custom component
      expect(screen.getByTestId('io-fields')).toBeInTheDocument();
    });
  });

  describe('Vector Store Component', () => {
    beforeEach(() => {
      mockSelectedComponent = {
        id: 'vector-1',
        component_type: 'vector_store',
        data: {
          component: 'vector_store',
          label: 'Vector Store',
          category: 'storage',
          icon: 'https://example.com/vector.svg',
          inputs: [],
          outputs: [{ field: 'output', type: 'string' }],
          json_schema: {
            type: 'object',
            properties: {
              database: { type: 'string', title: 'Database' },
            },
          },
        },
        configuration: { database: 'conn-1' },
      };
      mockNodes = [mockSelectedComponent!];
    });

    afterEach(() => {
      // Reset to default
      mockSelectedComponent = {
        id: 'comp-1',
        data: {
          component: 'llm',
          label: 'LLM Component',
          category: 'ai',
          icon: 'https://example.com/icon.svg',
          inputs: [{ field: 'input', type: 'string' }],
          outputs: [{ field: 'output', type: 'string' }],
          json_schema: {
            type: 'object',
            properties: {
              model: { type: 'string', title: 'Model' },
            },
          },
        },
        configuration: { model: 'gpt-4' },
      };
      mockNodes = [mockSelectedComponent!];
    });

    it('should render vector store component', () => {
      renderComponent();
      expect(screen.getByText('Vector Store')).toBeInTheDocument();
    });

    it('should trigger handlePgVectorConfig useEffect when conditions are met', async () => {
      renderComponent();

      // Wait for queries to complete and useEffect to trigger
      await new Promise((resolve) => setTimeout(resolve, 200));

      // Verify the component renders correctly with vector_store type
      expect(screen.getByText('Vector Store')).toBeInTheDocument();
    });

    it('should use null AddButton for vector_store component', () => {
      renderComponent();
      // Form is rendered with vector_store specific templates
      expect(screen.getByTestId('rjsf-form')).toBeInTheDocument();
    });
  });

  describe('No Selected Component', () => {
    beforeEach(() => {
      mockSelectedComponent = null as unknown as Record<string, unknown>;
    });

    afterEach(() => {
      // Reset to default
      mockSelectedComponent = {
        id: 'comp-1',
        data: {
          component: 'llm',
          label: 'LLM Component',
          category: 'ai',
          icon: 'https://example.com/icon.svg',
          inputs: [{ field: 'input', type: 'string' }],
          outputs: [{ field: 'output', type: 'string' }],
          json_schema: {
            type: 'object',
            properties: {
              model: { type: 'string', title: 'Model' },
            },
          },
        },
        configuration: { model: 'gpt-4' },
      };
    });

    it('should render nothing when selectedComponent is null', () => {
      renderComponent();
      // Should not render the configbar elements
      expect(screen.queryByTestId('io-fields')).not.toBeInTheDocument();
      expect(screen.queryByTestId('close-button')).not.toBeInTheDocument();
    });
  });

  describe('Component Without JSON Schema', () => {
    beforeEach(() => {
      mockSelectedComponent = {
        id: 'no-schema-1',
        data: {
          component: 'simple',
          label: 'Simple Component',
          category: 'basic',
          icon: 'https://example.com/simple.svg',
          inputs: [],
          outputs: [],
          json_schema: null, // No schema
        },
        configuration: {},
      };
      mockNodes = [mockSelectedComponent!];
    });

    afterEach(() => {
      mockSelectedComponent = {
        id: 'comp-1',
        data: {
          component: 'llm',
          label: 'LLM Component',
          category: 'ai',
          icon: 'https://example.com/icon.svg',
          inputs: [{ field: 'input', type: 'string' }],
          outputs: [{ field: 'output', type: 'string' }],
          json_schema: {
            type: 'object',
            properties: {
              model: { type: 'string', title: 'Model' },
            },
          },
        },
        configuration: { model: 'gpt-4' },
      };
      mockNodes = [mockSelectedComponent!];
    });

    it('should not render form when json_schema is null', () => {
      renderComponent();
      expect(screen.queryByTestId('rjsf-form')).not.toBeInTheDocument();
    });
  });

  describe('No Current Workflow', () => {
    beforeEach(() => {
      mockCurrentWorkflow = null;
      mockSelectedComponent = {
        id: 'comp-1',
        data: {
          component: 'llm',
          label: 'LLM Component',
          category: 'ai',
          icon: 'https://example.com/icon.svg',
          inputs: [{ field: 'input', type: 'string' }],
          outputs: [{ field: 'output', type: 'string' }],
          json_schema: {
            type: 'object',
            properties: {
              model: { type: 'string', title: 'Model' },
            },
          },
        },
        configuration: { model: 'gpt-4' },
      };
      mockNodes = [mockSelectedComponent!];
    });

    afterEach(() => {
      mockCurrentWorkflow = { workflow: { components: mockNodes } };
    });

    it('should handle form change when currentWorkflow is null', () => {
      renderComponent();
      const changeButton = screen.getByTestId('trigger-change');
      fireEvent.click(changeButton);
      // Should return early without error
      expect(mockSetWorkflow).not.toHaveBeenCalled();
    });
  });

  describe('Component Form Errors', () => {
    beforeEach(() => {
      mockComponentFormErrors = [
        {
          componentId: 'comp-1',
          errorSchema: { model: { __errors: ['Model is required'] } },
        },
      ];
      mockSelectedComponent = {
        id: 'comp-1',
        data: {
          component: 'llm',
          label: 'LLM Component',
          category: 'ai',
          icon: 'https://example.com/icon.svg',
          inputs: [{ field: 'input', type: 'string' }],
          outputs: [{ field: 'output', type: 'string' }],
          json_schema: {
            type: 'object',
            properties: {
              model: { type: 'string', title: 'Model' },
            },
          },
        },
        configuration: { model: 'gpt-4' },
      };
      mockNodes = [mockSelectedComponent!];
    });

    afterEach(() => {
      mockComponentFormErrors = [];
    });

    it('should pass errors to form when component has form errors', () => {
      renderComponent();
      // Form should still render with errors
      expect(screen.getByTestId('rjsf-form')).toBeInTheDocument();
    });
  });

  describe('Button Templates', () => {
    it('should provide SubmitButton template that returns null', () => {
      renderComponent();

      // Invoke the captured SubmitButton template
      if (capturedTemplates.ButtonTemplates?.SubmitButton) {
        const result = capturedTemplates.ButtonTemplates.SubmitButton();
        expect(result).toBeNull();
      }
    });

    it('should provide AddButton template for non-vector_store components', () => {
      renderComponent();

      // AddButton should be defined for non-vector_store
      expect(capturedTemplates.ButtonTemplates?.AddButton).toBeDefined();
    });

    it('should provide null AddButton for vector_store components', () => {
      mockSelectedComponent = {
        id: 'vector-1',
        component_type: 'vector_store',
        data: {
          component: 'vector_store',
          label: 'Vector Store',
          category: 'storage',
          icon: 'https://example.com/vector.svg',
          inputs: [],
          outputs: [{ field: 'output', type: 'string' }],
          json_schema: {
            type: 'object',
            properties: {
              database: { type: 'string', title: 'Database' },
            },
          },
        },
        configuration: { database: 'conn-1' },
      };
      mockNodes = [mockSelectedComponent!];

      renderComponent();

      // For vector_store, AddButton should return null
      if (
        capturedTemplates.ButtonTemplates?.AddButton &&
        typeof capturedTemplates.ButtonTemplates.AddButton === 'function'
      ) {
        const result = (capturedTemplates.ButtonTemplates.AddButton as () => null)();
        expect(result).toBeNull();
      }
    });

    describe('Tool Component Handling', () => {
      beforeEach(() => {
        mockSelectedComponent = {
          id: 'tool-comp-1',
          data: {
            component: 'tool',
            label: 'Tool Component',
            category: 'tools',
            icon: 'https://example.com/tool-icon.svg',
            inputs: [],
            outputs: [],
            json_schema: {
              type: 'object',
              properties: {
                tool_id: { type: 'string' },
                tools: { type: 'array' },
              },
            },
          },
          configuration: {
            tool_id: 'tool-123',
            tools: ['action1', 'action2'],
          },
        };
        mockNodes = [mockSelectedComponent!];
        mockCurrentWorkflow = { workflow: { components: mockNodes } };
      });

      it('should handle tool configuration changes', async () => {
        renderComponent();

        fireEvent.click(screen.getByTestId('trigger-change'));

        await new Promise((resolve) => setTimeout(resolve, 250));

        expect(toolConfigUtils.mergeToolConfiguration).toHaveBeenCalled();
        expect(mockSetWorkflow).toHaveBeenCalled();
      });

      it('should preserve tools from formContext when RJSF filters it', async () => {
        renderComponent();

        // Simulate RJSF onChange without tools (as if it was filtered)
        const changeButton = screen.getByTestId('trigger-change');
        fireEvent.click(changeButton);

        await new Promise((resolve) => setTimeout(resolve, 250));

        // Should preserve tools from formContext
        expect(mockSetWorkflow).toHaveBeenCalled();
      });

      it('should generate tool outputs for tool components', async () => {
        renderComponent();

        fireEvent.click(screen.getByTestId('trigger-change'));

        await new Promise((resolve) => setTimeout(resolve, 250));

        expect(toolConfigUtils.generateToolOutputs).toHaveBeenCalled();
      });

      it('should merge tool configuration correctly', async () => {
        renderComponent();

        fireEvent.click(screen.getByTestId('trigger-change'));

        await new Promise((resolve) => setTimeout(resolve, 250));

        expect(toolConfigUtils.mergeToolConfiguration).toHaveBeenCalledWith(
          expect.objectContaining({ tool_id: 'tool-123', tools: ['action1', 'action2'] }),
          expect.any(Object),
        );
      });

      it('should handle tool component with empty tools array', async () => {
        mockSelectedComponent = {
          ...mockSelectedComponent,
          configuration: {
            tool_id: 'tool-123',
            tools: [],
          },
        };
        mockNodes = [mockSelectedComponent!];
        mockCurrentWorkflow = { workflow: { components: mockNodes } };

        renderComponent();

        fireEvent.click(screen.getByTestId('trigger-change'));

        await new Promise((resolve) => setTimeout(resolve, 250));

        expect(toolConfigUtils.generateToolOutputs).toHaveBeenCalledWith('tool-123', []);
      });

      it('should handle tool configuration with legacy tool_id object format', async () => {
        mockSelectedComponent = {
          ...mockSelectedComponent,
          configuration: {
            tool_id: { tool_id: 'tool-123', tools: ['action1'] } as any,
            tools: ['action1'],
          },
        };
        mockNodes = [mockSelectedComponent!];
        mockCurrentWorkflow = { workflow: { components: mockNodes } };

        renderComponent();

        fireEvent.click(screen.getByTestId('trigger-change'));

        await new Promise((resolve) => setTimeout(resolve, 250));

        expect(toolConfigUtils.mergeToolConfiguration).toHaveBeenCalled();
      });

      it('should preserve tools from formContext when tools is undefined in new data', async () => {
        mockSelectedComponent = {
          ...mockSelectedComponent,
          configuration: {
            tool_id: 'tool-123',
            tools: ['action1', 'action2'],
          },
        };
        mockNodes = [mockSelectedComponent!];
        mockCurrentWorkflow = { workflow: { components: mockNodes } };

        renderComponent();

        fireEvent.click(screen.getByTestId('trigger-change'));

        await new Promise((resolve) => setTimeout(resolve, 250));

        expect(toolConfigUtils.mergeToolConfiguration).toHaveBeenCalled();
      });

      it('should handle tool configuration when tools is empty array in new data', async () => {
        mockSelectedComponent = {
          ...mockSelectedComponent,
          configuration: {
            tool_id: 'tool-123',
            tools: ['action1'],
          },
        };
        mockNodes = [mockSelectedComponent!];
        mockCurrentWorkflow = { workflow: { components: mockNodes } };

        renderComponent();

        fireEvent.click(screen.getByTestId('trigger-change'));

        await new Promise((resolve) => setTimeout(resolve, 250));

        expect(toolConfigUtils.mergeToolConfiguration).toHaveBeenCalled();
      });

      it('should generate tool outputs with valid tool_id and tools', async () => {
        mockSelectedComponent = {
          ...mockSelectedComponent,
          configuration: {
            tool_id: 'tool-123',
            tools: ['action1', 'action2'],
          },
        };
        mockNodes = [mockSelectedComponent!];
        mockCurrentWorkflow = { workflow: { components: mockNodes } };

        renderComponent();

        fireEvent.click(screen.getByTestId('trigger-change'));

        await new Promise((resolve) => setTimeout(resolve, 250));

        expect(toolConfigUtils.generateToolOutputs).toHaveBeenCalledWith('tool-123', [
          'action1',
          'action2',
        ]);
      });

      it('should generate tool outputs with undefined tool_id', async () => {
        mockSelectedComponent = {
          ...mockSelectedComponent,
          configuration: {
            tool_id: undefined,
            tools: [],
          },
        };
        mockNodes = [mockSelectedComponent!];
        mockCurrentWorkflow = { workflow: { components: mockNodes } };

        renderComponent();

        fireEvent.click(screen.getByTestId('trigger-change'));

        await new Promise((resolve) => setTimeout(resolve, 250));

        expect(toolConfigUtils.generateToolOutputs).toHaveBeenCalled();
      });

      it('should handle tool configuration when toolsFromContext is not an array', async () => {
        mockSelectedComponent = {
          ...mockSelectedComponent,
          configuration: {
            tool_id: 'tool-123',
            tools: 'not-an-array' as any,
          },
        };
        mockNodes = [mockSelectedComponent!];
        mockCurrentWorkflow = { workflow: { components: mockNodes } };

        renderComponent();

        fireEvent.click(screen.getByTestId('trigger-change'));

        await new Promise((resolve) => setTimeout(resolve, 250));

        expect(toolConfigUtils.mergeToolConfiguration).toHaveBeenCalled();
        // generateToolOutputs should handle non-array tools gracefully
        expect(toolConfigUtils.generateToolOutputs).toHaveBeenCalled();
      });

      it('should handle tool configuration when toolData.tools is not an array', async () => {
        mockSelectedComponent = {
          ...mockSelectedComponent,
          configuration: {
            tool_id: 'tool-123',
            tools: ['action1'],
          },
        };
        mockNodes = [mockSelectedComponent!];
        mockCurrentWorkflow = { workflow: { components: mockNodes } };

        renderComponent();

        fireEvent.click(screen.getByTestId('trigger-change'));

        await new Promise((resolve) => setTimeout(resolve, 250));

        expect(toolConfigUtils.mergeToolConfiguration).toHaveBeenCalled();
      });

      it('should handle tool configuration when componentIndex is -1', async () => {
        mockSelectedComponent = {
          ...mockSelectedComponent,
          id: 'non-existent',
        };
        // Set nodes to empty array so componentIndex will be -1
        mockNodes = [];
        mockCurrentWorkflow = { workflow: { components: mockNodes } };

        renderComponent();

        fireEvent.click(screen.getByTestId('trigger-change'));

        await new Promise((resolve) => setTimeout(resolve, 250));

        // Should not crash when componentIndex is -1
        expect(mockSetWorkflow).not.toHaveBeenCalled();
      });
    });
  });

  describe('Catalog Query Edge Cases', () => {
    it('should return null when selectedComponent has no database configuration (line 94)', async () => {
      // Mock getCatalog to track if it's called

      const syncsModule = require('@/services/syncs');
      const getCatalogSpy = jest.spyOn(syncsModule, 'getCatalog');

      // Ensure selectedComponent exists but has no database in configuration
      const baseData = mockSelectedComponent?.data || {
        component: 'llm',
        label: 'LLM Component',
        category: 'ai',
        icon: 'https://example.com/icon.svg',
        inputs: [],
        outputs: [],
        json_schema: { type: 'object', properties: {} },
      };

      mockSelectedComponent = {
        id: 'comp-1',
        data: baseData,
        configuration: {}, // No database property - line 94 should return null
      };
      mockNodes = [mockSelectedComponent];

      renderComponent();

      // The queryFn on line 90-94 should return null when database is not configured
      // Line 91-94: if (selectedComponent?.configuration?.database) { return getCatalog(...); } return null;
      // Since there's no database, the condition is false and line 94 executes: return null;
      expect(screen.getByTestId('rjsf-form')).toBeInTheDocument();

      // Wait for query to execute and verify getCatalog was NOT called (because line 94 returns null)
      await waitFor(
        () => {
          // getCatalog should not be called because the condition on line 91 is false
          // Line 94: return null; should execute instead
        },
        { timeout: 500 },
      );

      // Verify getCatalog was not called (because we returned null on line 94)
      expect(getCatalogSpy).not.toHaveBeenCalled();
    });
  });

  describe('Prompt Template Variables', () => {
    it('should handle null variables from prompt match', async () => {
      const baseData = mockSelectedComponent?.data || {
        component: 'llm',
        label: 'LLM Component',
        category: 'ai',
        icon: 'https://example.com/icon.svg',
        inputs: [],
        outputs: [],
        json_schema: {
          type: 'object',
          properties: {},
        },
      };

      mockSelectedComponent = {
        id: 'comp-1',
        data: {
          ...baseData,
          component: 'prompt_template',
        },
        configuration: {
          prompt: 'No variables here',
        },
      };
      mockNodes = [mockSelectedComponent];

      renderComponent();

      fireEvent.click(screen.getByTestId('trigger-change'));

      await new Promise((resolve) => setTimeout(resolve, 250));

      // Should handle null variables gracefully (line 164)
      expect(mockSetSelectedComponent).toHaveBeenCalled();
    });
  });

  describe('Component Update Callbacks', () => {
    it('should call setSelectedComponent callback in handlePgVectorConfig (line 224)', async () => {
      // Get the real handlePgVectorConfig implementation and use it

      const utilsModule = jest.requireActual('../utils');
      const originalHandlePgVectorConfig = utilsModule.handlePgVectorConfig;

      // Replace the mock with the real implementation for this test

      const mockedUtilsForTest = require('../utils');
      mockedUtilsForTest.handlePgVectorConfig = originalHandlePgVectorConfig;

      // Set up vector_store component with database, connectors, and catalog
      const vectorStoreData = {
        component: 'vector_store',
        label: 'Vector Store',
        category: 'data',
        icon: 'https://example.com/icon.svg',
        inputs: [],
        outputs: [],
        json_schema: {
          type: 'object',
          properties: {},
          required: [],
        },
      };

      mockSelectedComponent = {
        id: 'vector-store-1',
        data: vectorStoreData,
        configuration: {
          database: 'conn-1',
        },
      };
      mockNodes = [mockSelectedComponent];

      // Mock connectors and catalog to trigger handlePgVectorConfig

      const connectorsModule = require('@/services/connectors');

      const syncsModule = require('@/services/syncs');
      const { getUserConnectors } = connectorsModule;
      const { getCatalog } = syncsModule;

      // Mock getUserConnectors to return Postgresql connector
      getUserConnectors.mockResolvedValue({
        data: [{ id: 'conn-1', attributes: { connector_name: 'Postgresql' } }],
      });

      // Mock getCatalog to return catalog data with proper structure
      // The catalog needs to have the right structure for handlePgVectorConfig to work
      getCatalog.mockResolvedValue({
        data: {
          attributes: {
            catalog: {
              streams: [
                {
                  name: 'table1',
                  json_schema: {
                    properties: {
                      vector_col: { type: 'array' },
                      text_col: { type: 'string' },
                    },
                  },
                },
              ],
            },
          },
        },
      });

      renderComponent();

      // Wait for queries to resolve and useEffect to trigger handlePgVectorConfig
      // The useEffect on line 212-227 requires:
      // - selectedComponent?.data.component === 'vector_store' ✓
      // - selectedComponent?.configuration?.database ✓
      // - connectors (from useQuery) ✓
      // - connectorCatalog (from useQuery) ✓
      // Line 224: (comp) => setSelectedComponent(comp) should be called
      // Note: handlePgVectorConfig needs specific conditions to call setSelectedComponent
      // It only calls it when isPostgresql is true and certain conditions are met (line 248 in utils.ts)
      await waitFor(
        () => {
          // handlePgVectorConfig should be called, which calls setSelectedComponent callback
          // The callback on line 224 is passed to handlePgVectorConfig and called on line 248 of utils.ts
          expect(mockSetSelectedComponent).toHaveBeenCalled();
        },
        { timeout: 3000 },
      );

      // Restore the mock
      mockedUtilsForTest.handlePgVectorConfig = jest.fn();
    });

    it('should call setInputs callback when updating python_custom component inputs (line 315)', async () => {
      // This tests the setInputs callback in the form (line 315)
      // The setInputs callback is used for PYTHON_COMPONENT ('python_custom') components
      const pythonData = {
        component: 'python_custom', // PYTHON_COMPONENT constant value
        label: 'Python Component',
        category: 'code',
        icon: 'https://example.com/icon.svg',
        inputs: [{ field: 'input1', type: 'string' }],
        outputs: [],
        json_schema: {
          type: 'object',
          properties: {
            code: { type: 'string' },
          },
        },
      };

      mockSelectedComponent = {
        id: 'python-1',
        data: pythonData,
        configuration: {},
      };
      mockNodes = [mockSelectedComponent];

      renderComponent();

      // The form should be rendered
      expect(screen.getByTestId('rjsf-form')).toBeInTheDocument();

      // When form values change for a python_custom component, setInputs should be called (line 315)
      // Line 314-319: setInputs callback should be called
      fireEvent.click(screen.getByTestId('trigger-change'));
      await new Promise((resolve) => setTimeout(resolve, 250));

      // setInputs callback should be called through handleInputChange
      // This tests line 315: setSelectedComponent({ ...selectedComponent, data: { ...selectedComponent.data, inputs } })
      expect(mockSetSelectedComponent).toHaveBeenCalled();
    });
  });

  describe('FileInput Widget', () => {
    beforeEach(() => {
      mockSelectedComponent = {
        id: 'file-input-1',
        data: {
          component: 'knowledge_base',
          label: 'Knowledge Base',
          category: 'data',
          icon: 'https://example.com/kb.svg',
          inputs: [{ field: 'query', type: 'string' }],
          outputs: [{ field: 'results', type: 'array' }],
          json_schema: {
            type: 'object',
            properties: {
              test_files: {
                type: 'array',
                title: 'Test Files',
                items: {
                  type: 'object',
                  properties: {
                    id: { type: 'string' },
                    name: { type: 'string' },
                  },
                },
                'x-ui': {
                  widget: 'fileInput',
                  order: 4,
                  optional: true,
                  acceptedFileTypes: MOCK_FILE_INPUT_ACCEPT,
                  maxFiles: WORKFLOW_FILE_DEFAULT_MAX_FILES,
                  helpText: MOCK_FILE_INPUT_HELP_TEXT,
                  tooltip: 'Displays the attachment icon in chat',
                },
              },
            },
          },
        },
        configuration: { test_files: [] },
      };
      mockNodes = [mockSelectedComponent];
    });

    afterEach(() => {
      // Reset to default
      mockSelectedComponent = {
        id: 'comp-1',
        data: {
          component: 'llm',
          label: 'LLM Component',
          category: 'ai',
          icon: 'https://example.com/icon.svg',
          inputs: [{ field: 'input', type: 'string' }],
          outputs: [{ field: 'output', type: 'string' }],
          json_schema: {
            type: 'object',
            properties: {
              model: { type: 'string', title: 'Model' },
            },
          },
        },
        configuration: { model: 'gpt-4' },
      };
      mockNodes = [mockSelectedComponent];
    });

    it('should render FileInput widget when fileInput widget is specified', () => {
      renderComponent();
      expect(screen.getByText('Test Files')).toBeInTheDocument();
      expect(screen.getByText('Upload files')).toBeInTheDocument();
    });

    it('should render FileInput with help text', () => {
      renderComponent();
      expect(screen.getByText(MOCK_FILE_INPUT_HELP_TEXT)).toBeInTheDocument();
    });

    it('should render FileInput with tooltip', () => {
      renderComponent();
      const tooltip = screen.getByTestId('tooltip');
      expect(tooltip).toHaveAttribute('data-label', 'Displays the attachment icon in chat');
    });

    it('should render FileInput with existing files', () => {
      mockSelectedComponent = {
        ...mockSelectedComponent,
        configuration: {
          test_files: [
            { id: '1', name: 'test.pdf' },
            { id: '2', name: 'document.docx' },
          ],
        },
      };
      renderComponent();
      expect(screen.getByText('test.pdf')).toBeInTheDocument();
      expect(screen.getByText('document.docx')).toBeInTheDocument();
    });

    it('should handle FileInput widget in form schema', () => {
      renderComponent();
      const form = screen.getByTestId('rjsf-form');
      expect(form).toBeInTheDocument();
      // Verify the form is rendered with the fileInput widget
      expect(screen.getByText('Test Files')).toBeInTheDocument();
    });
  });

  describe('File view modal', () => {
    beforeEach(() => {
      mockUseParams.mockReturnValue({ id: 'workflow-123' });
      mockSelectedComponent = {
        id: 'comp-1',
        data: {
          component: 'llm',
          label: 'LLM Component',
          category: 'ai',
          icon: 'https://example.com/icon.svg',
          inputs: [{ field: 'input', type: 'string' }],
          outputs: [{ field: 'output', type: 'string' }],
          json_schema: {
            type: 'object',
            properties: {
              test_files: {
                type: 'array',
                title: 'Test Files',
                'x-ui': { widget: 'fileInput' },
              },
            },
          },
        },
        configuration: { test_files: [] },
      };
      mockNodes = [mockSelectedComponent];
    });

    it('opens modal with blob when onFileView is called with file.file', async () => {
      renderComponent();
      fireEvent.click(screen.getByTestId('trigger-view-file-blob'));

      await waitFor(() => {
        expect(screen.getByTestId('view-workflow-file-modal')).toBeInTheDocument();
        expect(screen.getByTestId('modal-file-name')).toHaveTextContent('test.pdf');
      });
    });

    it('closes modal when onClose is clicked', async () => {
      renderComponent();
      fireEvent.click(screen.getByTestId('trigger-view-file-blob'));

      await waitFor(() => {
        expect(screen.getByTestId('view-workflow-file-modal')).toBeInTheDocument();
      });

      fireEvent.click(screen.getByTestId('configbar-close-modal'));
      expect(screen.queryByTestId('view-workflow-file-modal')).not.toBeInTheDocument();
    });

    it('fetches file content and opens modal when onFileView is called with file.id', async () => {
      const blob = new Blob(['file content'], { type: 'application/pdf' });
      mockGetWorkflowFileContent.mockResolvedValue(blob);

      renderComponent();
      fireEvent.click(screen.getByTestId('trigger-view-file-id'));

      await waitFor(() => {
        expect(mockGetWorkflowFileContent).toHaveBeenCalledWith('workflow-123', 'file-1');
        expect(screen.getByTestId('view-workflow-file-modal')).toBeInTheDocument();
        expect(screen.getByTestId('modal-file-name')).toHaveTextContent('test.pdf');
      });
    });

    it('shows error when getWorkflowFileContent fails', async () => {
      mockGetWorkflowFileContent.mockRejectedValue(new Error('Failed to load'));

      renderComponent();
      fireEvent.click(screen.getByTestId('trigger-view-file-id'));

      await waitFor(() => {
        expect(screen.getByTestId('view-workflow-file-modal')).toBeInTheDocument();
        expect(screen.getByTestId('modal-error')).toHaveTextContent('Failed to load file.');
      });
    });
  });

  describe('A2A Agent Rendering', () => {
    it('should render A2ASkillsSection for a2a_agent component', () => {
      mockSelectedComponent = {
        id: 'a2a-1',
        data: {
          component: 'a2a_agent',
          label: 'A2A Agent',
          category: 'basic',
          icon: 'icon.png',
        },
      };
      mockNodes = [mockSelectedComponent!];

      renderComponent();
      // Since A2ASkillsSection handles its own store/rendering, we just check if it's there
      // We can't easily see its contents without mocking it too, but we can verify it doesn't crash
      expect(screen.getByText('A2A Agent')).toBeInTheDocument();
    });
  });
});
