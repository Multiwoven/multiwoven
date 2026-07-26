import { CustomSelect } from '@/components/CustomSelect/CustomSelect';
import InputField from '@/components/InputField';
import {
  Stack,
  HStack,
  Text,
  Collapse,
  Box,
  Tooltip as ChakraTooltip,
  Input,
} from '@chakra-ui/react';

import { Option } from '@/components/CustomSelect/Option';

import { EXPORT_OPTIONS, INTERFACE_POSITION_OPTIONS } from '../constants';
import useAgentStore from '@/enterprise/store/useAgentStore';
import { useEffect, useRef } from 'react';
import { FiInfo } from 'react-icons/fi';
import { INTERFACE_DISPLAY_TYPE } from '../types';

import { EmbeddableCodeSection } from './EmbeddableCodeSection';
import { ChromeExtensionSection } from './ChromeExtensionSection';
import { StandaloneAppSection } from './StandaloneAppSection';

type ChatbotExportConfigProps = {
  isExportOpen: boolean;
  agentId: string;
};

const ChatbotExportConfig = ({ isExportOpen, agentId }: ChatbotExportConfigProps) => {
  const { exportConfig, setExportConfig, interfaceDisplayType, interfaceConfig, workflowDataApp } =
    useAgentStore((state) => state);

  const methodPerDisplayType = useRef<Partial<Record<INTERFACE_DISPLAY_TYPE, string>>>({});
  const previousDisplayType = useRef<INTERFACE_DISPLAY_TYPE>(interfaceDisplayType);
  const isInitialized = useRef<boolean>(false);

  const availableExportOptions = EXPORT_OPTIONS.filter((option) =>
    option.displayTypes.includes(interfaceDisplayType),
  );

  useEffect(() => {
    const getAvailableOptions = () => {
      return EXPORT_OPTIONS.filter((option) => option.displayTypes.includes(interfaceDisplayType));
    };
    const apiExportConfig = interfaceConfig?.export_config;
    const availableOptions = getAvailableOptions();
    const displayTypeChanged = previousDisplayType.current !== interfaceDisplayType;

    // Helper to get embeddable assistant flag for current display type
    const getEmbeddableFlag = (method: string): boolean => {
      return interfaceDisplayType === INTERFACE_DISPLAY_TYPE.FULL_PAGE && method === 'embed';
    };

    // Get current config from store directly to avoid stale closures
    const getCurrentConfig = () => useAgentStore.getState().exportConfig;
    const updateConfig = useAgentStore.getState().setExportConfig;

    // Helper to update config if values differ
    const updateConfigIfNeeded = (method: string, embeddableAssistant: boolean) => {
      const currentConfig = getCurrentConfig();
      if (
        currentConfig.method !== method ||
        currentConfig.embeddable_assistant !== embeddableAssistant
      ) {
        updateConfig({
          ...currentConfig,
          method,
          embeddable_assistant: embeddableAssistant,
        });
      }
    };

    // Initialization logic
    if (!isInitialized.current) {
      const hasDataAppId = !!interfaceConfig?.dataAppId;

      if (!hasDataAppId && !apiExportConfig) return;

      const currentConfig = getCurrentConfig();

      // Get initial method and flag from API or existing config
      let method: string;
      let embeddableAssistant: boolean;

      if (apiExportConfig) {
        embeddableAssistant = apiExportConfig.embeddable_assistant ?? false;
        const currentMethod = apiExportConfig.method ?? 'embed';
        method = embeddableAssistant ? 'embed' : currentMethod;
      } else if (currentConfig.method && currentConfig.embeddable_assistant !== undefined) {
        embeddableAssistant = currentConfig.embeddable_assistant;
        method = embeddableAssistant ? 'embed' : currentConfig.method;
      } else {
        method = 'embed';
        embeddableAssistant = false;
      }

      // Validate method is available for current display type
      const currentOption = availableOptions.find((option) => option.value === method);
      if (!currentOption) {
        const firstOption = availableOptions[0];
        if (!firstOption) return;

        method = firstOption.value;
        embeddableAssistant = getEmbeddableFlag(method);
      }

      methodPerDisplayType.current[interfaceDisplayType] = method;
      updateConfigIfNeeded(method, embeddableAssistant);
      isInitialized.current = true;
      return;
    }

    // Handle display type change
    if (displayTypeChanged) {
      const currentConfig = getCurrentConfig();

      // Save previous method if it was valid
      const previousMethodWasValid = EXPORT_OPTIONS.some(
        (option) =>
          option.value === currentConfig.method &&
          option.displayTypes.includes(previousDisplayType.current),
      );

      if (previousMethodWasValid) {
        methodPerDisplayType.current[previousDisplayType.current] = currentConfig.method;
      }

      previousDisplayType.current = interfaceDisplayType;

      // Try to restore saved method for new display type
      const savedMethod = methodPerDisplayType.current[interfaceDisplayType];
      const savedMethodIsValid =
        savedMethod && availableOptions.some((option) => option.value === savedMethod);

      if (savedMethodIsValid) {
        const embeddableAssistant = getEmbeddableFlag(savedMethod);
        updateConfigIfNeeded(savedMethod, embeddableAssistant);
        return;
      }

      // Check if API value should be used
      const shouldUseApiValue =
        apiExportConfig?.embeddable_assistant &&
        interfaceDisplayType === INTERFACE_DISPLAY_TYPE.FULL_PAGE &&
        !savedMethod;

      if (shouldUseApiValue) {
        updateConfigIfNeeded('embed', true);
        methodPerDisplayType.current[interfaceDisplayType] = 'embed';
        return;
      }

      // Fall back to first available option
      const firstAvailableOption = availableOptions[0];
      if (!firstAvailableOption) return;

      const embeddableAssistant = getEmbeddableFlag(firstAvailableOption.value);
      updateConfigIfNeeded(firstAvailableOption.value, embeddableAssistant);
      methodPerDisplayType.current[interfaceDisplayType] = firstAvailableOption.value;
      return;
    }

    // Validate and update method (no display type change)
    const currentConfig = getCurrentConfig();

    if (currentConfig.embeddable_assistant && currentConfig.method !== 'embed') {
      updateConfig({ ...currentConfig, method: 'embed' });
      methodPerDisplayType.current[interfaceDisplayType] = 'embed';
      return;
    }

    const currentOption = availableOptions.find((option) => option.value === currentConfig.method);

    if (!currentOption) {
      const firstAvailableOption = availableOptions[0];
      if (!firstAvailableOption) return;

      const embeddableAssistant = getEmbeddableFlag(firstAvailableOption.value);
      updateConfig({
        ...currentConfig,
        method: firstAvailableOption.value,
        embeddable_assistant: embeddableAssistant,
      });
      methodPerDisplayType.current[interfaceDisplayType] = firstAvailableOption.value;
      return;
    }

    methodPerDisplayType.current[interfaceDisplayType] = currentConfig.method;

    const expectedEmbeddableAssistant = getEmbeddableFlag(currentConfig.method);

    if (currentConfig.embeddable_assistant !== expectedEmbeddableAssistant) {
      updateConfig({
        ...currentConfig,
        embeddable_assistant: expectedEmbeddableAssistant,
      });
    }
  }, [interfaceDisplayType, interfaceConfig?.dataAppId, interfaceConfig?.export_config]);

  return (
    <Collapse in={isExportOpen} animateOpacity>
      <Stack spacing='24px'>
        <Box display='flex' flexDirection='column' gap='8px'>
          <Text size='sm' fontWeight='semibold'>
            Method
          </Text>
          <CustomSelect
            data-testid='interface-export-method-select'
            name='method'
            value={exportConfig.method}
            onChange={(value) => {
              const isEmbeddableAssistant =
                interfaceDisplayType === INTERFACE_DISPLAY_TYPE.FULL_PAGE && value === 'embed';
              const newMethod = value as string;

              methodPerDisplayType.current[interfaceDisplayType] = newMethod;

              setExportConfig({
                ...exportConfig,
                method: newMethod,
                embeddable_assistant: isEmbeddableAssistant,
              });
            }}
            placeholder='Select a method'
          >
            {EXPORT_OPTIONS.filter((option) =>
              option.displayTypes.includes(interfaceDisplayType),
            ).map((option, index) => (
              <Option
                value={option.value}
                key={`export-option-${index}`}
                data-testid={`export-option-${option.value}`}
              >
                <HStack>
                  <Text size='sm' fontWeight={400}>
                    {option.label}
                  </Text>
                </HStack>
              </Option>
            ))}
          </CustomSelect>
          <Text size='xs' fontWeight={500} color='gray.600'>
            {
              availableExportOptions.find((option) => option.value === exportConfig.method)
                ?.helperText
            }
          </Text>
        </Box>

        {/* Dynamic content based on selected method */}
        {exportConfig.method === 'embed' && (
          <EmbeddableCodeSection
            dataAppId={interfaceConfig?.dataAppId}
            dataAppUseCaseId={interfaceConfig?.dataAppToken}
            dataAppEmbedMethod={workflowDataApp?.data_app?.meta_data?.rendering_type}
            currentMethod={exportConfig.method}
            embeddableAssistant={exportConfig.embeddable_assistant}
            publishedEmbeddableAssistant={
              workflowDataApp?.data_app?.meta_data?.embeddable_assistant
            }
            interfaceDisplayType={interfaceDisplayType}
          />
        )}
        {exportConfig.method === 'no_code' && (
          <ChromeExtensionSection
            dataAppEmbedMethod={workflowDataApp?.data_app?.meta_data?.rendering_type}
          />
        )}
        {exportConfig.method === 'assistant' && (
          <StandaloneAppSection
            workflowId={agentId}
            dataAppId={interfaceConfig?.dataAppId}
            dataAppEmbedMethod={workflowDataApp?.data_app?.meta_data?.rendering_type}
          />
        )}
        {exportConfig.method === 'embed' &&
          interfaceDisplayType === INTERFACE_DISPLAY_TYPE.FULL_PAGE && (
            <Box width='100%' display='flex' flexDirection='column' gap='8px'>
              <Text fontWeight='semibold' size='sm'>
                Query Selector
              </Text>

              <Input
                backgroundColor='gray.100'
                placeholder='[data-id = "tabpanel-general"]'
                onChange={(e) => {
                  setExportConfig({
                    ...exportConfig,
                    query_selector: e.target.value,
                  });
                }}
                value={exportConfig.query_selector}
                borderStyle='solid'
                borderWidth='1px'
                borderColor='gray.400'
                fontSize='14px'
                borderRadius='6px'
                _focusVisible={{ border: 'gray.400' }}
                _hover={{ border: 'gray.400' }}
                name='query_selector'
              />
              <Text color='gray.600' size='xs' fontWeight={500}>
                Container is injected at the body of the content by default. Use query selectors to
                inject in specific elements.
              </Text>
            </Box>
          )}
        {(exportConfig.method === 'no_code' || exportConfig.method === 'embed') &&
          !exportConfig.embeddable_assistant &&
          interfaceDisplayType === INTERFACE_DISPLAY_TYPE.MOBILE && (
            <>
              <Box display='flex' flexDirection='column' gap='8px'>
                <Box display='flex' alignItems='center' gap='8px'>
                  <Text size='sm' fontWeight='semibold'>
                    Interface Position
                  </Text>
                  <ChakraTooltip
                    hasArrow
                    label='Control the position of the interface on the page.'
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
                <CustomSelect
                  name='interface_position'
                  value={exportConfig.interface_position}
                  onChange={(value) => {
                    setExportConfig({
                      ...exportConfig,
                      interface_position: value as string,
                    });
                  }}
                >
                  {INTERFACE_POSITION_OPTIONS.map((option, index) => (
                    <Option value={option.value} key={`export-option-${index}`}>
                      <HStack>
                        <Text size='sm' fontWeight={400}>
                          {option.label}
                        </Text>
                      </HStack>
                    </Option>
                  ))}
                </CustomSelect>
              </Box>
            </>
          )}
        {exportConfig.method === 'no_code' && (
          <InputField
            label='Whitelist URLs'
            name='whitelist_urls'
            value={exportConfig.whitelist_urls?.join(', ') || ''}
            onChange={(value) => {
              setExportConfig({
                ...exportConfig,
                whitelist_urls: value.target.value.split(',').map((url) => url.trim()),
              });
            }}
            isTooltip
            tooltipLabel={
              'Specify which URLs the chatbot can be embedded on. Enter comma-separated URLs to restrict where the interface appears.'
            }
            placeholder='Enter one or more URLs separated by commas.'
          />
        )}
      </Stack>
    </Collapse>
  );
};

export default ChatbotExportConfig;
