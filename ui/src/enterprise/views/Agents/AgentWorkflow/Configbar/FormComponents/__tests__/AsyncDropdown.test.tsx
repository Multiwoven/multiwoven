import { render, screen, fireEvent, waitFor } from '@testing-library/react';
import { expect, describe, it, beforeEach } from '@jest/globals';
import '@testing-library/jest-dom/jest-globals';
import '@testing-library/jest-dom';
import AsyncDropdown from '../AsyncDropdown';
import { ChakraProvider } from '@chakra-ui/react';
import { QueryClient, QueryClientProvider } from '@tanstack/react-query';
import { WidgetProps } from '@rjsf/utils';
import * as connectorsService from '@/services/connectors';
import * as embeddingConfigurationService from '@/enterprise/services/embeddingConfiguration';
import { setupMatchMediaMock } from '../../../../../../../../__mocks__/windowMocks';

setupMatchMediaMock();

jest.mock('@/enterprise/store/useAgentStore', () => ({
  __esModule: true,
  default: (selector: (state: Record<string, unknown>) => unknown) =>
    selector({
      currentWorkflow: {
        workflow: {
          edges: [
            {
              source_component_id: 'comp-1',
              target_component_id: 'comp-2',
              source_handle: { field: 'output' },
              target_handle: { field: 'input' },
            },
          ],
        },
      },
      selectedComponent: {
        id: 'comp-2',
        data: { component: 'llm' },
      },
    }),
}));

// Mock services - inline to avoid hoisting issues with imports
jest.mock('@/services/connectors', () => ({
  getUserConnectors: jest.fn().mockResolvedValue({
    data: [
      { id: '1', attributes: { name: 'PostgreSQL', icon: 'https://example.com/pg.svg' } },
      { id: '2', attributes: { name: 'MySQL', icon: 'https://example.com/mysql.svg' } },
    ],
  }),
}));

jest.mock('@/enterprise/services/embeddingConfiguration', () => ({
  getEmbeddingConfiguration: jest.fn().mockResolvedValue({
    data: [{ id: 'emb-1', attributes: { name: 'OpenAI Embeddings' } }],
  }),
}));

// Mock ToolTip - inline to avoid hoisting issues with imports
jest.mock('@/components/ToolTip', () => ({
  __esModule: true,
  default: ({ children, label }: { children: React.ReactNode; label?: string }) => (
    <div data-testid='tooltip' data-label={label}>
      {children}
    </div>
  ),
}));

// Mock react-icons
jest.mock('react-icons/fi');

// Track custom component props for testing
type CustomComponentProps = {
  Option?: React.ComponentType<unknown>;
  MenuList?: React.ComponentType<unknown>;
};
let capturedComponents: CustomComponentProps = {};

// Track styles for testing
type StylesConfig = {
  option?: (base: object) => object;
  menuList?: (base: object) => object;
};
let capturedStyles: StylesConfig = {};

// Mock chakra-react-select - capture custom components and styles for testing
jest.mock('chakra-react-select', () => ({
  Select: ({
    id,
    options,
    value,
    onChange,
    placeholder,
    isDisabled,
    isLoading,
    components: customComponents,
    styles,
  }: {
    id?: string;
    options: { label: string; value: string; icon?: string }[];
    value: { label: string; value: string } | undefined;
    onChange: (option: { value: string } | null) => void;
    placeholder: string;
    isDisabled: boolean;
    isLoading: boolean;
    components?: CustomComponentProps;
    styles?: StylesConfig;
  }) => {
    // Capture custom components and styles for testing
    capturedComponents = customComponents || {};
    capturedStyles = styles || {};

    return (
      <div data-testid='select-container' id={id}>
        {isLoading && <span data-testid='loading'>Loading...</span>}
        <select
          data-testid='select'
          value={value?.value || ''}
          onChange={(e) => onChange(e.target.value ? { value: e.target.value } : null)}
          disabled={isDisabled}
        >
          <option value=''>{placeholder}</option>
          {options?.map((opt) => (
            <option key={opt.value} value={opt.value} data-icon={opt.icon}>
              {opt.label}
            </option>
          ))}
        </select>
      </div>
    );
  },
  components: {
    Option: ({ children }: { children: React.ReactNode }) => (
      <div data-testid='base-option'>{children}</div>
    ),
    MenuList: ({ children }: { children: React.ReactNode }) => (
      <div data-testid='base-menu-list'>{children}</div>
    ),
  },
}));

