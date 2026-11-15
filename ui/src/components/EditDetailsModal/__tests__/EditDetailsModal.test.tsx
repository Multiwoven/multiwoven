import { fireEvent, render, screen, waitFor } from '@testing-library/react';
import { expect } from '@jest/globals';
import '@testing-library/jest-dom/jest-globals';
import '@testing-library/jest-dom';

import EditDetailsModal from '../EditDetailsModal';

describe('EditDetailsModal', () => {
  const mockSetModalOpen = jest.fn();
  const mockOnSave = jest.fn();
  const defaultProps = {
    openModal: true,
    setModalOpen: mockSetModalOpen,
    resourceName: 'source',
    onSave: mockOnSave,
  };

  beforeEach(() => {
    jest.clearAllMocks();
  });

  it('should render component correctly with default props', () => {
    render(<EditDetailsModal {...defaultProps} />);

    // Check if main elements are present
    expect(screen.getByText('Edit Details')).toBeInTheDocument();
    expect(screen.getByText('Edit the settings for this source')).toBeInTheDocument();
    expect(screen.getByText('Source Name')).toBeInTheDocument();
    expect(screen.getByText('Description')).toBeInTheDocument();
    expect(screen.getByText('(optional)')).toBeInTheDocument();

    // Check for input fields
    expect(screen.getByPlaceholderText('Enter a name')).toBeInTheDocument();
    expect(screen.getByPlaceholderText('Enter a description')).toBeInTheDocument();

    // Check for buttons
    expect(screen.getByText('Cancel')).toBeInTheDocument();
    expect(screen.getByText('Save Changes')).toBeInTheDocument();
  });

  it('should render with initial values when provided', () => {
    const initialValues = {
      name: 'Test Source',
      description: 'Test Description',
    };

    render(<EditDetailsModal {...defaultProps} initialValues={initialValues} />);

    expect(screen.getByPlaceholderText('Enter a name')).toHaveValue('Test Source');
    expect(screen.getByPlaceholderText('Enter a description')).toHaveValue('Test Description');
  });

  it('should close modal when clicking Cancel', () => {
    render(<EditDetailsModal {...defaultProps} />);

    fireEvent.click(screen.getByTestId('cancel-button'));
    expect(mockSetModalOpen).toHaveBeenCalledWith(false);
  });

  it('should show validation error when submitting without a name', async () => {
    render(<EditDetailsModal {...defaultProps} initialValues={{ name: '', description: '' }} />);

    fireEvent.blur(screen.getByTestId('name-input'));

    // Click save with empty form
    fireEvent.click(screen.getByTestId('save-changes-button'));

    // Validation should trigger and show error
    await waitFor(() => {
      expect(screen.getByText('Name is required')).toBeTruthy();
    });

    // The form should be marked as invalid
    const nameInput = screen.getByPlaceholderText('Enter a name');
    expect(nameInput).toHaveAttribute('aria-invalid', 'true');
  });

  it('should call onSave with form values when submitting valid form', async () => {
    render(<EditDetailsModal {...defaultProps} />);

    // Fill in the required name field
    fireEvent.change(screen.getByPlaceholderText('Enter a name'), {
      target: { value: 'New Source' },
    });

    // Fill in the optional description field
    fireEvent.change(screen.getByPlaceholderText('Enter a description'), {
      target: { value: 'New Description' },
    });

    fireEvent.click(screen.getByText('Save Changes'));

    await waitFor(() => {
      expect(mockOnSave).toHaveBeenCalledWith({
        name: 'New Source',
        description: 'New Description',
      });
    });
  });

  it('should handle form validation on blur', async () => {
    render(<EditDetailsModal {...defaultProps} />);

    const nameInput = screen.getByPlaceholderText('Enter a name');

    // Trigger blur event on empty input
    fireEvent.blur(nameInput);

    await waitFor(() => {
      expect(screen.getByText('Name is required')).toBeInTheDocument();
    });

    // Fill in the name and blur again
    fireEvent.change(nameInput, {
      target: { value: 'Valid Name' },
    });
    fireEvent.blur(nameInput);

    await waitFor(() => {
      expect(screen.queryByText('Name is required')).not.toBeInTheDocument();
    });
  });

  it('should use custom resource name in form labels', () => {
    render(<EditDetailsModal {...defaultProps} resourceName='dataset' />);

    expect(screen.getByText('Dataset Name')).toBeInTheDocument();
    expect(screen.getByText('Edit the settings for this dataset')).toBeInTheDocument();
  });
});
