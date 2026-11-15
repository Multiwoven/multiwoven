import { render, screen, fireEvent } from '@testing-library/react';
import { expect } from '@jest/globals';
import '@testing-library/jest-dom/jest-globals';
import '@testing-library/jest-dom';

import ChatGeneralConfig from '../ChatGeneralConfig';
import { Avatar, WorkflowInterfaceConfig } from '@/enterprise/services/types';
import { INTERFACE_DISPLAY_TYPE } from '../../types';
import { MULTIPLE_CHOICE_TYPES } from '@/enterprise/dataApps/feedbackTypes';
import { QueryClient, QueryClientProvider } from '@tanstack/react-query';
import { ChakraProvider, Tabs } from '@chakra-ui/react';
import { mockSetInterfaceConfig } from '../../../../../../__mocks__/agentStoreMocks';

// Mock useAgentStore
const mockSetInterfaceDisplayType = jest.fn();
let mockInterfaceDisplayType = INTERFACE_DISPLAY_TYPE.FULL_PAGE;

jest.mock('@/enterprise/store/useAgentStore', () => ({
  __esModule: true,
  default: (selector: (state: unknown) => unknown) =>
    selector({
      setInterfaceConfig: mockSetInterfaceConfig,
      setInterfaceDisplayType: mockSetInterfaceDisplayType,
      get interfaceDisplayType() {
        return mockInterfaceDisplayType;
      },
    }),
}));

// Mock UploadChatbotAvatar
jest.mock('@/enterprise/dataApps/components/ChatBot/UploadChatbotAvatar', () => ({
  __esModule: true,
  default: ({
    label,
    avatar,
    visualColor,
    setAvatar,
  }: {
    label: string;
    avatar?: Avatar;
    visualColor: string;
    setAvatar: (avatar: Avatar | undefined) => void;
  }) => (
    <div data-testid='upload-chatbot-avatar'>
      <div data-testid='avatar-label'>{label}</div>
      <div data-testid='avatar-value'>{avatar ? JSON.stringify(avatar) : 'no-avatar'}</div>
      <div data-testid='avatar-visual-color'>{visualColor}</div>
      <button
        data-testid='set-avatar-btn'
        onClick={() => setAvatar({ type: 'image', value: 'http://example.com/new-avatar.png' })}
      >
        Set Avatar
      </button>
    </div>
  ),
}));

// Mock InputField
jest.mock('@/components/InputField', () => ({
  __esModule: true,
  default: ({
    label,
    name,
    value,
    onChange,
    placeholder,
    isTooltip,
    tooltipLabel,
    testId,
  }: {
    label: string;
    name: string;
    value: string;
    onChange: (e: { target: { value: string } }) => void;
    placeholder?: string;
    isTooltip?: boolean;
    tooltipLabel?: string;
    testId?: string;
  }) => (
    <div data-testid={`input-field-${name}`}>
      <label>{label}</label>
      <input
        data-testid={testId ?? `input-${name}`}
        value={value}
        onChange={onChange}
        placeholder={placeholder}
      />
      {isTooltip && tooltipLabel && <div data-testid={`tooltip-${name}`}>{tooltipLabel}</div>}
    </div>
  ),
}));

// Mock ColourPicker
jest.mock('@/components/ColourPicker', () => ({
  __esModule: true,
  default: ({
    label,
    visualColor,
    setVisualColor,
  }: {
    label: string;
    visualColor: string;
    setVisualColor: (value: string) => void;
  }) => (
    <div data-testid='colour-picker'>
      <label>{label}</label>
      <input
        data-testid='colour-input'
        type='color'
        value={visualColor}
        onChange={(e) => setVisualColor(e.target.value)}
      />
    </div>
  ),
}));

// Mock TabItem and TabsWrapper
jest.mock('@/components/TabItem', () => ({
  __esModule: true,
  default: ({
    text,
    action,
    icon,
    testId,
  }: {
    text: string;
    action: () => void;
    icon?: React.ReactNode;
    testId?: string;
  }) => (
    <button data-testid={testId ?? `tab-item-${text}`} onClick={action}>
      {text}
      {icon}
    </button>
  ),
}));

jest.mock('@/components/TabsWrapper', () => {
  return {
    __esModule: true,
    default: ({ children, index }: { children: React.ReactNode; index: number }) => (
      <Tabs index={index} data-testid='tabs-wrapper' data-index={index}>
        {children}
      </Tabs>
    ),
  };
});

