import { render, screen, fireEvent } from '@testing-library/react';
import { expect, describe, it, beforeEach } from '@jest/globals';
import '@testing-library/jest-dom/jest-globals';
import '@testing-library/jest-dom';
import ConfigWrapper from '../ConfigWrapper';
import { ChakraProvider } from '@chakra-ui/react';
import { INTERFACE_TYPE } from '../../types';
import { WorkflowInterfaceConfig } from '@/enterprise/services/types';

// Mock react-router-dom
jest.mock('react-router-dom', () => ({
  useParams: () => ({ id: 'workflow-123' }),
}));

// Mock ChatGeneralConfig
jest.mock('../ChatGeneralConfig', () => ({
  __esModule: true,
  default: () => <div data-testid='chat-general-config'>Chat General Config</div>,
}));

// Mock ApiGeneralConfig
jest.mock('../ApiInterface/ApiGeneralConfig', () => ({
  __esModule: true,
  default: () => <div data-testid='api-general-config'>API General Config</div>,
}));

// Mock SlackGeneralConfig
jest.mock('../SlackInterface/SlackGeneralConfig', () => ({
  __esModule: true,
  default: () => <div data-testid='slack-general-config'>Slack General Config</div>,
}));

// Mock SlackExportConfig
jest.mock('../SlackInterface/SlackExportConfig', () => ({
  __esModule: true,
  default: () => <div data-testid='slack-export-config'>Slack Export Config</div>,
}));

// Mock ChatbotExportConfig
jest.mock('../ChatbotExportConfig', () => ({
  __esModule: true,
  default: ({ isExportOpen }: { isExportOpen: boolean; agentId: string }) =>
    isExportOpen ? <div data-testid='chatbot-export-config'>Chatbot Export Config</div> : null,
}));

// Mock Security
jest.mock('../Security/Security', () => ({
  __esModule: true,
  default: () => <div data-testid='security-config'>Security Config</div>,
}));

// Mock FeedbackConfigForm
jest.mock('@/enterprise/views/DataApps/DataAppsForm/BuildDataApp/FeedbackConfigForm', () => ({
  __esModule: true,
  default: () => <div data-testid='feedback-config-form'>Feedback Config Form</div>,
}));

// Mock react-icons
jest.mock('react-icons/fi');

