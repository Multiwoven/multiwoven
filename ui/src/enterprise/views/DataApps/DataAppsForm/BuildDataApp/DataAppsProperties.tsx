import TabItem from '@/components/TabItem';
import TabsWrapper from '@/components/TabsWrapper';
import {
  Box,
  Divider,
  Input,
  InputGroup,
  InputLeftElement,
  Switch,
  TabList,
  Text,
} from '@chakra-ui/react';
import { Dispatch, SetStateAction, useEffect, useState } from 'react';
import FeedbackConfigForm from './FeedbackConfigForm';
import { FEEDBACK_METHODS, MultipleChoiceConfig } from '@/enterprise/dataApps/feedbackTypes';

import UploadChatbotAvatar from '@/enterprise/dataApps/components/ChatBot/UploadChatbotAvatar';
import { Avatar } from '@/enterprise/services/types';

enum DATA_APP_PROPERT_TABS {
  PROPERTIES = 'Properties',
  FEEDBACK = 'Feedback',
}

type DataAppsPropertiesProps = {
  canConfigureColor: boolean;
  feedbackTitle: string;
  feedbackDescription: string;
  cardTitle: string;
  visualColor: string;
  feedbackMethod: FEEDBACK_METHODS | null;
  isAdditionalRemarks: boolean;
  isAdditionalRemarksRequired: boolean;
  additionalRemarksTitle: string;
  additionalRemarksDescription: string;
  multipleChoiceConfig: MultipleChoiceConfig;
  responderName: string;
  welcomeMessage: string;
  isFeedbackEnabled: boolean;
  avatar?: Avatar;
  setIsFeedbackEnabled: Dispatch<SetStateAction<boolean>>;
  setMultipleChoiceConfig: Dispatch<SetStateAction<MultipleChoiceConfig>>;
  setFeedbackMethod: Dispatch<SetStateAction<string | null | undefined>>;
  setFeedbackTitle: Dispatch<SetStateAction<string>>;
  setFeedbackDescription: Dispatch<SetStateAction<string>>;
  setIsAdditionalRemarks: Dispatch<SetStateAction<boolean>>;
  setIsAdditionalRemarksRequired: Dispatch<SetStateAction<boolean>>;
  setAdditionalRemarksTitle: Dispatch<SetStateAction<string>>;
  setAdditionalRemarksDescription: Dispatch<SetStateAction<string>>;
  setCardTitle: Dispatch<SetStateAction<string>>;
  setVisualColor: Dispatch<SetStateAction<string>>;
  isChatbot?: boolean;
  setResponderName: (args: string) => void;
  setWelcomeMessage: (args: string) => void;
  setAvatar: (args: Avatar | undefined) => void;
};