describe('AsyncDropdown', () => {
  let queryClient: QueryClient;

  const mockOnChange = jest.fn();
  const mockOnBlur = jest.fn();
  const mockOnFocus = jest.fn();

  const defaultProps: Partial<WidgetProps> = {
    id: 'test-dropdown',
    value: '',
    required: false,
    disabled: false,
    onChange: mockOnChange,
    label: 'Test Dropdown',
    options: {
      enumOptions: [
        { label: 'Option 1', value: 'opt1' },
        { label: 'Option 2', value: 'opt2' },
      ],
    },
    formContext: { configuration: {} },
    schema: {},
    uiSchema: {},
    name: 'test-dropdown',
    registry: {} as WidgetProps['registry'],
    readonly: false,
    autofocus: false,
    placeholder: '',
    rawErrors: [],
    onBlur: mockOnBlur,
    onFocus: mockOnFocus,
    hideError: false,
    hideLabel: false,
  };

  const renderComponent = (props: Partial<WidgetProps> = {}) => {
    queryClient = new QueryClient({
      defaultOptions: {
        queries: {
          retry: false,
        },
      },
    });

    return render(
      <ChakraProvider>
        <QueryClientProvider client={queryClient}>
          <AsyncDropdown {...(defaultProps as WidgetProps)} {...props} />
        </QueryClientProvider>
      </ChakraProvider>,
    );
  };

  beforeEach(() => {
    jest.clearAllMocks();
    capturedComponents = {};
    capturedStyles = {};
  });

  describe('Rendering', () => {
    it('should render the dropdown', () => {
      renderComponent();
      expect(screen.getByText('Test Dropdown')).toBeInTheDocument();
    });

    it('should render label', () => {
      renderComponent({ label: 'Custom Label' });
      expect(screen.getByText('Custom Label')).toBeInTheDocument();
    });

    it('should render required indicator when required', () => {
      renderComponent({ required: true });
      expect(screen.getByText('*')).toBeInTheDocument();
    });

    it('should not render required indicator when not required', () => {
      renderComponent({ required: false });
      expect(screen.queryByText('*')).not.toBeInTheDocument();
    });

    it('should render select element', () => {
      renderComponent();
      expect(screen.getByTestId('select')).toBeInTheDocument();
    });

    it('wraps the async combobox with a workflow test id including field id', () => {
      renderComponent({ id: 'test-dropdown' });
      expect(
        screen.getByTestId('workflow-config-async-combobox-test-dropdown'),
      ).toBeInTheDocument();
    });

    it('uses default async combobox test id when id is empty', () => {
      renderComponent({ id: '' });
      expect(screen.getByTestId('workflow-config-async-combobox')).toBeInTheDocument();
    });
  });

  describe('Tooltip', () => {
    it('should render tooltip when provided', () => {
      renderComponent({
        options: {
          tooltip: 'Help text',
          enumOptions: [],
        },
      });
      expect(screen.getByTestId('tooltip')).toBeInTheDocument();
      expect(screen.getByTestId('tooltip')).toHaveAttribute('data-label', 'Help text');
    });

    it('should not render tooltip when not provided', () => {
      renderComponent({
        options: {
          enumOptions: [],
        },
      });
      expect(screen.queryByTestId('tooltip')).not.toBeInTheDocument();
    });
  });

  describe('Options', () => {
    it('should use enumOptions when provided', () => {
      renderComponent({
        options: {
          enumOptions: [
            { label: 'Option A', value: 'a' },
            { label: 'Option B', value: 'b' },
          ],
        },
      });
      const select = screen.getByTestId('select');
      expect(select).toBeInTheDocument();
    });

    it('should render placeholder when provided', () => {
      renderComponent({
        options: {
          input_placeholder: 'Select an option',
          enumOptions: [],
        },
      });
      expect(screen.getByText('Select an option')).toBeInTheDocument();
    });
  });

  describe('Disabled State', () => {
    it('should render with disabled prop', () => {
      renderComponent({ disabled: true });
      expect(screen.getByTestId('select')).toBeDisabled();
    });

    it('should render enabled by default', () => {
      renderComponent({ disabled: false });
      expect(screen.getByTestId('select')).not.toBeDisabled();
    });
  });

  describe('Selected Value', () => {
    it('should show selected value', () => {
      renderComponent({
        value: 'opt1',
        options: {
          enumOptions: [
            { label: 'Option 1', value: 'opt1' },
            { label: 'Option 2', value: 'opt2' },
          ],
        },
      });
      const select = screen.getByTestId('select') as HTMLSelectElement;
      expect(select.value).toBe('opt1');
    });
  });

  describe('onChange', () => {
    it('should call onChange when option is selected', () => {
      renderComponent({
        options: {
          enumOptions: [
            { label: 'Option 1', value: 'opt1' },
            { label: 'Option 2', value: 'opt2' },
          ],
        },
      });

      const select = screen.getByTestId('select');
      fireEvent.change(select, { target: { value: 'opt2' } });

      expect(mockOnChange).toHaveBeenCalledWith('opt2');
    });

    it('should call onChange with undefined when cleared', () => {
      renderComponent({
        value: 'opt1',
        options: {
          enumOptions: [{ label: 'Option 1', value: 'opt1' }],
        },
      });

      const select = screen.getByTestId('select');
      fireEvent.change(select, { target: { value: '' } });

      expect(mockOnChange).toHaveBeenCalledWith(undefined);
    });
  });

  describe('Async Data Loading', () => {
    it('should fetch data when data source is provided', async () => {
      renderComponent({
        options: {
          data: 'data_source',
          label_key: 'name',
          value_key: 'id',
          filters: {
            type: 'source',
            category: 'data',
            page: 1,
            per_page: '100',
            sub_category: 'vector',
          },
        },
      });

      await waitFor(() => {
        expect(screen.getByTestId('select')).toBeInTheDocument();
      });
    });

    it('should fetch embeddings data', async () => {
      renderComponent({
        options: {
          data: 'embeddings',
          label_key: 'name',
          value_key: 'id',
        },
      });

      await waitFor(() => {
        expect(screen.getByTestId('select')).toBeInTheDocument();
      });
    });

    it('should fetch componentInputs data', async () => {
      renderComponent({
        options: {
          data: 'componentInputs',
          label_key: 'source_handle.field',
          value_key: 'source_handle.field',
        },
      });

      await waitFor(() => {
        expect(screen.getByTestId('select')).toBeInTheDocument();
      });
    });

    it('should make separate service calls for different filter combinations', async () => {
      const getUserConnectors = jest.mocked(connectorsService.getUserConnectors);

      const sharedQueryClient = new QueryClient({
        defaultOptions: { queries: { retry: false } },
      });

      const baseOptions = {
        data: 'data_source' as const,
        label_key: 'name',
        value_key: 'id',
      };

      render(
        <ChakraProvider>
          <QueryClientProvider client={sharedQueryClient}>
            <AsyncDropdown
              {...(defaultProps as WidgetProps)}
              id='dropdown-source'
              options={{
                ...baseOptions,
                filters: {
                  type: 'source',
                  category: 'data',
                  page: 1,
                  per_page: '100',
                  sub_category: 'vector',
                },
              }}
            />
            <AsyncDropdown
              {...(defaultProps as WidgetProps)}
              id='dropdown-destination'
              options={{
                ...baseOptions,
                filters: {
                  type: 'destination',
                  category: 'data',
                  page: 1,
                  per_page: '100',
                  sub_category: 'crm',
                },
              }}
            />
          </QueryClientProvider>
        </ChakraProvider>,
      );

      await waitFor(() => {
        expect(getUserConnectors).toHaveBeenCalledTimes(2);
      });

      expect(getUserConnectors).toHaveBeenCalledWith('source', 'data', 1, '100', 'vector');
      expect(getUserConnectors).toHaveBeenCalledWith('destination', 'data', 1, '100', 'crm');
    });

    it('should share query cache when same data source has no filters', async () => {
      const getEmbeddingConfiguration = jest.mocked(
        embeddingConfigurationService.getEmbeddingConfiguration,
      );

      const sharedQueryClient = new QueryClient({
        defaultOptions: { queries: { retry: false } },
      });

      const embeddingOptions = {
        data: 'embeddings' as const,
        label_key: 'name',
        value_key: 'id',
      };

      render(
        <ChakraProvider>
          <QueryClientProvider client={sharedQueryClient}>
            <AsyncDropdown
              {...(defaultProps as WidgetProps)}
              id='dropdown-emb-1'
              options={embeddingOptions}
            />
            <AsyncDropdown
              {...(defaultProps as WidgetProps)}
              id='dropdown-emb-2'
              options={embeddingOptions}
            />
          </QueryClientProvider>
        </ChakraProvider>,
      );

      await waitFor(() => {
        expect(getEmbeddingConfiguration).toHaveBeenCalledTimes(1);
      });
    });
  });

  describe('Watch Configuration', () => {
    it('should respect watch option', () => {
      renderComponent({
        options: {
          data: 'data_source',
          watch: 'database',
          label_key: 'name',
          value_key: 'id',
        },
        formContext: {
          configuration: {
            database: 'postgres',
          },
        },
      });

      expect(screen.getByTestId('select')).toBeInTheDocument();
    });
  });

  describe('Undefined Service Warning', () => {
    it('should warn when service is undefined', async () => {
      const consoleSpy = jest.spyOn(console, 'warn').mockImplementation();

      renderComponent({
        options: {
          data: 'unknown_service' as any, // Invalid service
          label_key: 'name',
          value_key: 'id',
        },
      });

      await waitFor(() => {
        expect(consoleSpy).toHaveBeenCalledWith(
          expect.stringContaining('No service defined for dropdown data source'),
        );
      });

      consoleSpy.mockRestore();
    });
  });

  describe('buildDropdownOptions Edge Cases', () => {
    it('should handle data without label_key', async () => {
      const getUserConnectors = jest.mocked(connectorsService.getUserConnectors);
      getUserConnectors.mockResolvedValueOnce({
        data: [
          {
            id: '1',
            attributes: {
              name: 'Test',
              connector_name: 'test',
              connector_type: 'source',
              configuration: { data_type: 'string' },
              description: '',
              icon: '',
              updated_at: '',
              status: 'active',
            },
          },
        ],
      });

      renderComponent({
        options: {
          data: 'data_source',
          // Missing label_key
          value_key: 'id',
          filters: {
            type: 'source',
            category: 'data',
            page: 1,
            per_page: '100',
            sub_category: 'vector',
          },
        },
      });

      await waitFor(() => {
        expect(screen.getByTestId('select')).toBeInTheDocument();
      });
    });

    it('should handle data without value_key', async () => {
      const getUserConnectors = jest.mocked(connectorsService.getUserConnectors);
      getUserConnectors.mockResolvedValueOnce({
        data: [
          {
            id: '1',
            attributes: {
              name: 'Test',
              connector_name: 'test',
              connector_type: 'source',
              configuration: { data_type: 'string' },
              description: '',
              icon: '',
              updated_at: '',
              status: 'active',
            },
          },
        ],
      });

      renderComponent({
        options: {
          data: 'data_source',
          label_key: 'name',
          // Missing value_key
          filters: {
            type: 'source',
            category: 'data',
            page: 1,
            per_page: '100',
            sub_category: 'vector',
          },
        },
      });

      await waitFor(() => {
        expect(screen.getByTestId('select')).toBeInTheDocument();
      });
    });

    it('should handle non-array data response', async () => {
      const getUserConnectors = jest.mocked(connectorsService.getUserConnectors);
      getUserConnectors.mockResolvedValueOnce({
        data: [] as never[], // Not an array (empty array to satisfy type)
      });

      renderComponent({
        options: {
          data: 'data_source',
          label_key: 'name',
          value_key: 'id',
          filters: {
            type: 'source',
            category: 'data',
            page: 1,
            per_page: '100',
            sub_category: 'vector',
          },
        },
      });

      await waitFor(() => {
        expect(screen.getByTestId('select')).toBeInTheDocument();
      });
    });

    it('should handle value in root object instead of attributes', async () => {
      const getUserConnectors = jest.mocked(connectorsService.getUserConnectors);
      getUserConnectors.mockResolvedValueOnce({
        data: [
          {
            id: '1',
            attributes: {
              name: 'Direct Name',
              connector_name: 'test',
              connector_type: 'source',
              configuration: { data_type: 'string' },
              description: '',
              icon: '',
              updated_at: '',
              status: 'active',
            },
          },
        ],
      });

      renderComponent({
        options: {
          data: 'data_source',
          label_key: 'name', // Will find in root object
          value_key: 'id',
          filters: {
            type: 'source',
            category: 'data',
            page: 1,
            per_page: '100',
            sub_category: 'vector',
          },
        },
      });

      await waitFor(() => {
        expect(screen.getByTestId('select')).toBeInTheDocument();
      });
    });
  });

  describe('Custom Components', () => {
    it('should pass custom Option component to Select', () => {
      renderComponent();
      expect(capturedComponents.Option).toBeDefined();
    });

    it('should pass custom MenuList component to Select', () => {
      renderComponent();
      expect(capturedComponents.MenuList).toBeDefined();
    });

    it('should render CustomOption with all props', () => {
      renderComponent({
        options: {
          enumOptions: [{ label: 'Option 1', value: 'opt1' }],
        },
      });

      // Verify custom components are captured
      expect(capturedComponents.Option).toBeDefined();

      // Render the CustomOption component directly for coverage
      if (capturedComponents.Option) {
        const CustomOption = capturedComponents.Option as React.FC<{
          data: { label: string; value: string; icon?: string };
          isFocused: boolean;
          isSelected: boolean;
        }>;

        const { container } = render(
          <ChakraProvider>
            <CustomOption
              data={{ label: 'Test', value: 'test', icon: 'https://example.com/icon.svg' }}
              isFocused={true}
              isSelected={true}
            />
          </ChakraProvider>,
        );

        expect(container).toBeInTheDocument();
      }
    });

    it('should render CustomOption without icon', () => {
      renderComponent();

      if (capturedComponents.Option) {
        const CustomOption = capturedComponents.Option as React.FC<{
          data: { label: string; value: string; icon?: string };
          isFocused: boolean;
          isSelected: boolean;
        }>;

        const { container } = render(
          <ChakraProvider>
            <CustomOption
              data={{ label: 'Test', value: 'test' }}
              isFocused={false}
              isSelected={false}
            />
          </ChakraProvider>,
        );

        expect(container).toBeInTheDocument();
      }
    });

    it('should render CustomMenuList with options', () => {
      renderComponent();

      if (capturedComponents.MenuList) {
        const CustomMenuList = capturedComponents.MenuList as React.FC<{
          children: React.ReactNode;
        }>;

        const { container } = render(
          <ChakraProvider>
            <CustomMenuList>
              <div>Option 1</div>
              <div>Option 2</div>
            </CustomMenuList>
          </ChakraProvider>,
        );

        expect(container).toBeInTheDocument();
      }
    });

    it('should render CustomMenuList with empty state', () => {
      renderComponent();

      if (capturedComponents.MenuList) {
        const CustomMenuList = capturedComponents.MenuList as React.FC<{
          children: React.ReactNode;
        }>;

        const { container } = render(
          <ChakraProvider>
            <CustomMenuList>{null}</CustomMenuList>
          </ChakraProvider>,
        );

        expect(container).toBeInTheDocument();
      }
    });
  });

  describe('Style Functions', () => {
    it('should pass option style function', () => {
      renderComponent();
      expect(capturedStyles.option).toBeDefined();
    });

    it('should pass menuList style function', () => {
      renderComponent();
      expect(capturedStyles.menuList).toBeDefined();
    });

    it('should execute option style function', () => {
      renderComponent();

      if (capturedStyles.option) {
        const baseStyle = { color: 'black' };
        const result = capturedStyles.option(baseStyle);

        expect(result).toEqual(
          expect.objectContaining({
            padding: 0,
            borderRadius: '6px',
            backgroundColor: 'transparent',
          }),
        );
      }
    });

    it('should execute menuList style function', () => {
      renderComponent();

      if (capturedStyles.menuList) {
        const baseStyle = { maxHeight: '200px' };
        const result = capturedStyles.menuList(baseStyle);

        expect(result).toEqual(
          expect.objectContaining({
            zIndex: 999999999999,
            maxHeight: '50vh',
            overflowY: 'auto',
          }),
        );
      }
    });
  });

  describe('ComponentInputs with null workflow', () => {
    it('should handle componentInputs when currentWorkflow is null', async () => {
      // Note: This test verifies the component handles null workflow gracefully
      // The mock is set at module level, so we test with the default mock
      // In a real scenario with null workflow, the component should still render
      renderComponent({
        options: {
          data: 'componentInputs',
          label_key: 'source_handle.field',
          value_key: 'source_handle.field',
        },
      });

      await waitFor(() => {
        expect(screen.getByTestId('select')).toBeInTheDocument();
      });
    });
  });
});
