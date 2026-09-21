import {
  Box,
  Button,
  Flex,
  Icon,
  Input,
  InputGroup,
  InputRightElement,
  IconButton,
  Tag,
  Text,
  Wrap,
  WrapItem,
  useDisclosure,
} from '@chakra-ui/react';
import { useCallback, useMemo } from 'react';
import {
  FiTool,
  FiKey,
  FiRefreshCw,
  FiEye,
  FiEyeOff,
  FiInfo,
  FiLink,
  FiCheck,
} from 'react-icons/fi';
import useCustomToast from '@/hooks/useCustomToast';
import { CustomToastStatus } from '@/components/Toast';
import useAgentStore from '@/enterprise/store/useAgentStore';
import ToolTip from '@/components/ToolTip';
import useAgentMutations from '@/enterprise/hooks/mutations/useAgentMutations';
import { A2AAgentCard, A2ASkill } from '@/enterprise/services/types';

interface A2AConfiguration {
  url?: string;
  api_key?: string;
  agent_card?: A2AAgentCard;
  skills?: A2ASkill[];
}

const TOAST_POSITION = 'bottom-right';

const getValidSkills = (skills?: A2ASkill[]) =>
  (skills ?? []).filter((skill) => skill.name?.trim().length > 0);

const A2ASkillsSection = () => {
  const { isOpen: isApiKeyVisible, onToggle: toggleApiKeyVisible } = useDisclosure();
  const toast = useCustomToast();
  const { fetchAgentCard } = useAgentMutations();

  const currentWorkflow = useAgentStore((state) => state.currentWorkflow);
  const selectedComponent = useAgentStore((state) => state.selectedComponent);
  const setSelectedComponent = useAgentStore((state) => state.setSelectedComponent);
  const setWorkflow = useAgentStore((state) => state.setWorkflow);
  const updateNodeById = useAgentStore((state) => state.updateNodeById);

  const config = useMemo(
    () => (selectedComponent?.configuration ?? {}) as A2AConfiguration,
    [selectedComponent],
  );
  const skills = useMemo(() => getValidSkills(config.skills), [config.skills]);
  const hasSkills = skills.length > 0;

  const showToast = useCallback(
    (title: string, description: string, status: CustomToastStatus) => {
      toast({
        title,
        description,
        status,
        isClosable: true,
        position: TOAST_POSITION,
      });
    },
    [toast],
  );

  const updateConfig = useCallback(
    (patch: Partial<A2AConfiguration>) => {
      if (!selectedComponent) return;
      const updatedComponent = {
        ...selectedComponent,
        configuration: {
          ...selectedComponent.configuration,
          ...(patch as Record<string, unknown>),
        },
      } as typeof selectedComponent;
      setSelectedComponent(updatedComponent);
      updateNodeById(selectedComponent.id, updatedComponent);

      // Sync to workflow payload so auto-save persists the change
      if (currentWorkflow) {
        const updatedWorkflow = { ...currentWorkflow };
        const componentIndex = updatedWorkflow.workflow.components.findIndex(
          (c) => c.id === selectedComponent.id,
        );
        if (componentIndex > -1) {
          updatedWorkflow.workflow.components = [...updatedWorkflow.workflow.components];
          updatedWorkflow.workflow.components[componentIndex] = updatedComponent;
          if (currentWorkflow.workflow.status === 'published') {
            updatedWorkflow.workflow = { ...updatedWorkflow.workflow, status: 'draft' as const };
          }
          setWorkflow(updatedWorkflow);
        }
      }
    },
    [currentWorkflow, selectedComponent, setSelectedComponent, setWorkflow, updateNodeById],
  );

  const handleConnect = useCallback(async () => {
    if (fetchAgentCard.isPending) return;

    const url = (config.url ?? '').trim();
    if (!url) {
      showToast(
        'Agent Endpoint URL is required',
        'Please enter the agent endpoint URL before connecting.',
        CustomToastStatus.Warning,
      );
      return;
    }

    try {
      const data = await fetchAgentCard.mutateAsync({
        connection_spec: {
          url,
          ...(config.api_key?.trim() ? { api_key: config.api_key.trim() } : {}),
        },
      });

      if (data.connection_status?.status === 'failed') {
        showToast('Connection failed', data.connection_status.message, CustomToastStatus.Error);
        return;
      }

      const loadedSkills = getValidSkills(data.skills ?? data.agent_card?.skills);
      updateConfig({ agent_card: data.agent_card, skills: loadedSkills, url });

      showToast(
        'Connected successfully',
        data.connection_status?.message ?? 'Agent skills loaded successfully.',
        CustomToastStatus.Success,
      );
    } catch (err: unknown) {
      showToast(
        'Connection failed',
        err instanceof Error ? err.message : 'Could not reach the remote agent.',
        CustomToastStatus.Error,
      );
    }
  }, [config.api_key, config.url, fetchAgentCard, showToast, updateConfig]);

  return (
    <Flex flexDir='column' gap='20px'>
      {/* Agent Endpoint URL */}
      <Flex flexDir='column' gap='8px'>
        <Flex gap='8px' alignItems='center'>
          <Text size='sm' fontWeight={600}>
            Agent Endpoint URL
          </Text>
          <ToolTip label='The base URL of the agent service you want this workflow to communicate with.'>
            <Box color='gray.600'>
              <FiInfo size='14px' />
            </Box>
          </ToolTip>
        </Flex>
        <InputGroup>
          <Input
            data-testid='workflow-config-a2a-endpoint-url-input'
            value={config.url ?? ''}
            placeholder='https://my-agent.example.com'
            onChange={(e) => updateConfig({ url: e.target.value })}
            pl='36px'
            borderColor={hasSkills ? 'success.400' : undefined}
            _hover={hasSkills ? { borderColor: 'success.400' } : undefined}
            _focusVisible={
              hasSkills ? { borderColor: 'success.400', boxShadow: 'none' } : undefined
            }
          />
          <Box position='absolute' left='10px' top='50%' transform='translateY(-50%)' zIndex={1}>
            <Icon as={FiLink} color={'gray.600'} boxSize='14px' />
          </Box>
          {hasSkills && (
            <InputRightElement pointerEvents='none'>
              <Icon as={FiCheck} color='green.400' boxSize='16px' />
            </InputRightElement>
          )}
        </InputGroup>

        {/* Skills — shown inline below URL once loaded, attached to the input */}
        {hasSkills && (
          <Box
            bg='gray.50'
            borderLeft='1px solid'
            borderRight='1px solid'
            borderBottom='1px solid'
            borderColor='gray.300'
            borderBottomRadius='6px'
            p='16px'
            pt='24px'
            marginTop='-14px'
          >
            <Flex gap='4px' alignItems='center' mb='8px'>
              <Text
                size='xs'
                fontWeight={700}
                color='gray.600'
                letterSpacing='2.4px'
                textTransform='uppercase'
              >
                Skills
              </Text>
              <Text size='xs' color='gray.600' fontWeight={400}>
                (read only)
              </Text>
            </Flex>
            <Wrap spacing='6px'>
              {skills.map((skill) => (
                <WrapItem key={skill.id}>
                  <Tag
                    size='sm'
                    variant='outline'
                    colorScheme='gray'
                    gap='4px'
                    px='8px'
                    py='4px'
                    borderRadius='4px'
                    borderColor='gray.500'
                    backgroundColor='gray.300'
                  >
                    <Icon as={FiTool} boxSize='10px' color='black.300' />
                    <Text size='xs' color='black.300' fontWeight={600}>
                      {skill.name}
                    </Text>
                  </Tag>
                </WrapItem>
              ))}
            </Wrap>
          </Box>
        )}
      </Flex>

      {/* API Key / Auth token */}
      <Flex flexDir='column' gap='8px'>
        <Flex gap='8px' alignItems='center'>
          <Text size='sm' fontWeight={600}>
            API Key / Auth token
          </Text>
          <ToolTip label='Optional. Provide an API key or token if the agent endpoint requires authentication.'>
            <Box color='gray.600'>
              <FiInfo size='14px' />
            </Box>
          </ToolTip>
        </Flex>
        <InputGroup>
          <Input
            data-testid='workflow-config-a2a-api-key-input'
            value={config.api_key ?? ''}
            type={isApiKeyVisible ? 'text' : 'password'}
            placeholder='••••••••••••••••••••'
            onChange={(e) => updateConfig({ api_key: e.target.value })}
            pl='36px'
          />
          <Box position='absolute' left='10px' top='50%' transform='translateY(-50%)' zIndex={1}>
            <Icon as={FiKey} color='gray.600' boxSize='14px' />
          </Box>
          <InputRightElement>
            <IconButton
              variant='text'
              color='gray.600'
              aria-label={isApiKeyVisible ? 'Hide token' : 'Show token'}
              icon={isApiKeyVisible ? <FiEyeOff /> : <FiEye />}
              onClick={toggleApiKeyVisible}
              size='sm'
            />
          </InputRightElement>
        </InputGroup>
      </Flex>

      <Button
        data-testid='workflow-config-a2a-connect-skills-button'
        variant='outline'
        w='100%'
        gap='8px'
        onClick={handleConnect}
        isLoading={fetchAgentCard.isPending}
        loadingText='Connecting...'
        isDisabled={!config.url?.trim()}
      >
        <Icon as={FiRefreshCw} />
        {hasSkills ? 'Refresh Skills' : 'Connect & Load Skills'}
      </Button>
    </Flex>
  );
};

export default A2ASkillsSection;
