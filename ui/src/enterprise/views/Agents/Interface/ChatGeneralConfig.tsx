import { Avatar, WorkflowInterfaceConfig } from '@/enterprise/services/types';
import { Box, Stack, Text, Tooltip as ChakraTooltip, TabList } from '@chakra-ui/react';
import { INTERFACE_DISPLAY_TYPE } from '../types';
import { FiInfo, FiMonitor, FiSmartphone } from 'react-icons/fi';
import TabsWrapper from '@/components/TabsWrapper';
import TabItem from '@/components/TabItem';
import InputField from '@/components/InputField';
import ColourPicker from '@/components/ColourPicker';
import useAgentStore from '@/enterprise/store/useAgentStore';
import UploadChatbotAvatar from '@/enterprise/dataApps/components/ChatBot/UploadChatbotAvatar';

const ChatGeneralConfig = ({
  interfaceComponentConfig,
}: {
  interfaceComponentConfig: WorkflowInterfaceConfig;
}) => {
  const { setInterfaceConfig, setInterfaceDisplayType, interfaceDisplayType } = useAgentStore(
    (state) => state,
  );

  return (
    <Stack spacing='24px' marginTop='24px'>
      <Box display='flex' justifyContent='space-between' alignItems='center'>
        <Box display='flex' alignItems='center' gap='8px'>
          <Text fontWeight='semibold' size='sm'>
            Chat Display
          </Text>
          <ChakraTooltip
            hasArrow
            label={
              'Control how users experience your chat assistant. Full-page Chat: A full-page chat interface, accessible only as a hosted standalone app via the platform. Embeddable Chat: An embeddable chat widget, exportable via code or chrome extension. Can be maximized into an expandable view when needed.'
            }
            fontSize='xs'
            placement='top-start'
            backgroundColor='black.500'
            color='gray.100'
            borderRadius='6px'
            padding='8px'
          >
            <Text color='gray.600'>
              <FiInfo />
            </Text>
          </ChakraTooltip>
        </Box>
        <TabsWrapper index={interfaceDisplayType === INTERFACE_DISPLAY_TYPE.FULL_PAGE ? 0 : 1}>
          <TabList gap='8px'>
            <TabItem
              text=''
              testId='interface-chat-display-tab-desktop'
              action={() => {
                setInterfaceDisplayType(INTERFACE_DISPLAY_TYPE.FULL_PAGE);
              }}
              icon={<FiMonitor />}
            />
            <TabItem
              text=''
              testId='interface-chat-display-tab-mobile'
              action={() => {
                setInterfaceDisplayType(INTERFACE_DISPLAY_TYPE.MOBILE);
              }}
              icon={<FiSmartphone />}
            />
          </TabList>
        </TabsWrapper>
      </Box>
      <InputField
        label={'Chat Name'}
        name='title'
        testId='interface-chat-name-input'
        placeholder='Welcome Message'
        value={interfaceComponentConfig.properties.card_title}
        onChange={(value) => {
          setInterfaceConfig({
            ...interfaceComponentConfig,
            properties: {
              ...interfaceComponentConfig.properties,
              card_title: value.target.value,
            },
          });
        }}
      />
      <InputField
        label='Welcome Message'
        name='welcomeMessage'
        value={interfaceComponentConfig.properties.chat_bot?.welcome_message || ''}
        onChange={(value) => {
          setInterfaceConfig({
            ...interfaceComponentConfig,
            properties: {
              ...interfaceComponentConfig.properties,
              chat_bot: {
                ...interfaceComponentConfig.properties.chat_bot,
                welcome_message: value.target.value,
              },
            },
          });
        }}
        isTooltip
        tooltipLabel={
          'Set the first message users see when the chat opens. Use it to greet or guide users.'
        }
      />
      <ColourPicker
        label='Chat Color'
        visualColor={interfaceComponentConfig.properties.visual_color}
        setVisualColor={(value) => {
          setInterfaceConfig({
            ...interfaceComponentConfig,
            properties: {
              ...interfaceComponentConfig.properties,
              visual_color: value,
            },
          });
        }}
      />
      {interfaceDisplayType === INTERFACE_DISPLAY_TYPE.MOBILE && (
        <InputField
          label='Responder Name'
          name='responderName'
          value={interfaceComponentConfig.properties.chat_bot?.responder_name || ''}
          onChange={(value) => {
            setInterfaceConfig({
              ...interfaceComponentConfig,
              properties: {
                ...interfaceComponentConfig.properties,
                chat_bot: {
                  ...interfaceComponentConfig.properties.chat_bot,
                  responder_name: value.target.value,
                },
              },
            });
          }}
          isTooltip
          tooltipLabel='This name appears as the sender of the chat responses.'
        />
      )}
      <UploadChatbotAvatar
        label='Avatar'
        avatar={interfaceComponentConfig.properties.chat_bot?.avatar}
        visualColor={interfaceComponentConfig.properties.visual_color}
        setAvatar={(value: Avatar | undefined) => {
          setInterfaceConfig({
            ...interfaceComponentConfig,
            properties: {
              ...interfaceComponentConfig.properties,
              chat_bot: { ...interfaceComponentConfig.properties.chat_bot, avatar: value },
            },
          });
        }}
      />
    </Stack>
  );
};

export default ChatGeneralConfig;
