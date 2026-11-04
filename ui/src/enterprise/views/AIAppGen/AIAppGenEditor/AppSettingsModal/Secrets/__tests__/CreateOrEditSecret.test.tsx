import { screen, fireEvent, waitFor } from '@testing-library/react';
import { describe, it, expect, jest, beforeEach } from '@jest/globals';
import '@testing-library/jest-dom/jest-globals';

import { renderWithProviders } from '@/utils/testUtils';

import CreateOrEditSecret, { CreateOrEditSecretValues } from '../CreateOrEditSecret';

type OnSubmitFn = (values: CreateOrEditSecretValues) => void | Promise<void>;

const baseProps = {
  handleClose: jest.fn(),
  onSubmit: jest.fn<OnSubmitFn>(),
};

beforeEach(() => {
  jest.clearAllMocks();
});

describe('CreateOrEditSecret — rendering', () => {
  it('renders name, value, and description fields with Cancel + Save', () => {
    renderWithProviders(<CreateOrEditSecret mode='new' {...baseProps} />);
    expect(
      screen.getByPlaceholderText('Enter a secret name (e.g., MY_UNIQUE_KEY)'),
    ).toBeInTheDocument();
    expect(screen.getByPlaceholderText('Enter the value of the secret')).toBeInTheDocument();
    expect(screen.getByTestId('create-or-edit-secret-name-input')).toBeInTheDocument();
    expect(screen.getByTestId('create-or-edit-secret-value-input')).toBeInTheDocument();
    expect(screen.getByTestId('create-or-edit-secret-description-input')).toBeInTheDocument();
    expect(screen.getByTestId('create-or-edit-secret-cancel-button')).toBeInTheDocument();
    expect(screen.getByTestId('create-or-edit-secret-submit-button')).toHaveTextContent('Save');
  });

  it('shows "Save Changes" in edit mode', () => {
    renderWithProviders(
      <CreateOrEditSecret
        mode='edit'
        {...baseProps}
        initialValues={{ name: 'API_KEY', value: 'sk-xxx', description: 'desc' }}
      />,
    );
    expect(screen.getByTestId('create-or-edit-secret-submit-button')).toHaveTextContent(
      'Save Changes',
    );
  });

  it('pre-fills fields when initialValues are provided', () => {
    renderWithProviders(
      <CreateOrEditSecret
        mode='edit'
        {...baseProps}
        initialValues={{ name: 'MY_KEY', value: 'secret-val', description: 'A note' }}
      />,
    );
    expect(screen.getByTestId('create-or-edit-secret-name-input')).toHaveValue('MY_KEY');
    expect(screen.getByTestId('create-or-edit-secret-value-input')).toHaveValue('secret-val');
    expect(screen.getByTestId('create-or-edit-secret-description-input')).toHaveValue('A note');
  });
});

describe('CreateOrEditSecret — name normalization', () => {
  it('uppercases the name and converts interior spaces to underscores', () => {
    renderWithProviders(<CreateOrEditSecret mode='new' {...baseProps} />);
    const nameInput = screen.getByPlaceholderText('Enter a secret name (e.g., MY_UNIQUE_KEY)');
    fireEvent.change(nameInput, { target: { value: 'my api key' } });
    expect(nameInput).toHaveValue('MY_API_KEY');
  });

  it('strips leading whitespace as the user types', () => {
    renderWithProviders(<CreateOrEditSecret mode='new' {...baseProps} />);
    const nameInput = screen.getByPlaceholderText('Enter a secret name (e.g., MY_UNIQUE_KEY)');
    fireEvent.change(nameInput, { target: { value: '  MY_KEY' } });
    expect(nameInput).toHaveValue('MY_KEY');
  });

  it('trims trailing underscores on blur', () => {
    renderWithProviders(<CreateOrEditSecret mode='new' {...baseProps} />);
    const nameInput = screen.getByPlaceholderText('Enter a secret name (e.g., MY_UNIQUE_KEY)');
    fireEvent.change(nameInput, { target: { value: 'MY_KEY_' } });
    fireEvent.blur(nameInput);
    expect(nameInput).toHaveValue('MY_KEY');
  });
});

describe('CreateOrEditSecret — navigation', () => {
  it('Cancel calls handleClose', () => {
    const handleClose = jest.fn();
    renderWithProviders(<CreateOrEditSecret mode='new' {...baseProps} handleClose={handleClose} />);
    fireEvent.click(screen.getByTestId('create-or-edit-secret-cancel-button'));
    expect(handleClose).toHaveBeenCalledTimes(1);
  });

  it('Cancel is disabled while isLoading', () => {
    renderWithProviders(<CreateOrEditSecret mode='new' {...baseProps} isLoading />);
    expect(screen.getByTestId('create-or-edit-secret-cancel-button')).toBeDisabled();
  });
});

describe('CreateOrEditSecret — submit', () => {
  it('calls onSubmit with trimmed form values when valid', async () => {
    const onSubmit = jest.fn<OnSubmitFn>();
    renderWithProviders(<CreateOrEditSecret mode='new' {...baseProps} onSubmit={onSubmit} />);

    fireEvent.change(screen.getByTestId('create-or-edit-secret-name-input'), {
      target: { value: 'MY_KEY' },
    });
    fireEvent.change(screen.getByTestId('create-or-edit-secret-value-input'), {
      target: { value: 'top-secret' },
    });
    fireEvent.change(screen.getByTestId('create-or-edit-secret-description-input'), {
      target: { value: 'optional note' },
    });
    fireEvent.click(screen.getByTestId('create-or-edit-secret-submit-button'));

    await waitFor(() =>
      expect(onSubmit).toHaveBeenCalledWith({
        name: 'MY_KEY',
        value: 'top-secret',
        description: 'optional note',
      }),
    );
  });

  it('does not call onSubmit when required fields are empty', async () => {
    const onSubmit = jest.fn<OnSubmitFn>();
    renderWithProviders(<CreateOrEditSecret mode='new' {...baseProps} onSubmit={onSubmit} />);
    fireEvent.click(screen.getByTestId('create-or-edit-secret-submit-button'));

    await new Promise((r) => setTimeout(r, 10));
    expect(onSubmit).not.toHaveBeenCalled();
  });
});
