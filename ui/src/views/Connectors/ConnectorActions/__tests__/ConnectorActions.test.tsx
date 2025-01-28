import { fireEvent, render, screen, waitFor } from '@testing-library/react';
import { expect } from '@jest/globals';
import '@testing-library/jest-dom';
// import { act } from 'react';

import ConnectorActions from '../ConnectorActions';
import { act } from 'react';

// Mock the custom hooks
const mockNavigate = jest.fn();
jest.mock('react-router-dom', () => ({
  ...jest.requireActual('react-router-dom'),
  useNavigate: () => mockNavigate,
  useParams: () => ({ sourceId: '123', destinationId: '456' }),
}));

const mockShowToast = jest.fn();
jest.mock('@/hooks/useCustomToast', () => ({
  __esModule: true,
  default: () => mockShowToast,
}));

// Add these mocks at the top of the file, with other mocks
jest.mock('@/app-signal', () => ({
  appsignal: {
    sendError: jest.fn(),
  },
}));

describe('ConnectorActions', () => {
  const defaultProps = {
    connectorType: 'source' as const,
    initialValues: {
      name: 'Test Connector',
      description: 'Test Description',
    },
    onSave: jest.fn(),
  };

  beforeEach(() => {
    jest.clearAllMocks();
  });

  it('renders edit and delete buttons', () => {
    render(<ConnectorActions {...defaultProps} />);

    expect(screen.getByText('Edit Details')).toBeTruthy();
    expect(screen.getByText('Delete')).toBeTruthy();
  });

  it('opens edit modal when edit button is clicked', () => {
    render(<ConnectorActions {...defaultProps} />);

    fireEvent.click(screen.getByText('Edit Details'));
    expect(screen.getByRole('dialog')).toBeTruthy();
  });

  it('calls onSave and closes modal when saving changes', async () => {
    render(<ConnectorActions {...defaultProps} />);

    // Open modal
    await act(async () => {
      fireEvent.click(screen.getByText('Edit Details'));
    });

    // Save changes
    await act(async () => {
      fireEvent.click(screen.getByText('Save Changes'));
    });

    await waitFor(() => {
      expect(defaultProps.onSave).toHaveBeenCalled();
      expect(screen.queryByRole('dialog')).not.toBeTruthy();
    });
  });

  it('deletes source connector successfully', async () => {
    jest.mock('@/services/connectors', () => ({
      deleteConnector: () => Promise.resolve({ success: true }),
    }));

    render(<ConnectorActions {...defaultProps} />);

    fireEvent.click(screen.getByText('Delete'));
    await waitFor(() =>
      expect(mockShowToast).toHaveBeenCalledWith({
        title: 'Connector deleted successfully',
        isClosable: true,
        duration: 5000,
        status: 'success',
        position: 'bottom-right',
      }),
    );

    expect(mockNavigate).toHaveBeenCalledWith('/setup/source');
  });

  it('uses correct connector ID based on type', async () => {
    const destinationProps = {
      ...defaultProps,
      connectorType: 'destination' as const,
    };

    render(<ConnectorActions {...destinationProps} />);

    fireEvent.click(screen.getByText('Delete'));

    await waitFor(() => {
      expect(mockNavigate).toHaveBeenCalledWith('/setup/destination');
    });
  });
});
