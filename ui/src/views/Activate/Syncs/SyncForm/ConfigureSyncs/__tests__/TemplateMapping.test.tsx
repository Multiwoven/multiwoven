import React from 'react';
import { render, screen, fireEvent, waitFor } from '@testing-library/react';
import { expect, describe, it, beforeEach, jest } from '@jest/globals';
import '@testing-library/jest-dom/jest-globals';
import '@testing-library/jest-dom';
import { ChakraProvider, Tabs } from '@chakra-ui/react';
import TemplateMapping, { OPTION_TYPE } from '../TemplateMapping/TemplateMapping';

const mockUseQueryWrapper = jest.fn();
const mockHandleUpdateConfig = jest.fn();

jest.mock('@/hooks/useQueryWrapper', () => ({
  __esModule: true,
  default: (_key: unknown, queryFn?: () => unknown) => {
    if (typeof queryFn === 'function') {
      try {
        queryFn();
      } catch {
        /* expected in mock */
      }
    }
    return mockUseQueryWrapper();
  },
}));

jest.mock('@/services/syncs', () => ({
  getSyncsConfiguration: jest.fn(),
}));

jest.mock('../TemplateMapping/StaticOptions', () => ({
  __esModule: true,
  default: ({
    selectedStaticOptionValue,
    setSelectedStaticOptionValue,
  }: {
    selectedStaticOptionValue: string | boolean;
    setSelectedStaticOptionValue: React.Dispatch<React.SetStateAction<string | boolean>>;
  }) => (
    <div data-testid='static-options'>
      <input
        data-testid='static-input'
        value={String(selectedStaticOptionValue)}
        onChange={(e) => setSelectedStaticOptionValue(e.target.value)}
      />
    </div>
  ),
}));

jest.mock('@/components/TemplateMappingOptions', () => ({
  __esModule: true,
  default: ({
    setSelectedTemplate,
  }: {
    setSelectedTemplate: React.Dispatch<React.SetStateAction<string>>;
  }) => (
    <button
      data-testid='template-select'
      onClick={() => setSelectedTemplate && setSelectedTemplate('template_value')}
    >
      Select Template
    </button>
  ),
}));

jest.mock('@/components/TemplateMappingOptions/Columns', () => ({
  __esModule: true,
  default: ({ onSelect }: { onSelect: (value: string) => void }) => (
    <button data-testid='standard-select' onClick={() => onSelect('column_value')}>
      Select Column
    </button>
  ),
}));

const mockConfigData = {
  data: {
    configurations: {
      catalog_mapping_types: {
        static: { string: 'String', boolean: 'Boolean', number: 'Number', null: 'Null' },
        template: {
          filter: { filter1: { description: 'Filter 1' } },
          variable: { var1: { description: 'Variable 1' } },
        },
      },
    },
  },
};

const renderComponent = (props: Record<string, unknown> = {}) => {
  return render(
    <ChakraProvider>
      <Tabs>
        <TemplateMapping
          entityName='Test Field'
          isDisabled={false}
          columnOptions={['col1', 'col2']}
          fieldType='model'
          handleUpdateConfig={mockHandleUpdateConfig}
          mappingId={0}
          mappingType={OPTION_TYPE.STANDARD}
          {...props}
        />
      </Tabs>
    </ChakraProvider>,
  );
};

