import { render, screen, fireEvent } from '@testing-library/react';
import { expect } from '@jest/globals';
import '@testing-library/jest-dom/jest-globals';
import '@testing-library/jest-dom';
import { ChakraProvider } from '@chakra-ui/react';
import HiddenInput from '../HiddenInput';

const renderHiddenInput = (props = {}) => {
  return render(
    <ChakraProvider>
      <HiddenInput {...props} />
    </ChakraProvider>,
  );
};

describe('HiddenInput', () => {
  const mockOnChange = jest.fn();

  beforeEach(() => {
    jest.clearAllMocks();
  });

  it('should render input field', () => {
    renderHiddenInput();
    expect(screen.getByTestId('hidden-input-field')).toBeInTheDocument();
  });

  it('should render label when provided', () => {
    renderHiddenInput({ label: 'Password' });
    expect(screen.getByText('Password')).toBeInTheDocument();
  });

  it('should render required asterisk when isRequired is true', () => {
    renderHiddenInput({ label: 'API Key', isRequired: true });
    expect(screen.getByText('*')).toBeInTheDocument();
  });

  it('should not render required asterisk when isRequired is omitted', () => {
    renderHiddenInput({ label: 'API Key' });
    expect(screen.queryByText('*')).not.toBeInTheDocument();
  });

  it('should apply custom data-testid from props over the default', () => {
    renderHiddenInput({ 'data-testid': 'embedding-api-key-input' });
    expect(screen.getByTestId('embedding-api-key-input')).toBeInTheDocument();
    expect(screen.queryByTestId('hidden-input-field')).not.toBeInTheDocument();
  });

  it('should not forward label onto the input element', () => {
    renderHiddenInput({ label: 'Secret' });
    const input = screen.getByTestId('hidden-input-field');
    expect(input).not.toHaveAttribute('label');
  });

  it('should render password input type by default', () => {
    renderHiddenInput();
    const input = screen.getByTestId('hidden-input-field');
    expect(input).toHaveAttribute('type', 'password');
  });

  it('should toggle to text type when reveal button is clicked', () => {
    renderHiddenInput();
    const input = screen.getByTestId('hidden-input-field');
    const revealButton = screen.getByRole('button', { name: /reveal password/i });

    expect(input).toHaveAttribute('type', 'password');
    fireEvent.click(revealButton);
    expect(input).toHaveAttribute('type', 'text');
  });

  it('should toggle back to password type when mask button is clicked', () => {
    renderHiddenInput();
    const input = screen.getByTestId('hidden-input-field');
    const revealButton = screen.getByRole('button', { name: /reveal password/i });

    // First click to reveal
    fireEvent.click(revealButton);
    expect(input).toHaveAttribute('type', 'text');

    // Second click to mask
    const maskButton = screen.getByRole('button', { name: /mask password/i });
    fireEvent.click(maskButton);
    expect(input).toHaveAttribute('type', 'password');
  });

  it('should change aria-label when visibility toggles', () => {
    renderHiddenInput();
    const revealButton = screen.getByRole('button', { name: /reveal password/i });
    expect(revealButton).toHaveAttribute('aria-label', 'Reveal password');

    fireEvent.click(revealButton);
    const maskButton = screen.getByRole('button', { name: /mask password/i });
    expect(maskButton).toHaveAttribute('aria-label', 'Mask password');
  });

  it('should render disabled input when disabled is true', () => {
    renderHiddenInput({ isDisabled: true });
    const input = screen.getByTestId('hidden-input-field');
    expect(input).toBeDisabled();
  });

  it('should disable reveal button when input is disabled', () => {
    renderHiddenInput({ isDisabled: true });
    const revealButton = screen.getByRole('button');
    expect(revealButton).toBeDisabled();
  });

  it('should call onChange when input value changes', () => {
    renderHiddenInput({ onChange: mockOnChange });
    const input = screen.getByTestId('hidden-input-field');
    fireEvent.change(input, { target: { value: 'newpassword' } });
    expect(mockOnChange).toHaveBeenCalledTimes(1);
  });

  it('should render input with correct name attribute', () => {
    renderHiddenInput();
    const input = screen.getByTestId('hidden-input-field');
    expect(input).toHaveAttribute('name', 'password');
  });

  it('should render input with autoComplete attribute', () => {
    renderHiddenInput();
    const input = screen.getByTestId('hidden-input-field');
    expect(input).toHaveAttribute('autoComplete', 'current-password');
  });

  it('should render input with id when provided', () => {
    renderHiddenInput({ id: 'password-input' });
    const input = screen.getByTestId('hidden-input-field');
    expect(input).toHaveAttribute('id', 'password-input');
  });

  it('should render input with value when provided', () => {
    renderHiddenInput({ value: 'testpassword' });
    const input = screen.getByTestId('hidden-input-field') as HTMLInputElement;
    expect(input.value).toBe('testpassword');
  });

  it('should render placeholder when provided', () => {
    renderHiddenInput({ placeholder: 'Enter password' });
    const input = screen.getByTestId('hidden-input-field');
    expect(input).toHaveAttribute('placeholder', 'Enter password');
  });

  it('should toggle visibility multiple times', () => {
    renderHiddenInput();
    const input = screen.getByTestId('hidden-input-field');
    const revealButton = screen.getByRole('button', { name: /reveal password/i });

    // Toggle multiple times
    fireEvent.click(revealButton);
    expect(input).toHaveAttribute('type', 'text');

    fireEvent.click(screen.getByRole('button', { name: /mask password/i }));
    expect(input).toHaveAttribute('type', 'password');

    fireEvent.click(revealButton);
    expect(input).toHaveAttribute('type', 'text');
  });
});
