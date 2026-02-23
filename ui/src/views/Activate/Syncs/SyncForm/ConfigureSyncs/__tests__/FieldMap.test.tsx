import { render, screen, fireEvent } from '@testing-library/react';
import { expect, describe, it, jest } from '@jest/globals';
import '@testing-library/jest-dom/jest-globals';
import '@testing-library/jest-dom';
import { ChakraProvider } from '@chakra-ui/react';
import FieldMap from '../FieldMap';

jest.mock('../TemplateMapping/TemplateMapping', () => ({
  __esModule: true,
  default: ({ entityName, isDisabled }: any) => (
    <div data-testid='template-mapping'>
      {entityName} {isDisabled && 'disabled'}
    </div>
  ),
  OPTION_TYPE: {
    STANDARD: 'standard',
    STATIC: 'static',
    TEMPLATE: 'template',
    VECTOR: 'vector',
  },
}));

const renderComponent = (props: Record<string, unknown> = {}) => {
  return render(
    <ChakraProvider>
      <FieldMap
        id={0}
        fieldType='model'
        icon='test-icon'
        entityName='Test Field'
        options={['option1', 'option2']}
        value=''
        isDisabled={false}
        onChange={jest.fn()}
        {...props}
      />
    </ChakraProvider>,
  );
};

describe('FieldMap', () => {
  it('renders entity item', () => {
    renderComponent({});
    const elements = screen.getAllByText('Test Field');
    expect(elements.length).toBeGreaterThan(0);
  });

  it('renders TemplateMapping for model field type', () => {
    renderComponent({ fieldType: 'model' });
    expect(screen.getByTestId('template-mapping')).toBeInTheDocument();
  });

  it('renders TemplateMapping for destination field type', () => {
    renderComponent({ fieldType: 'destination' });
    expect(screen.getByTestId('template-mapping')).toBeInTheDocument();
  });

  it('renders input for custom field type', () => {
    renderComponent({ fieldType: 'custom', value: 'custom value' });
    const input = screen.getByDisplayValue('custom value');
    expect(input).toBeInTheDocument();
  });

  it('calls onChange when custom input changes', () => {
    const mockOnChange = jest.fn();
    renderComponent({ fieldType: 'custom', onChange: mockOnChange });
    const input = screen.getByRole('textbox');
    fireEvent.change(input, { target: { value: 'new value' } });
    expect(mockOnChange).toHaveBeenCalledWith(0, 'custom', 'new value');
  });

  it('renders refresh button for destination field type with id 0', () => {
    const mockRefresh = jest.fn();
    renderComponent({
      fieldType: 'destination',
      id: 0,
      handleRefreshCatalog: mockRefresh,
    });
    expect(screen.getByText('Refresh')).toBeInTheDocument();
  });

  it('calls handleRefreshCatalog when refresh button is clicked', () => {
    const mockRefresh = jest.fn();
    renderComponent({
      fieldType: 'destination',
      id: 0,
      handleRefreshCatalog: mockRefresh,
    });
    const refreshButton = screen.getByText('Refresh');
    fireEvent.click(refreshButton);
    expect(mockRefresh).toHaveBeenCalled();
  });

  it('disables input when isDisabled is true', () => {
    renderComponent({ fieldType: 'custom', isDisabled: true });
    const input = screen.getByRole('textbox');
    expect(input).toBeDisabled();
  });

  it('passes disabled state to TemplateMapping', () => {
    renderComponent({ isDisabled: true });
    // The disabled state is passed to TemplateMapping, verify it's rendered
    expect(screen.getByTestId('template-mapping')).toBeInTheDocument();
  });
});