describe('ChatGeneralConfig', () => {
  const baseConfig: WorkflowInterfaceConfig = {
    component_type: 'chat_bot',
    configurable_id: '',
    configurable_type: 'workflow',
    properties: {
      field_group: '',
      measure_value: '',
      file_id: '',
      card_title: 'Test Chat',
      visual_color: '#FF5733',
      chat_bot: {
        welcome_message: 'Welcome!',
        responder_name: 'Bot',
      },
    },
    feedback_config: {
      feedback_enabled: false,
      feedback_method: null,
      feedback_title: '',
      feedback_description: '',
      additional_remarks: {
        enabled: false,
        required: false,
        title: '',
        description: '',
      },
      multiple_choice: {
        type: MULTIPLE_CHOICE_TYPES.SINGLE_SELECT,
        choices: [],
      },
    },
    export_config: {
      method: 'embed',
      interface_position: 'bottom_right',
      whitelist_urls: [],
      embeddable_assistant: false,
    },
  };

  beforeEach(() => {
    jest.clearAllMocks();
    mockInterfaceDisplayType = INTERFACE_DISPLAY_TYPE.FULL_PAGE;
  });
  const queryClient = new QueryClient();

  const renderComponent = (config: WorkflowInterfaceConfig) => {
    return render(
      <ChakraProvider>
        <QueryClientProvider client={queryClient}>
          <ChatGeneralConfig interfaceComponentConfig={config} />
        </QueryClientProvider>
      </ChakraProvider>,
    );
  };

  it('renders Chat Display section with tooltip', () => {
    renderComponent(baseConfig);

    expect(screen.getByText('Chat Display')).toBeInTheDocument();
  });

  it('uses stable test ids for display tabs and chat name', () => {
    renderComponent(baseConfig);
    expect(screen.getByTestId('interface-chat-display-tab-desktop')).toBeInTheDocument();
    expect(screen.getByTestId('interface-chat-display-tab-mobile')).toBeInTheDocument();
    expect(screen.getByTestId('interface-chat-name-input')).toBeInTheDocument();
  });

  it('renders Chat Name input field', () => {
    renderComponent(baseConfig);

    const input = screen.getByTestId('interface-chat-name-input');
    expect(input).toBeInTheDocument();
    expect(input).toHaveValue('Test Chat');
  });

  it('updates card_title when Chat Name input changes', () => {
    renderComponent(baseConfig);

    const input = screen.getByTestId('interface-chat-name-input');
    fireEvent.change(input, { target: { value: 'New Chat Name' } });

    expect(mockSetInterfaceConfig).toHaveBeenCalledWith({
      ...baseConfig,
      properties: {
        ...baseConfig.properties,
        card_title: 'New Chat Name',
      },
    });
  });

  it('renders Welcome Message input field', () => {
    renderComponent(baseConfig);

    const input = screen.getByTestId('input-welcomeMessage');
    expect(input).toBeInTheDocument();
    expect(input).toHaveValue('Welcome!');
  });

  it('updates welcome_message when Welcome Message input changes', () => {
    renderComponent(baseConfig);

    const input = screen.getByTestId('input-welcomeMessage');
    fireEvent.change(input, { target: { value: 'New Welcome Message' } });

    expect(mockSetInterfaceConfig).toHaveBeenCalledWith({
      ...baseConfig,
      properties: {
        ...baseConfig.properties,
        chat_bot: {
          ...baseConfig.properties.chat_bot,
          welcome_message: 'New Welcome Message',
        },
      },
    });
  });

  it('renders ColourPicker for Chat Color', () => {
    renderComponent(baseConfig);

    expect(screen.getByTestId('colour-picker')).toBeInTheDocument();
    const colorInput = screen.getByTestId('colour-input');
    // HTML color inputs normalize to lowercase
    expect(colorInput).toHaveValue('#ff5733');
  });

  it('updates visual_color when Chat Color changes', () => {
    renderComponent(baseConfig);

    const colorInput = screen.getByTestId('colour-input');
    fireEvent.change(colorInput, { target: { value: '#123456' } });

    expect(mockSetInterfaceConfig).toHaveBeenCalledWith({
      ...baseConfig,
      properties: {
        ...baseConfig.properties,
        visual_color: '#123456',
      },
    });
  });

  it('renders Responder Name input when interfaceDisplayType is MOBILE', () => {
    mockInterfaceDisplayType = INTERFACE_DISPLAY_TYPE.MOBILE;
    renderComponent(baseConfig);

    const input = screen.getByTestId('input-responderName');
    expect(input).toBeInTheDocument();
    expect(input).toHaveValue('Bot');
  });

  it('does not render Responder Name input when interfaceDisplayType is FULL_PAGE', () => {
    renderComponent(baseConfig);

    expect(screen.queryByTestId('input-responderName')).not.toBeInTheDocument();
  });

  it('updates responder_name when Responder Name input changes', () => {
    mockInterfaceDisplayType = INTERFACE_DISPLAY_TYPE.MOBILE;
    renderComponent(baseConfig);

    const input = screen.getByTestId('input-responderName');
    fireEvent.change(input, { target: { value: 'New Bot Name' } });

    expect(mockSetInterfaceConfig).toHaveBeenCalledWith({
      ...baseConfig,
      properties: {
        ...baseConfig.properties,
        chat_bot: {
          ...baseConfig.properties.chat_bot,
          responder_name: 'New Bot Name',
        },
      },
    });
  });

  it('renders UploadChatbotAvatar component', () => {
    renderComponent(baseConfig);

    expect(screen.getByTestId('upload-chatbot-avatar')).toBeInTheDocument();
    expect(screen.getByTestId('avatar-label')).toHaveTextContent('Avatar');
  });

  it('passes avatar prop to UploadChatbotAvatar when avatar exists', () => {
    const avatar: Avatar = { type: 'image', value: 'http://example.com/avatar.png' };
    const configWithAvatar: WorkflowInterfaceConfig = {
      ...baseConfig,
      properties: {
        ...baseConfig.properties,
        chat_bot: {
          ...baseConfig.properties.chat_bot,
          avatar,
        },
      },
    };

    renderComponent(configWithAvatar);

    const avatarValue = screen.getByTestId('avatar-value');
    expect(avatarValue).toHaveTextContent(JSON.stringify(avatar));
  });

  it('passes undefined avatar to UploadChatbotAvatar when avatar does not exist', () => {
    renderComponent(baseConfig);

    const avatarValue = screen.getByTestId('avatar-value');
    expect(avatarValue).toHaveTextContent('no-avatar');
  });

  it('passes visual_color to UploadChatbotAvatar', () => {
    renderComponent(baseConfig);

    const visualColor = screen.getByTestId('avatar-visual-color');
    expect(visualColor).toHaveTextContent('#FF5733');
  });

  it('updates avatar when setAvatar is called from UploadChatbotAvatar', () => {
    renderComponent(baseConfig);

    const setAvatarBtn = screen.getByTestId('set-avatar-btn');
    fireEvent.click(setAvatarBtn);

    expect(mockSetInterfaceConfig).toHaveBeenCalledWith({
      ...baseConfig,
      properties: {
        ...baseConfig.properties,
        chat_bot: {
          ...baseConfig.properties.chat_bot,
          avatar: { type: 'image', value: 'http://example.com/new-avatar.png' },
        },
      },
    });
  });

  it('handles empty welcome_message gracefully', () => {
    const configWithoutWelcome: WorkflowInterfaceConfig = {
      ...baseConfig,
      properties: {
        ...baseConfig.properties,
        chat_bot: {
          ...baseConfig.properties.chat_bot,
          welcome_message: undefined,
        },
      },
    };

    renderComponent(configWithoutWelcome);

    const input = screen.getByTestId('input-welcomeMessage');
    expect(input).toHaveValue('');
  });

  it('handles empty responder_name gracefully', () => {
    mockInterfaceDisplayType = INTERFACE_DISPLAY_TYPE.MOBILE;
    const configWithoutResponder: WorkflowInterfaceConfig = {
      ...baseConfig,
      properties: {
        ...baseConfig.properties,
        chat_bot: {
          ...baseConfig.properties.chat_bot,
          responder_name: undefined,
        },
      },
    };

    renderComponent(configWithoutResponder);

    const input = screen.getByTestId('input-responderName');
    expect(input).toHaveValue('');
  });

  it('calls setInterfaceDisplayType when tab is clicked', () => {
    renderComponent(baseConfig);

    fireEvent.click(screen.getByTestId('interface-chat-display-tab-mobile'));

    expect(mockSetInterfaceDisplayType).toHaveBeenCalledWith(INTERFACE_DISPLAY_TYPE.MOBILE);
  });
});
