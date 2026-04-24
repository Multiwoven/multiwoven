import { render, screen, fireEvent } from '@testing-library/react';
import { expect } from '@jest/globals';
import '@testing-library/jest-dom/jest-globals';
import '@testing-library/jest-dom';
import { ChakraProvider } from '@chakra-ui/react';
import InputField from '../InputField';

const renderInputField = (props = {}) => {
  return render(
    <ChakraProvider>
      <InputField label='Test Label' name='testName' value='' onChange={() => {}} {...props} />
    </ChakraProvider>,
  );
};

describe('InputField', () => {
  const mockOnChange = jest.fn();

  beforeEach(() => {
    jest.clearAllMocks();
  });

  it('should render label', () => {
    renderInputField({ label: 'Test Label' });
    expect(screen.getByText('Test Label')).toBeInTheDocument();
  });

  it('should render input field', () => {
    renderInputField();
    expect(screen.getByTestId('input-field')).toBeInTheDocument();
  });

  it('should use custom testId when provided', () => {
    renderInputField({ testId: 'settings-api-key-input' });
    expect(screen.getByTestId('settings-api-key-input')).toBeInTheDocument();
    expect(screen.queryByTestId('input-field')).not.toBeInTheDocument();
  });

  it('should render input with correct name attribute', () => {
    renderInputField({ name: 'testName' });
    const input = screen.getByTestId('input-field');
    expect(input).toHaveAttribute('name', 'testName');
  });

  it('should render input with correct value', () => {
    renderInputField({ value: 'test value' });
    const input = screen.getByTestId('input-field') as HTMLInputElement;
    expect(input.value).toBe('test value');
  });

  it('should call onChange when input value changes', () => {
    renderInputField({ onChange: mockOnChange });
    const input = screen.getByTestId('input-field');
    fireEvent.change(input, { target: { value: 'new value' } });
    expect(mockOnChange).toHaveBeenCalledTimes(1);
  });

  it('should render placeholder', () => {
    renderInputField({ placeholder: 'Enter text here' });
    const input = screen.getByTestId('input-field');
    expect(input).toHaveAttribute('placeholder', 'Enter text here');
  });

  it('should render helper text when provided', () => {
    renderInputField({ helperText: 'This is helper text' });
    expect(screen.getByText('This is helper text')).toBeInTheDocument();
  });

  it('should not render helper text when not provided', () => {
    renderInputField();
    expect(screen.queryByText('This is helper text')).not.toBeInTheDocument();
  });

  it('should not render tooltip when isTooltip is false', () => {
    renderInputField({ isTooltip: false });
    // Tooltip icon should not be visible
    const tooltipIcon = screen.queryByRole('img', { hidden: true });
    // The FiInfo icon might still render but tooltip won't show
    expect(tooltipIcon).not.toBeInTheDocument();
  });

  it('should render disabled input when disabled is true', () => {
    renderInputField({ disabled: true });
    const input = screen.getByTestId('input-field');
    expect(input).toBeDisabled();
  });

  it('should render enabled input when disabled is false', () => {
    renderInputField({ disabled: false });
    const input = screen.getByTestId('input-field');
    expect(input).not.toBeDisabled();
  });

  it('should render text input type by default', () => {
    renderInputField();
    const input = screen.getByTestId('input-field');
    expect(input).toHaveAttribute('type', 'text');
  });

  it('should render password input type', () => {
    renderInputField({ type: 'password' });
    const input = screen.getByTestId('input-field');
    expect(input).toHaveAttribute('type', 'password');
  });

  it('should render number input type', () => {
    renderInputField({ type: 'number' });
    const input = screen.getByTestId('input-field');
    expect(input).toHaveAttribute('type', 'number');
  });

  it('should render input with id when provided', () => {
    renderInputField({ id: 'test-id' });
    const input = screen.getByTestId('input-field');
    expect(input).toHaveAttribute('id', 'test-id');
  });

  it('should render input as required', () => {
    renderInputField();
    const input = screen.getByTestId('input-field');
    expect(input).toBeRequired();
  });
});
