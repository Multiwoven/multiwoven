import React from 'react';
import { fireEvent, render, screen, waitFor } from '@testing-library/react';
import { expect, jest } from '@jest/globals';
import '@testing-library/jest-dom/jest-globals';
import '@testing-library/jest-dom';
import { ChakraProvider } from '@chakra-ui/react';
import ChatPromptInput from '../ChatPromptInput';
import { useFeatureFlags, FEATURE_FLAG_KEYS } from '@/enterprise/hooks/useFeatureFlags';

(global as any).mockUseFeatureFlags = jest.fn().mockReturnValue({ nasaFeatures: true });

jest.mock('@/enterprise/hooks/useFeatureFlags', () => {
  const FEATURE_FLAG_KEYS = { nasaFeatures: 'nasaFeatures' as const };

  const useFeatureFlags = jest.fn().mockReturnValue({
    [FEATURE_FLAG_KEYS.nasaFeatures]: false,
  });

  return {
    __esModule: true,
    FEATURE_FLAG_KEYS,
    useFeatureFlags,
  };
});

jest.mock('@/components/FeatureFlagWrapper/FeatureFlagWrapper', () => {
  return {
    FeatureFlagWrapper: ({ children, flags }: { children: React.ReactNode; flags: string[] }) => {
      const ff = (global as any).mockUseFeatureFlags();
      const enabled = flags.some((f) => ff[f]);
      return enabled ? <>{children}</> : null;
    },
  };
});

const mockSetFile = jest.fn();
jest.mock('@/enterprise/store/useAssistantConfigStore', () => ({
  useAssistantConfigStore: () => ({ setFile: mockSetFile }),
}));

jest.mock('@/components/ToolTip', () => ({
  __esModule: true,
  default: ({ children }: { children: React.ReactNode }) => <>{children}</>,
}));

jest.mock('../AssistantFileMessage', () => ({
  __esModule: true,
  default: ({
    filename,
    handleRemoveFile,
  }: {
    filename: string;
    handleRemoveFile?: () => void;
  }) => (
    <div data-testid='file-chip'>
      <span>{filename}</span>
      {handleRemoveFile ? (
        <button data-testid='remove-file' onClick={handleRemoveFile}>
          remove
        </button>
      ) : null}
    </div>
  ),
}));

jest.mock('../SessionFileAttach', () => ({
  __esModule: true,
  default: ({
    onFileSelect,
    disabled,
  }: {
    onFileSelect?: (file: File) => void;
    disabled?: boolean;
  }) => (
    <button
      type='button'
      data-testid='session-attach'
      aria-label='Attach file to message'
      disabled={disabled}
      onClick={() => onFileSelect?.(new File(['x'], 'session.csv', { type: 'text/csv' }))}
    >
      session attach
    </button>
  ),
}));

function setScrollHeight(el: HTMLElement, value: number) {
  Object.defineProperty(el, 'scrollHeight', {
    configurable: true,
    get: () => value,
  });
}

const renderWithChakra = (ui: React.ReactElement) => render(<ChakraProvider>{ui}</ChakraProvider>);

