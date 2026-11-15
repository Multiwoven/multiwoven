import { render, screen, fireEvent, waitFor } from '@testing-library/react';
import { expect, describe, it, beforeEach, jest } from '@jest/globals';
import '@testing-library/jest-dom/jest-globals';
import '@testing-library/jest-dom';
import { ChakraProvider } from '@chakra-ui/react';
import ErrorLogsModal from '../ErrorLogsModal';
import { SyncRecordStatus } from '../../types';
import { useSyncStore } from '@/stores/useSyncStore';
import { mockStoreImplementation } from '../../../../../../__mocks__/commonMocks';
import copy from 'copy-to-clipboard';
const mockCopy = copy as jest.MockedFunction<typeof copy>;

jest.mock('copy-to-clipboard', () => ({
  __esModule: true,
  default: jest.fn(() => true),
}));

jest.mock('react-icons/fi', () => ({
  FiCopy: () => <span>Copy</span>,
  FiArrowRight: () => <span>→</span>,
  FiAlertTriangle: () => <span>⚠</span>,
}));

jest.mock('@/stores/useSyncStore', () => ({
  useSyncStore: jest.fn(),
}));

const mockUseSyncStore = useSyncStore as jest.MockedFunction<typeof useSyncStore>;

const renderComponent = (props: {
  request: string;
  response: string;
  level: string;
  status: SyncRecordStatus;
}) => {
  return render(
    <ChakraProvider>
      <ErrorLogsModal {...props} />
    </ChakraProvider>,
  );
};

describe('ErrorLogsModal', () => {
  beforeEach(() => {
    jest.clearAllMocks();
    mockStoreImplementation(mockUseSyncStore, {
      selectedSync: {
        syncName: 'Test Sync',
        sourceName: 'PostgreSQL',
        sourceIcon: 'postgres-icon',
        destinationName: 'Snowflake',
        destinationIcon: 'snowflake-icon',
      },
      setSelectedSync: jest.fn(),
    });
  });

  it('renders logs button', () => {
    renderComponent({
      request: '{}',
      response: '{}',
      level: 'info',
      status: SyncRecordStatus.success,
    });
    expect(screen.getByTestId('logs-button')).toBeInTheDocument();
  });

  it('opens modal when button is clicked', () => {
    renderComponent({
      request: '{"test": "data"}',
      response: '{"result": "success"}',
      level: 'info',
      status: SyncRecordStatus.success,
    });
    const button = screen.getByTestId('logs-button');
    fireEvent.click(button);
    expect(screen.getByText('Request')).toBeInTheDocument();
    expect(screen.getByText('Response')).toBeInTheDocument();
  });

  it('displays request and response data', () => {
    renderComponent({
      request: '{"test": "data"}',
      response: '{"result": "success"}',
      level: 'info',
      status: SyncRecordStatus.success,
    });
    const button = screen.getByTestId('logs-button');
    fireEvent.click(button);
    expect(screen.getByText(/test/)).toBeInTheDocument();
    expect(screen.getByText(/result/)).toBeInTheDocument();
  });

  it('copies request to clipboard', () => {
    renderComponent({
      request: '{"test": "data"}',
      response: '{}',
      level: 'info',
      status: SyncRecordStatus.success,
    });
    const button = screen.getByTestId('logs-button');
    fireEvent.click(button);
    // The component only has "Copy Code" button which copies both request and response
    const copyButton = screen.getByText(/Copy Code/i);
    fireEvent.click(copyButton);
    expect(mockCopy).toHaveBeenCalledWith('Request: {"test": "data"}\nResponse: {}');
  });

  it('copies response to clipboard', () => {
    renderComponent({
      request: '{}',
      response: '{"result": "success"}',
      level: 'info',
      status: SyncRecordStatus.success,
    });
    const button = screen.getByTestId('logs-button');
    fireEvent.click(button);
    const copyButton = screen.getByText(/Copy Code/i);
    fireEvent.click(copyButton);
    // The component copies both request and response
    expect(mockCopy).toHaveBeenCalledWith('Request: {}\nResponse: {"result": "success"}');
  });

  it('closes modal when close button is clicked', async () => {
    renderComponent({
      request: '{}',
      response: '{}',
      level: 'info',
      status: SyncRecordStatus.success,
    });
    const button = screen.getByTestId('logs-button');
    fireEvent.click(button);
    await waitFor(() => {
      expect(screen.getByText('Request')).toBeInTheDocument();
    });
    const closeButton = screen.getByRole('button', { name: /close/i });
    fireEvent.click(closeButton);
    await waitFor(() => {
      expect(screen.queryByText('Request')).not.toBeInTheDocument();
    });
  });

  it('shows error icon for failed status', () => {
    renderComponent({
      request: '{}',
      response: '{"error": "message"}',
      level: 'error',
      status: SyncRecordStatus.failed,
    });
    const button = screen.getByTestId('logs-button');
    fireEvent.click(button);
    // There are multiple elements with "error" text, check for the error icon (⚠) instead
    expect(screen.getByText('⚠')).toBeInTheDocument();
  });

  it('handles null sourceName, sourceIcon, destinationName, destinationIcon with fallbacks', () => {
    mockStoreImplementation(mockUseSyncStore, {
      selectedSync: {
        syncName: 'Test Sync',
        sourceName: null,
        sourceIcon: null,
        destinationName: null,
        destinationIcon: null,
      },
      setSelectedSync: jest.fn(),
    });
    renderComponent({
      request: '{}',
      response: '{}',
      level: 'info',
      status: SyncRecordStatus.success,
    });
    fireEvent.click(screen.getByTestId('logs-button'));
    expect(screen.getByText('SOURCE')).toBeInTheDocument();
    expect(screen.getByText('DESTINATION')).toBeInTheDocument();
    expect(screen.getByText('Logs received by')).toBeInTheDocument();
  });

  it('shows error on destination when status is failed and names are missing', () => {
    mockStoreImplementation(mockUseSyncStore, {
      selectedSync: {
        syncName: 'Test Sync',
        sourceName: undefined,
        sourceIcon: undefined,
        destinationName: undefined,
        destinationIcon: undefined,
      },
      setSelectedSync: jest.fn(),
    });
    renderComponent({
      request: '{}',
      response: '{"error": "fail"}',
      level: 'error',
      status: SyncRecordStatus.failed,
    });
    fireEvent.click(screen.getByTestId('logs-button'));
    expect(screen.getByText('⚠')).toBeInTheDocument();
    expect(screen.getByText('SOURCE')).toBeInTheDocument();
    expect(screen.getByText('DESTINATION')).toBeInTheDocument();
  });
});