describe('ConfigWrapper', () => {
  const mockSetInterfaceComponentConfig = jest.fn();

  const defaultInterfaceConfig = {
    component_type: 'chatbot',
    configurable_id: '123',
    configurable_type: 'agent',
    properties: {
      field_group: '',
      measure_value: '',
      card_title: 'Test Chat',
      visual_color: '#808080',
      file_id: '',
      chat_bot: {
        welcome_message: 'Hello!',
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
        type: 'single',
        choices: [],
      },
    },
    export_config: {
      method: 'embed',
      interface_position: 'bottom_right',
    },
  } as unknown as WorkflowInterfaceConfig;

  const defaultProps = {
    selectedInterfaceType: INTERFACE_TYPE.WEBSITE_CHATBOT,
    interfaceComponentConfig: defaultInterfaceConfig,
    setInterfaceComponentConfig: mockSetInterfaceComponentConfig,
  };

  const renderComponent = (props = defaultProps) => {
    return render(
      <ChakraProvider>
        <ConfigWrapper {...props} />
      </ChakraProvider>,
    );
  };

  beforeEach(() => {
    jest.clearAllMocks();
  });

  describe('Rendering', () => {
    it('should render GENERAL section', () => {
      renderComponent();
      expect(screen.getByText('GENERAL')).toBeInTheDocument();
    });

    it('should render export section toggle with test id', () => {
      renderComponent();
      expect(screen.getByTestId('interface-export-section-toggle')).toBeInTheDocument();
    });

    it('should render ChatGeneralConfig for Website Chatbot', () => {
      renderComponent({
        ...defaultProps,
        selectedInterfaceType: INTERFACE_TYPE.WEBSITE_CHATBOT,
      });
      expect(screen.getByTestId('chat-general-config')).toBeInTheDocument();
    });

    it('should render ApiGeneralConfig for API Interface', () => {
      renderComponent({
        ...defaultProps,
        selectedInterfaceType: INTERFACE_TYPE.API_INTERFACE,
      });
      expect(screen.getByTestId('api-general-config')).toBeInTheDocument();
    });

    it('should render SlackGeneralConfig for Slack App', () => {
      renderComponent({
        ...defaultProps,
        selectedInterfaceType: INTERFACE_TYPE.SLACK_APP,
      });
      expect(screen.getByTestId('slack-general-config')).toBeInTheDocument();
    });
  });

  describe('Feedback Section', () => {
    it('should render FEEDBACK section for Website Chatbot', () => {
      renderComponent({
        ...defaultProps,
        selectedInterfaceType: INTERFACE_TYPE.WEBSITE_CHATBOT,
      });
      expect(screen.getByText('FEEDBACK')).toBeInTheDocument();
    });

    it('should render FEEDBACK section for Slack App', () => {
      renderComponent({
        ...defaultProps,
        selectedInterfaceType: INTERFACE_TYPE.SLACK_APP,
      });
      expect(screen.getByText('FEEDBACK')).toBeInTheDocument();
    });

    it('should not render FEEDBACK section for API Interface', () => {
      renderComponent({
        ...defaultProps,
        selectedInterfaceType: INTERFACE_TYPE.API_INTERFACE,
      });
      expect(screen.queryByText('FEEDBACK')).not.toBeInTheDocument();
    });

    it('should toggle feedback section when clicked', () => {
      renderComponent({
        ...defaultProps,
        selectedInterfaceType: INTERFACE_TYPE.WEBSITE_CHATBOT,
      });

      const feedbackButton = screen.getByText('FEEDBACK').closest('button');
      fireEvent.click(feedbackButton!);

      // After clicking, feedback section should expand
      expect(screen.getByText('Enable Feedback')).toBeInTheDocument();
    });
  });

  describe('Security Section', () => {
    it('should render SECURITY section for Website Chatbot', () => {
      renderComponent({
        ...defaultProps,
        selectedInterfaceType: INTERFACE_TYPE.WEBSITE_CHATBOT,
      });
      expect(screen.getByText('SECURITY')).toBeInTheDocument();
    });

    it('should not render SECURITY section for API Interface', () => {
      renderComponent({
        ...defaultProps,
        selectedInterfaceType: INTERFACE_TYPE.API_INTERFACE,
      });
      expect(screen.queryByText('SECURITY')).not.toBeInTheDocument();
    });

    it('should not render SECURITY section for Slack App', () => {
      renderComponent({
        ...defaultProps,
        selectedInterfaceType: INTERFACE_TYPE.SLACK_APP,
      });
      expect(screen.queryByText('SECURITY')).not.toBeInTheDocument();
    });
  });

  describe('Export Section', () => {
    it('should render EXPORT section for Website Chatbot', () => {
      renderComponent({
        ...defaultProps,
        selectedInterfaceType: INTERFACE_TYPE.WEBSITE_CHATBOT,
      });
      expect(screen.getByText('EXPORT')).toBeInTheDocument();
    });

    it('should render EXPORT section for Slack App', () => {
      renderComponent({
        ...defaultProps,
        selectedInterfaceType: INTERFACE_TYPE.SLACK_APP,
      });
      expect(screen.getByText('EXPORT')).toBeInTheDocument();
    });

    it('should not render EXPORT section for API Interface', () => {
      renderComponent({
        ...defaultProps,
        selectedInterfaceType: INTERFACE_TYPE.API_INTERFACE,
      });
      expect(screen.queryByText('EXPORT')).not.toBeInTheDocument();
    });
  });

  describe('Collapsible Sections', () => {
    it('should have GENERAL section open by default', () => {
      renderComponent({
        ...defaultProps,
        selectedInterfaceType: INTERFACE_TYPE.WEBSITE_CHATBOT,
      });
      // Chat General Config should be visible by default
      expect(screen.getByTestId('chat-general-config')).toBeInTheDocument();
    });

    it('should close GENERAL and open FEEDBACK when FEEDBACK is clicked', () => {
      renderComponent({
        ...defaultProps,
        selectedInterfaceType: INTERFACE_TYPE.WEBSITE_CHATBOT,
      });

      const feedbackButton = screen.getByText('FEEDBACK').closest('button');
      fireEvent.click(feedbackButton!);

      // Feedback section should now be visible
      expect(screen.getByText('Enable Feedback')).toBeInTheDocument();
    });
  });

  describe('Feedback Toggle', () => {
    it('should call setInterfaceComponentConfig when feedback switch is toggled', () => {
      renderComponent({
        ...defaultProps,
        selectedInterfaceType: INTERFACE_TYPE.WEBSITE_CHATBOT,
      });

      // Open feedback section
      const feedbackButton = screen.getByText('FEEDBACK').closest('button');
      fireEvent.click(feedbackButton!);

      // Toggle feedback switch
      const feedbackSwitch = screen.getByRole('checkbox');
      fireEvent.click(feedbackSwitch);

      expect(mockSetInterfaceComponentConfig).toHaveBeenCalled();
    });
  });
});