describe('ChatPromptInput', () => {
  beforeEach(() => {
    jest.clearAllMocks();
  });

  test('renders textarea with placeholder and respects disabled state', () => {
    const onChange = jest.fn();
    const onSend = jest.fn();
    renderWithChakra(
      <ChatPromptInput
        value=''
        file={null}
        isDisabled={false}
        placeholder='Type your message...'
        onChange={onChange}
        onSend={onSend}
        handleAttachFile={jest.fn()}
      />,
    );

    const textarea = screen.getByPlaceholderText('Type your message...');
    expect(textarea).toBeInTheDocument();
    const send = screen.getByRole('button', { name: /send message/i });
    expect(send).toBeEnabled();
    expect(send).toHaveAttribute('data-testid', 'chat-send-button');
  });

  test('Enter key alone does NOT trigger onSend (allows newline)', () => {
    const onSend = jest.fn();
    renderWithChakra(
      <ChatPromptInput
        value='Test'
        file={null}
        onChange={jest.fn()}
        onSend={onSend}
        handleAttachFile={jest.fn()}
      />,
    );

    const textarea = screen.getByPlaceholderText('Type your message...');

    fireEvent.keyDown(textarea, { key: 'Enter' });
    expect(onSend).not.toHaveBeenCalled();
  });

  test('Shift+Enter triggers onSend', () => {
    const onSend = jest.fn();
    renderWithChakra(
      <ChatPromptInput
        value='Test'
        file={null}
        onChange={jest.fn()}
        onSend={onSend}
        handleAttachFile={jest.fn()}
      />,
    );

    const textarea = screen.getByPlaceholderText('Type your message...');

    fireEvent.keyDown(textarea, { key: 'Enter', shiftKey: true });
    expect(onSend).toHaveBeenCalledTimes(1);
  });

  test('Ctrl+Enter (Windows/Linux) triggers onSend', () => {
    const onSend = jest.fn();
    renderWithChakra(
      <ChatPromptInput
        value='Test'
        file={null}
        onChange={jest.fn()}
        onSend={onSend}
        handleAttachFile={jest.fn()}
      />,
    );

    const textarea = screen.getByPlaceholderText('Type your message...');

    fireEvent.keyDown(textarea, { key: 'Enter', ctrlKey: true });
    expect(onSend).toHaveBeenCalledTimes(1);
  });

  test('Cmd+Enter (macOS) triggers onSend', () => {
    const onSend = jest.fn();
    renderWithChakra(
      <ChatPromptInput
        value='Test'
        file={null}
        onChange={jest.fn()}
        onSend={onSend}
        handleAttachFile={jest.fn()}
      />,
    );

    const textarea = screen.getByPlaceholderText('Type your message...');

    fireEvent.keyDown(textarea, { key: 'Enter', metaKey: true });
    expect(onSend).toHaveBeenCalledTimes(1);
  });

  test('Send button click triggers onSend when enabled', () => {
    const onSend = jest.fn();
    renderWithChakra(
      <ChatPromptInput
        value='Hi'
        file={null}
        onChange={jest.fn()}
        onSend={onSend}
        handleAttachFile={jest.fn()}
      />,
    );

    fireEvent.click(screen.getByRole('button', { name: /send message/i }));
    expect(onSend).toHaveBeenCalledTimes(1);
  });

  test('Send button disabled when isDisabled=true', () => {
    renderWithChakra(
      <ChatPromptInput
        value='Hi'
        file={null}
        isDisabled
        onChange={jest.fn()}
        onSend={jest.fn()}
        handleAttachFile={jest.fn()}
      />,
    );

    expect(screen.getByRole('button', { name: /send message/i })).toBeDisabled();
  });

  test('Attach file button is visible when nasaFeatures flag is true and calls handleAttachFile', () => {
    (global as any).mockUseFeatureFlags.mockReturnValue({ nasaFeatures: true });

    const handleAttachFile = jest.fn();
    renderWithChakra(
      <ChatPromptInput
        value=''
        file={null}
        onChange={jest.fn()}
        onSend={jest.fn()}
        handleAttachFile={handleAttachFile}
      />,
    );

    // Button has paperclip icon but no aria-label; rely on role=button count and click the first non-send button.
    const buttons = screen.getAllByRole('button');
    // Expect two buttons: attach + send
    expect(buttons.length).toBeGreaterThanOrEqual(2);

    // Click the first button that is not "Send message"
    const attachBtn = buttons.find((b) => b.getAttribute('aria-label') !== 'Send message')!;
    fireEvent.click(attachBtn);

    expect(handleAttachFile).toHaveBeenCalledTimes(1);
  });

  test('Attach file button is hidden when nasaFeatures flag is false', () => {
    (global as any).mockUseFeatureFlags.mockReturnValue({ nasaFeatures: false });

    const { container } = renderWithChakra(
      <ChatPromptInput
        value=''
        file={null}
        onChange={jest.fn()}
        onSend={jest.fn()}
        handleAttachFile={jest.fn()}
      />,
    );

    // Only the send button should be present
    const buttons = container.querySelectorAll('button');
    expect(buttons.length).toBe(1);
    expect(screen.getByRole('button', { name: /send message/i })).toBeInTheDocument();
  });

  test('Shows file chip when file prop is provided and remove triggers setFile(null)', () => {
    (global as any).mockUseFeatureFlags.mockReturnValue({ nasaFeatures: true });

    renderWithChakra(
      <ChatPromptInput
        value=''
        file={new File(['hello'], 'data.csv', { type: 'text/csv' })}
        onChange={jest.fn()}
        onSend={jest.fn()}
        handleAttachFile={jest.fn()}
      />,
    );

    expect(screen.getByTestId('file-chip')).toBeInTheDocument();
    expect(screen.getByText('data.csv')).toBeInTheDocument();

    fireEvent.click(screen.getByTestId('remove-file'));
    expect(mockSetFile).toHaveBeenCalledWith(null);
  });

  test('Widget mode renders without crashing and still sends on click', () => {
    const onSend = jest.fn();
    renderWithChakra(
      <ChatPromptInput
        isWidget
        value='Widget mode'
        file={null}
        onChange={jest.fn()}
        onSend={onSend}
        handleAttachFile={jest.fn()}
      />,
    );

    fireEvent.click(screen.getByRole('button', { name: /send message/i }));
    expect(onSend).toHaveBeenCalledTimes(1);
  });

  test('auto-grows height to match scrollHeight when text increases', async () => {
    const { rerender } = renderWithChakra(
      <ChatPromptInput
        value=''
        file={null}
        onChange={jest.fn()}
        onSend={jest.fn()}
        handleAttachFile={jest.fn()}
      />,
    );

    const textarea = screen.getByPlaceholderText('Type your message...') as HTMLTextAreaElement;

    setScrollHeight(textarea, 60);
    fireEvent.change(textarea, { target: { value: 'Hello' } });
    rerender(
      <ChakraProvider>
        <ChatPromptInput
          value='Hello'
          file={null}
          onChange={jest.fn()}
          onSend={jest.fn()}
          handleAttachFile={jest.fn()}
        />
      </ChakraProvider>,
    );
    await waitFor(() => expect(textarea.style.height).toBe('60px'));
  });

  describe('Session file upload', () => {
    beforeEach(() => {
      (useFeatureFlags as jest.Mock).mockReturnValue({ [FEATURE_FLAG_KEYS.nasaFeatures]: false });
    });

    test('session attach button is visible when nasaFeatures=false, isSessionFileUploadEnabled=true, and onSessionAttachFile provided', () => {
      renderWithChakra(
        <ChatPromptInput
          value=''
          file={null}
          onChange={jest.fn()}
          onSend={jest.fn()}
          handleAttachFile={jest.fn()}
          isSessionFileUploadEnabled
          onSessionAttachFile={jest.fn()}
        />,
      );

      expect(screen.getByRole('button', { name: /attach file to message/i })).toBeInTheDocument();
    });

    test('session attach button is hidden when nasaFeatures=true even with session upload enabled', () => {
      (useFeatureFlags as jest.Mock).mockReturnValue({ [FEATURE_FLAG_KEYS.nasaFeatures]: true });

      renderWithChakra(
        <ChatPromptInput
          value=''
          file={null}
          onChange={jest.fn()}
          onSend={jest.fn()}
          handleAttachFile={jest.fn()}
          isSessionFileUploadEnabled
          onSessionAttachFile={jest.fn()}
        />,
      );

      expect(
        screen.queryByRole('button', { name: /attach file to message/i }),
      ).not.toBeInTheDocument();
    });

    test('session attach button is hidden when onSessionAttachFile is not provided', () => {
      renderWithChakra(
        <ChatPromptInput
          value=''
          file={null}
          onChange={jest.fn()}
          onSend={jest.fn()}
          handleAttachFile={jest.fn()}
          isSessionFileUploadEnabled
        />,
      );

      expect(
        screen.queryByRole('button', { name: /attach file to message/i }),
      ).not.toBeInTheDocument();
    });

    test('session file chips show file names and remove calls onRemoveSessionFile with index', () => {
      const onRemoveSessionFile = jest.fn();
      const files = [
        { file: new File(['a'], 'doc1.txt', { type: 'text/plain' }), isUploading: false },
        { file: new File(['b'], 'doc2.pdf', { type: 'application/pdf' }), isUploading: false },
      ];

      renderWithChakra(
        <ChatPromptInput
          value=''
          file={null}
          onChange={jest.fn()}
          onSend={jest.fn()}
          handleAttachFile={jest.fn()}
          isSessionFileUploadEnabled
          onSessionAttachFile={jest.fn()}
          sessionAttachedFiles={files}
          onRemoveSessionFile={onRemoveSessionFile}
        />,
      );

      expect(screen.getByText('doc1.txt')).toBeInTheDocument();
      expect(screen.getByText('doc2.pdf')).toBeInTheDocument();

      const removeButtons = screen.getAllByRole('button', { name: /remove file/i });
      expect(removeButtons).toHaveLength(2);
      fireEvent.click(removeButtons[1]);
      expect(onRemoveSessionFile).toHaveBeenCalledWith(1);
    });

    test('session attach button remains enabled while files are uploading', () => {
      renderWithChakra(
        <ChatPromptInput
          value='Hi'
          file={null}
          onChange={jest.fn()}
          onSend={jest.fn()}
          handleAttachFile={jest.fn()}
          isSessionFileUploadEnabled
          onSessionAttachFile={jest.fn()}
          isSessionFilesUploading
        />,
      );

      expect(screen.getByRole('button', { name: /attach file to message/i })).not.toBeDisabled();
    });

    test('send button is disabled when isSessionFilesUploading is true', () => {
      renderWithChakra(
        <ChatPromptInput
          value='Hi'
          file={null}
          onChange={jest.fn()}
          onSend={jest.fn()}
          handleAttachFile={jest.fn()}
          isSessionFileUploadEnabled
          onSessionAttachFile={jest.fn()}
          isSessionFilesUploading
        />,
      );

      expect(screen.getByRole('button', { name: /send message/i })).toBeDisabled();
    });

    test('send button is disabled when session files attached but message is empty', () => {
      renderWithChakra(
        <ChatPromptInput
          value=''
          file={null}
          onChange={jest.fn()}
          onSend={jest.fn()}
          handleAttachFile={jest.fn()}
          isSessionFileUploadEnabled
          onSessionAttachFile={jest.fn()}
          sessionAttachedFiles={[
            { file: new File(['a'], 'doc.txt', { type: 'text/plain' }), isUploading: false },
          ]}
        />,
      );

      expect(screen.getByRole('button', { name: /send message/i })).toBeDisabled();
    });
  });
});