const DataAppsProperties = ({
  canConfigureColor = true,
  feedbackTitle,
  setFeedbackTitle,
  feedbackMethod,
  setFeedbackMethod,
  feedbackDescription,
  setFeedbackDescription,
  cardTitle,
  setCardTitle,
  visualColor,
  setVisualColor,
  isAdditionalRemarks,
  setIsAdditionalRemarks,
  isAdditionalRemarksRequired,
  setIsAdditionalRemarksRequired,
  additionalRemarksTitle,
  setAdditionalRemarksTitle,
  additionalRemarksDescription,
  setAdditionalRemarksDescription,
  multipleChoiceConfig,
  setMultipleChoiceConfig,
  responderName,
  setResponderName,
  isChatbot = false,
  welcomeMessage,
  setWelcomeMessage,
  isFeedbackEnabled,
  setIsFeedbackEnabled,
  avatar,
  setAvatar,
}: DataAppsPropertiesProps) => {
  const [activeTab, setActiveTab] = useState(DATA_APP_PROPERT_TABS.PROPERTIES);

  useEffect(() => {
    if (isChatbot) {
      setCardTitle('Chatbot');
    }
  }, [isChatbot]);

  useEffect(() => {
    if (feedbackMethod === FEEDBACK_METHODS.TEXT_INPUT) {
      setIsAdditionalRemarks(false);
      setIsAdditionalRemarksRequired(false);
    }
  }, [feedbackMethod]);

  return (
    <Box
      flex={1}
      minHeight={'100%'}
      padding='24px'
      backgroundColor='gray.100'
      borderRadius='8px'
      borderStyle='solid'
      borderWidth='1px'
      borderColor='gray.400'
      overflow={'auto'}
    >
      <Box display='flex' flexDirection='column' gap='24px'>
        <TabsWrapper width='100%'>
          <TabList gap='8px'>
            <TabItem
              text={DATA_APP_PROPERT_TABS.PROPERTIES}
              action={() => setActiveTab(DATA_APP_PROPERT_TABS.PROPERTIES)}
              flex={1}
            />
            <TabItem
              text={DATA_APP_PROPERT_TABS.FEEDBACK}
              action={() => setActiveTab(DATA_APP_PROPERT_TABS.FEEDBACK)}
              flex={1}
            />
          </TabList>
        </TabsWrapper>
        {activeTab === DATA_APP_PROPERT_TABS.FEEDBACK && (
          <>
            <Box display='flex' justifyContent='space-between' alignItems='center'>
              <Text size='sm' fontWeight='semibold'>
                Enable Feedback
              </Text>
              <Switch
                onChange={(event) => setIsFeedbackEnabled(event.target.checked)}
                isChecked={isFeedbackEnabled}
              />
            </Box>
            {isFeedbackEnabled && (
              <FeedbackConfigForm
                feedbackMethod={feedbackMethod}
                feedbackTitle={feedbackTitle}
                feedbackDescription={feedbackDescription}
                setFeedbackMethod={setFeedbackMethod}
                setFeedbackTitle={setFeedbackTitle}
                setFeedbackDescription={setFeedbackDescription}
                isAdditionalRemarks={isAdditionalRemarks}
                setIsAdditionalRemarks={setIsAdditionalRemarks}
                isAdditionalRemarksRequired={isAdditionalRemarksRequired}
                setIsAdditionalRemarksRequired={setIsAdditionalRemarksRequired}
                additionalRemarksTitle={additionalRemarksTitle}
                setAdditionalRemarksTitle={setAdditionalRemarksTitle}
                additionalRemarksDescription={additionalRemarksDescription}
                setAdditionalRemarksDescription={setAdditionalRemarksDescription}
                multipleChoiceConfig={multipleChoiceConfig}
                setMultipleChoiceConfig={setMultipleChoiceConfig}
              />
            )}
          </>
        )}
        {activeTab === DATA_APP_PROPERT_TABS.PROPERTIES && (
          <>
            <Box display='flex' flexDirection='column' gap='8px'>
              <Text size='sm' fontWeight='semibold'>
                {isChatbot ? 'Chat Title' : 'Card Title'}
              </Text>
              <Input
                data-testid='data-app-card-title-input'
                name='card_title'
                placeholder={isChatbot ? 'Enter a title for the chat' : 'Enter card title'}
                background='gray.100'
                resize='none'
                onChange={({ target: { value } }) => setCardTitle(value)}
                value={cardTitle || (isChatbot ? 'Chatbot' : '')}
                borderStyle='solid'
                borderWidth='1px'
                borderColor='gray.400'
                fontSize='14px'
              />
            </Box>
            {canConfigureColor && (
              <Box display='flex' flexDirection='column' gap='8px'>
                <Text size='sm' fontWeight='semibold'>
                  {isChatbot ? 'Chat Color' : 'Visual Color'}
                </Text>
                <Box display='flex' flexDirection='column' gap='4px'>
                  <InputGroup>
                    <InputLeftElement pointerEvents='none'>
                      <Box
                        width='16px'
                        height='16px'
                        backgroundColor={visualColor || 'transparent'}
                        borderRadius='2px'
                      />
                    </InputLeftElement>
                    {/* Visible input showing the hex code */}
                    <Input
                      tabIndex={-1}
                      name='visual_color_display'
                      placeholder='Enter visual color'
                      background='gray.100'
                      resize='none'
                      value={visualColor}
                      readOnly
                      borderStyle='solid'
                      borderWidth='1px'
                      borderColor='gray.400'
                      fontSize='14px'
                    />
                    {/* Hidden input for color picking */}
                    <Input
                      name='visual_color'
                      type='color'
                      position='absolute'
                      opacity='0'
                      width='100%'
                      height='100%'
                      onChange={({ target: { value } }) => setVisualColor(value)}
                      cursor='pointer'
                    />
                  </InputGroup>

                  <Text size='xs' color='gray.600' fontWeight={500}>
                    Shades of this color will be used in the visual.
                  </Text>
                </Box>
              </Box>
            )}
            {isChatbot && (
              <>
                <Box backgroundColor='gray.400'>
                  <Divider orientation='horizontal' />
                </Box>
                <Box display='flex' flexDirection='column' gap='8px'>
                  <Text size='sm' fontWeight='semibold'>
                    Welcome Message
                  </Text>
                  <Box display='flex' flexDirection='column' gap='4px'>
                    <Input
                      name='welcome_message'
                      placeholder='Enter a welcome message'
                      background='gray.100'
                      resize='none'
                      value={welcomeMessage || 'Start chatting with me'}
                      onChange={({ target: { value } }) => setWelcomeMessage(value)}
                      borderStyle='solid'
                      borderWidth='1px'
                      borderColor='gray.400'
                      fontSize='14px'
                    />
                    <Text size='xs' color='gray.600' fontWeight={500}>
                      This will appear when you open the chat.
                    </Text>
                  </Box>
                </Box>
                <Box display='flex' flexDirection='column' gap='8px'>
                  <Text size='sm' fontWeight='semibold'>
                    Responder Name
                  </Text>
                  <Input
                    name='responder_name'
                    placeholder='Enter a name for your responder'
                    background='gray.100'
                    resize='none'
                    value={responderName || 'Bot'}
                    onChange={({ target: { value } }) => setResponderName(value)}
                    borderStyle='solid'
                    borderWidth='1px'
                    borderColor='gray.400'
                    fontSize='14px'
                  />
                </Box>
                <Box display='flex' flexDirection='column' gap='8px'>
                  <Text size='sm' fontWeight='semibold'>
                    Avatar
                  </Text>
                  <Text size='xs' color='gray.600' fontWeight={500}>
                    This will appear as the avatar in the chat.
                  </Text>
                  <UploadChatbotAvatar
                    label='Avatar'
                    avatar={avatar}
                    setAvatar={setAvatar}
                    visualColor={visualColor}
                  />
                </Box>
              </>
            )}
          </>
        )}
      </Box>
    </Box>
  );
};

export default DataAppsProperties;