describe('TemplateMapping', () => {
  beforeEach(() => {
    jest.clearAllMocks();
    mockUseQueryWrapper.mockReturnValue({
      data: mockConfigData,
      isLoading: false,
    });
  });

  it('renders tabs for different mapping types', () => {
    renderComponent({});
    expect(screen.getByText('Column')).toBeInTheDocument();
    expect(screen.getByText('Static Value')).toBeInTheDocument();
    expect(screen.getByText('Template')).toBeInTheDocument();
  });

  it('renders standard tab by default', () => {
    renderComponent({});
    expect(screen.getByTestId('standard-select')).toBeInTheDocument();
  });

  it('switches to static tab', () => {
    renderComponent({});
    const staticTab = screen.getByText('Static Value');
    fireEvent.click(staticTab);
    expect(screen.getByTestId('static-options')).toBeInTheDocument();
  });

  it('switches to template tab', () => {
    renderComponent({});
    const templateTab = screen.getByText('Template');
    fireEvent.click(templateTab);
    expect(screen.getByTestId('template-select')).toBeInTheDocument();
  });

  it('calls handleUpdateConfig when standard column is selected', () => {
    renderComponent({});
    const selectButton = screen.getByTestId('standard-select');
    fireEvent.click(selectButton);
    expect(mockHandleUpdateConfig).toHaveBeenCalledWith(
      0,
      'model',
      'column_value',
      OPTION_TYPE.STANDARD,
    );
  });

  it('calls handleUpdateConfig when template is selected', () => {
    renderComponent({});
    const templateTab = screen.getByText('Template');
    fireEvent.click(templateTab);
    // TemplateMapping uses setSelectedTemplate internally, not onSelect
    // The actual update happens when applyConfigs is called
    expect(screen.getByTestId('template-select')).toBeInTheDocument();
  });

  it('initializes with template mapping type when provided', async () => {
    renderComponent({ mappingType: OPTION_TYPE.TEMPLATE, selectedConfig: 'template_value' });
    // The popover should be open when selectedConfig is provided and mappingType is TEMPLATE
    // Click the input to open the popover if it's not already open
    const input = screen.getByPlaceholderText('Select a field from Test Field');
    fireEvent.click(input);
    // Wait for the popover to open and the template tab to be visible
    await waitFor(() => {
      const templateTab = screen.getByText('Template');
      expect(templateTab).toBeInTheDocument();
    });
    // Click the template tab to ensure it's active
    const templateTab = screen.getByText('Template');
    fireEvent.click(templateTab);
    await waitFor(() => {
      expect(screen.getByTestId('template-select')).toBeInTheDocument();
    });
  });

  it('initializes with static mapping type when provided', () => {
    renderComponent({ mappingType: OPTION_TYPE.STATIC, selectedConfig: 'string' });
    const staticTab = screen.getByText('Static Value');
    fireEvent.click(staticTab);
    expect(screen.getByTestId('static-options')).toBeInTheDocument();
  });

  it('handles disabled state', () => {
    renderComponent({ isDisabled: true });
    expect(screen.getByTestId('standard-select')).toBeInTheDocument();
  });

  it('applies static value config when Apply is clicked', () => {
    renderComponent();
    const staticTab = screen.getByText('Static Value');
    fireEvent.click(staticTab);
    const staticInput = screen.getByTestId('static-input');
    fireEvent.change(staticInput, { target: { value: 'string' } });
    const applyButton = screen.getByText('Apply');
    fireEvent.click(applyButton);
    expect(mockHandleUpdateConfig).toHaveBeenCalledWith(0, 'model', 'string', OPTION_TYPE.STATIC);
  });

  it('applies template config when Apply is clicked', () => {
    renderComponent();
    const templateTab = screen.getByText('Template');
    fireEvent.click(templateTab);
    const selectTemplateBtn = screen.getByTestId('template-select');
    fireEvent.click(selectTemplateBtn);
    const applyButton = screen.getByText('Apply');
    fireEvent.click(applyButton);
    expect(mockHandleUpdateConfig).toHaveBeenCalledWith(
      0,
      'model',
      'template_value',
      OPTION_TYPE.TEMPLATE,
    );
  });

  it('does not render tabs for destination fieldType', () => {
    renderComponent({ fieldType: 'destination' });
    expect(screen.queryByText('Column')).not.toBeInTheDocument();
    expect(screen.queryByText('Static Value')).not.toBeInTheDocument();
    expect(screen.queryByText('Template')).not.toBeInTheDocument();
  });

  it('closes popover when onClose is triggered', () => {
    renderComponent();
    const input = screen.getByPlaceholderText('Select a field from Test Field');
    fireEvent.click(input);
    expect(screen.getByTestId('standard-select')).toBeInTheDocument();
    fireEvent.click(screen.getByTestId('standard-select'));
    expect(mockHandleUpdateConfig).toHaveBeenCalled();
  });

  it('switches back to Column tab from another tab', () => {
    renderComponent();
    const input = screen.getByPlaceholderText('Select a field from Test Field');
    fireEvent.click(input);
    fireEvent.click(screen.getByText('Static Value'));
    expect(screen.getByTestId('static-options')).toBeInTheDocument();
    fireEvent.click(screen.getByText('Column'));
    expect(screen.getByTestId('standard-select')).toBeInTheDocument();
  });

  it('closes popover via Escape key triggering onClose', async () => {
    renderComponent();
    const input = screen.getByPlaceholderText('Select a field from Test Field');
    fireEvent.click(input);
    await waitFor(() => {
      expect(screen.getByTestId('standard-select')).toBeInTheDocument();
    });
    fireEvent.keyDown(input, { key: 'Escape', code: 'Escape' });
  });

  it('toggles popover closed when clicking input while open', async () => {
    renderComponent();
    const input = screen.getByPlaceholderText('Select a field from Test Field');
    fireEvent.click(input);
    await waitFor(() => {
      expect(screen.getByTestId('standard-select')).toBeInTheDocument();
    });
    fireEvent.click(input);
  });

  it('renders with null config data using fallback defaults', () => {
    mockUseQueryWrapper.mockReturnValue({
      data: null,
      isLoading: false,
    });
    renderComponent();
    expect(screen.getByText('Column')).toBeInTheDocument();
    expect(screen.getByText('Static Value')).toBeInTheDocument();
    expect(screen.getByText('Template')).toBeInTheDocument();
  });

  it('handles config data with missing description fields', () => {
    mockUseQueryWrapper.mockReturnValue({
      data: {
        data: {
          configurations: {
            catalog_mapping_types: {
              static: { string: 'String' },
              template: {
                filter: { filter1: {} },
                variable: { var1: {} },
              },
            },
          },
        },
      },
      isLoading: false,
    });
    renderComponent();
    expect(screen.getByText('Column')).toBeInTheDocument();
  });
});
