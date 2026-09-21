import {
  Stack,
  Button,
  HStack,
  Icon,
  Text,
  Collapse,
  Box,
  Divider,
  Switch,
} from '@chakra-ui/react';
import { useState } from 'react';
import { FiChevronDown, FiChevronUp } from 'react-icons/fi';
import { INTERFACE_TYPE } from '../types';
import FeedbackConfigForm from '../../DataApps/DataAppsForm/BuildDataApp/FeedbackConfigForm';
import { FEEDBACK_METHODS } from '@/enterprise/dataApps/feedbackTypes';
import { WorkflowInterfaceConfig } from '@/enterprise/services/types';

import { useParams } from 'react-router-dom';

import ChatGeneralConfig from './ChatGeneralConfig';
import ApiGeneralConfig from './ApiInterface/ApiGeneralConfig';
import SlackGeneralConfig from './SlackInterface/SlackGeneralConfig';
import SlackExportConfig from './SlackInterface/SlackExportConfig';
import ChatbotExportConfig from './ChatbotExportConfig';
import Security from './Security/Security';

const ConfigWrapper = ({
  selectedInterfaceType,
  interfaceComponentConfig,
  setInterfaceComponentConfig,
}: {
  selectedInterfaceType: INTERFACE_TYPE;
  interfaceComponentConfig: WorkflowInterfaceConfig;
  setInterfaceComponentConfig: (config: WorkflowInterfaceConfig) => void;
}) => {
  const [openState, setOpenState] = useState({
    isGeneralOpen: true,
    isFeedbackOpen: false,
    isSecurityOpen: false,
    isExportOpen: false,
  });

  const params = useParams();

  const agentId = params.id ?? '';

  return (
    <Box display='flex' flexDirection='column' gap='20px' overflowY='auto' overflowX='hidden'>
      <Stack spacing={0} flex={1}>
        <Button
          variant='tertiary'
          justifyContent='start'
          backgroundColor={'none'}
          width='100%'
          size='sm'
          height='36px'
          onClick={() => {
            setOpenState({
              isGeneralOpen: !openState.isGeneralOpen,
              isFeedbackOpen: false,
              isSecurityOpen: false,
              isExportOpen: false,
            });
          }}
          padding='0px'
        >
          <HStack justifyContent='space-between' width='full'>
            <HStack spacing='2'>
              <Text color='gray.600' fontWeight='bold' size='xs' letterSpacing='2.4px'>
                GENERAL
              </Text>
            </HStack>
            <Icon
              as={openState.isGeneralOpen ? FiChevronUp : FiChevronDown}
              color='gray.600'
              height='16px'
              width='16px'
            />
          </HStack>
        </Button>
        <Collapse in={openState.isGeneralOpen} animateOpacity>
          {selectedInterfaceType === INTERFACE_TYPE.WEBSITE_CHATBOT && (
            <ChatGeneralConfig interfaceComponentConfig={interfaceComponentConfig} />
          )}
          {selectedInterfaceType === INTERFACE_TYPE.API_INTERFACE && <ApiGeneralConfig />}
          {selectedInterfaceType === INTERFACE_TYPE.SLACK_APP && <SlackGeneralConfig />}
        </Collapse>
      </Stack>
      {(selectedInterfaceType === INTERFACE_TYPE.WEBSITE_CHATBOT ||
        selectedInterfaceType === INTERFACE_TYPE.SLACK_APP) && (
        <>
          <Divider borderColor='gray.400' borderWidth='1px' />
          <Stack spacing={0} flex={1}>
            <Button
              variant='tertiary'
              justifyContent='start'
              backgroundColor={'none'}
              width='100%'
              size='sm'
              height='36px'
              onClick={() => {
                setOpenState({
                  isGeneralOpen: false,
                  isFeedbackOpen: !openState.isFeedbackOpen,
                  isSecurityOpen: false,
                  isExportOpen: false,
                });
              }}
              padding='0px'
            >
              <HStack justifyContent='space-between' width='full'>
                <HStack spacing='2'>
                  <Text color='gray.600' fontWeight='bold' size='xs' letterSpacing='2.4px'>
                    FEEDBACK
                  </Text>
                </HStack>
                <Icon
                  as={openState.isFeedbackOpen ? FiChevronUp : FiChevronDown}
                  color='gray.600'
                  height='16px'
                  width='16px'
                />
              </HStack>
            </Button>

            <Collapse in={openState.isFeedbackOpen} animateOpacity>
              <Stack spacing='24px' marginTop='24px' minHeight='40vh' overflow='hidden'>
                <Box display='flex' justifyContent='space-between' alignItems='center'>
                  <Text size='sm' fontWeight='semibold'>
                    Enable Feedback
                  </Text>
                  <Switch
                    onChange={(event) => {
                      setInterfaceComponentConfig({
                        ...interfaceComponentConfig,
                        feedback_config: {
                          ...interfaceComponentConfig.feedback_config,
                          feedback_enabled: event.target.checked,
                        },
                      });
                    }}
                    isChecked={interfaceComponentConfig.feedback_config.feedback_enabled}
                  />
                </Box>
                {interfaceComponentConfig.feedback_config.feedback_enabled && (
                  <FeedbackConfigForm
                    feedbackMethod={
                      INTERFACE_TYPE.SLACK_APP === selectedInterfaceType
                        ? FEEDBACK_METHODS.THUMBS_RATING
                        : interfaceComponentConfig.feedback_config.feedback_method
                    }
                    disableFeedbackMethod={INTERFACE_TYPE.SLACK_APP === selectedInterfaceType}
                    disableAdditionalRemarks={INTERFACE_TYPE.SLACK_APP === selectedInterfaceType}
                    feedbackTitle={interfaceComponentConfig.feedback_config.feedback_title}
                    feedbackDescription={
                      interfaceComponentConfig.feedback_config.feedback_description || ''
                    }
                    setFeedbackMethod={(value) => {
                      setInterfaceComponentConfig({
                        ...interfaceComponentConfig,
                        feedback_config: {
                          ...interfaceComponentConfig.feedback_config,
                          feedback_method:
                            INTERFACE_TYPE.SLACK_APP === selectedInterfaceType
                              ? FEEDBACK_METHODS.THUMBS_RATING
                              : (value as FEEDBACK_METHODS),
                        },
                      });
                    }}
                    setFeedbackTitle={(value) => {
                      setInterfaceComponentConfig({
                        ...interfaceComponentConfig,
                        feedback_config: {
                          ...interfaceComponentConfig.feedback_config,
                          feedback_title: value,
                        },
                      });
                    }}
                    setFeedbackDescription={(value) => {
                      setInterfaceComponentConfig({
                        ...interfaceComponentConfig,
                        feedback_config: {
                          ...interfaceComponentConfig.feedback_config,
                          feedback_description: value,
                        },
                      });
                    }}
                    isAdditionalRemarks={
                      interfaceComponentConfig.feedback_config.additional_remarks?.enabled || false
                    }
                    setIsAdditionalRemarks={(value) => {
                      setInterfaceComponentConfig({
                        ...interfaceComponentConfig,
                        feedback_config: {
                          ...interfaceComponentConfig.feedback_config,
                          additional_remarks: {
                            ...interfaceComponentConfig.feedback_config.additional_remarks,
                            enabled: value,
                          },
                        },
                      });
                    }}
                    isAdditionalRemarksRequired={
                      interfaceComponentConfig.feedback_config.additional_remarks?.required || false
                    }
                    setIsAdditionalRemarksRequired={(value) => {
                      setInterfaceComponentConfig({
                        ...interfaceComponentConfig,
                        feedback_config: {
                          ...interfaceComponentConfig.feedback_config,
                          additional_remarks: {
                            ...interfaceComponentConfig.feedback_config.additional_remarks,
                            required: value,
                          },
                        },
                      });
                    }}
                    additionalRemarksTitle={
                      interfaceComponentConfig.feedback_config.additional_remarks?.title || ''
                    }
                    setAdditionalRemarksTitle={(value) => {
                      setInterfaceComponentConfig({
                        ...interfaceComponentConfig,
                        feedback_config: {
                          ...interfaceComponentConfig.feedback_config,
                          additional_remarks: {
                            ...interfaceComponentConfig.feedback_config.additional_remarks,
                            title: value,
                          },
                        },
                      });
                    }}
                    additionalRemarksDescription={
                      interfaceComponentConfig.feedback_config.additional_remarks?.description || ''
                    }
                    setAdditionalRemarksDescription={(value) => {
                      setInterfaceComponentConfig({
                        ...interfaceComponentConfig,
                        feedback_config: {
                          ...interfaceComponentConfig.feedback_config,
                          additional_remarks: {
                            ...interfaceComponentConfig.feedback_config.additional_remarks,
                            description: value,
                          },
                        },
                      });
                    }}
                    multipleChoiceConfig={{
                      type: interfaceComponentConfig.feedback_config.multiple_choice.type,
                      choices: interfaceComponentConfig.feedback_config.multiple_choice.choices,
                    }}
                    setMultipleChoiceConfig={(value) => {
                      setInterfaceComponentConfig({
                        ...interfaceComponentConfig,
                        feedback_config: {
                          ...interfaceComponentConfig.feedback_config,
                          multiple_choice: value,
                        },
                      });
                    }}
                  />
                )}
              </Stack>
            </Collapse>
          </Stack>
        </>
      )}
      {(selectedInterfaceType === INTERFACE_TYPE.WEBSITE_CHATBOT ||
        selectedInterfaceType === INTERFACE_TYPE.CHAT_ASSISTANT) && (
        <>
          <Divider borderColor='gray.400' borderWidth='1px' />
          <Stack spacing={0} flex={1}>
            <Button
              variant='tertiary'
              justifyContent='start'
              backgroundColor={'none'}
              width='100%'
              size='sm'
              height='36px'
              onClick={() => {
                setOpenState({
                  isGeneralOpen: false,
                  isFeedbackOpen: false,
                  isSecurityOpen: !openState.isSecurityOpen,
                  isExportOpen: false,
                });
              }}
              padding='0px'
            >
              <HStack justifyContent='space-between' width='full'>
                <HStack spacing='2'>
                  <Text color='gray.600' fontWeight='bold' size='xs' letterSpacing='2.4px'>
                    SECURITY
                  </Text>
                </HStack>
                <Icon
                  as={openState.isSecurityOpen ? FiChevronUp : FiChevronDown}
                  color='gray.600'
                  height='16px'
                  width='16px'
                />
              </HStack>
            </Button>
            <Collapse in={openState.isSecurityOpen} animateOpacity>
              <Security />
            </Collapse>
          </Stack>
        </>
      )}
      {selectedInterfaceType !== INTERFACE_TYPE.API_INTERFACE && (
        <>
          <Divider borderColor='gray.400' borderWidth='1px' />
          <Stack spacing={0} flex={1} gap='24px'>
            <Button
              data-testid='interface-export-section-toggle'
              variant='tertiary'
              justifyContent='start'
              backgroundColor={'none'}
              width='100%'
              size='sm'
              height='36px'
              onClick={() => {
                setOpenState({
                  isGeneralOpen: false,
                  isFeedbackOpen: false,
                  isSecurityOpen: false,
                  isExportOpen: !openState.isExportOpen,
                });
              }}
              padding='0px'
            >
              <HStack justifyContent='space-between' width='full'>
                <HStack spacing='2'>
                  <Text color='gray.600' fontWeight='bold' size='xs' letterSpacing='2.4px'>
                    EXPORT
                  </Text>
                </HStack>
                <Icon
                  as={openState.isExportOpen ? FiChevronUp : FiChevronDown}
                  color='gray.600'
                  height='16px'
                  width='16px'
                />
              </HStack>
            </Button>
            {selectedInterfaceType === INTERFACE_TYPE.WEBSITE_CHATBOT && (
              <ChatbotExportConfig isExportOpen={openState.isExportOpen} agentId={agentId} />
            )}
            {selectedInterfaceType === INTERFACE_TYPE.SLACK_APP && (
              <Collapse in={openState.isExportOpen} animateOpacity>
                <SlackExportConfig />
              </Collapse>
            )}
          </Stack>
        </>
      )}
    </Box>
  );
};

export default ConfigWrapper;
