import {
  Box,
  Text,
  Button,
  IconButton,
  TabList,
  Flex,
  Image,
  useDisclosure,
  Icon,
  usePopoverContext,
  FormControl,
  FormLabel,
  Textarea,
} from '@chakra-ui/react';
import { useState, useEffect } from 'react';
import {
  FiArrowLeft,
  FiBarChart2,
  FiBookOpen,
  FiMonitor,
  FiRefreshCcw,
  FiClock,
} from 'react-icons/fi';
import { useNavigate, useParams } from 'react-router-dom';
import TabsWrapper from '@/components/TabsWrapper';
import TabItem from '@/components/TabItem';
import useAgentStore from '@/enterprise/store/useAgentStore';
import { useAutoSaveWorkflow } from '@/enterprise/hooks/useAutoSaveWorkflow';
import { keyframes } from '@chakra-ui/react';
import useAgentValidation from '@/enterprise/hooks/useAgentValidation';
import WorkflowTabIcon from '@/assets/icons/workflow.svg';
import ToolTip from '@/components/ToolTip';
import { DOCS_URL } from '@/enterprise/app-constants';
import BaseModal from '@/components/BaseModal';
import useDataAppMutations from '@/enterprise/hooks/mutations/useDataAppMutations';
import WorkflowPlayground from './Playground/WorkflowPlayground';
import { INTERFACE_TYPE } from '../types';
import AgentWorkflowReports from '../../Reports/AgentWorkflowReports';
import { FeatureFlagWrapper } from '@/components/FeatureFlagWrapper/FeatureFlagWrapper';
import HorizontalMenuActions from '@/components/HorizontalMenuActions/HorizontalMenuActions';
import VersionsPanel from './Versions/VersionsPanel';

const spin = keyframes`
  from { transform: rotate(0deg); }
  to { transform: rotate(360deg); }
`;

const AutosaveStatus = ({
  isSaving,
  status,
}: {
  isSaving: boolean;
  status: 'draft' | 'published';
}) => {
  return (
    <Flex alignItems='center' gap='4px' data-testid='workflow-autosave-status' aria-live='polite'>
      {isSaving ? (
        <Box animation={`${spin} 1s linear infinite`}>
          <FiRefreshCcw size='12px' />
        </Box>
      ) : (
        <Box width='6px' height='6px' rounded='full' bgColor='success.400' />
      )}
      <Text size='xs' color='black100'>
        {isSaving ? 'Saving...' : status === 'published' ? 'Live' : 'Saved as draft'}
      </Text>
    </Flex>
  );
};

const VersionsMenuItem = ({ onClick }: { onClick: () => void }) => {
  const { onClose } = usePopoverContext();
  return (
    <Flex
      data-testid='workflow-versions-toggle'
      align='center'
      p='8px 12px'
      gap='8px'
      borderRadius='4px'
      _hover={{ bg: 'gray.200' }}
      cursor='pointer'
      onClick={() => {
        onClick();
        onClose();
      }}
    >
      <Icon as={FiClock} boxSize={4} color='gray.600' />
      <Text
        fontSize='14px'
        lineHeight='20px'
        fontWeight='400'
        color='black.500'
        letterSpacing='-0.01em'
      >
        Versions
      </Text>
    </Flex>
  );
};

const AgentWorkflowHeader = ({
  activeTab,
  setActiveTab,
}: {
  activeTab: number;
  setActiveTab: (tab: number) => void;
}): JSX.Element => {
  const { isOpen, onOpen, onClose, onToggle } = useDisclosure();
  const {
    isOpen: isReportsOpen,
    onOpen: onReportsOpen,
    onToggle: onReportsToggle,
  } = useDisclosure();
  const navigate = useNavigate();
  const params = useParams();
  const {
    currentWorkflow,
    setWorkflow,
    triggerType,
    interfaceConfig,
    exportConfig,
    setInterfaceConfig,
    selectedComponent,
    setSelectedComponent,
  } = useAgentStore((state) => state);
  const [isVersionsOpen, setVersionsOpen] = useState(false);
  const [versionDescription, setVersionDescription] = useState('');
  const agentId = params.id ?? '';
  const { isPending } = useAutoSaveWorkflow(agentId, activeTab === 1);

  // Close VersionsPanel when Configbar opens (component is selected)
  // Component selection happens in AgentWorkflowCanvas, so we need to react to that state change
  useEffect(() => {
    if (selectedComponent) {
      setVersionsOpen(false);
    }
  }, [selectedComponent]);
  const { validateAgent } = useAgentValidation();
  const { createDataApp, updateDataApp } = useDataAppMutations();
  const dataAppId = interfaceConfig.dataAppId;
  const version = currentWorkflow?.workflow?.version_number
    ? `v${currentWorkflow.workflow.version_number}`
    : null;

  const handleSave = async (activeTab: number) => {
    if (activeTab !== 1) {
      setWorkflow({
        workflow: {
          ...currentWorkflow!.workflow,
          configuration: {
            ...currentWorkflow!.workflow.configuration,
            interface: {
              ...interfaceConfig,
              export_config: exportConfig,
            },
          },
          trigger_type: triggerType,
          status: 'published',
          version_description: versionDescription,
        },
      });
      setVersionDescription('');
      onClose();
      return;
    }

    const renderingType = exportConfig.embeddable_assistant ? 'embed' : exportConfig.method;

    const dataAppCreatePayload = {
      data_app: {
        name:
          (triggerType === INTERFACE_TYPE.API_INTERFACE ||
            triggerType === INTERFACE_TYPE.SLACK_APP) &&
          currentWorkflow?.workflow?.name
            ? currentWorkflow.workflow.name
            : interfaceConfig.properties.card_title,
        description: '',
        meta_data: {
          rendering_type: renderingType,
          container_position: exportConfig.interface_position,
          whitelist_urls: exportConfig.whitelist_urls,
          workflow_name: currentWorkflow?.workflow.name,
          embeddable_assistant: exportConfig.embeddable_assistant,
          query_selector: exportConfig.query_selector,
          version_description: versionDescription,
        },
        visual_components: [
          {
            ...interfaceConfig,
            component_type: 'chat_bot',
            configurable_id: agentId,
            configurable_type: 'workflow',
          },
        ],
        rendering_type: renderingType,
      },
    };

    const response = dataAppId
      ? await updateDataApp.mutateAsync({
          id: dataAppId,
          data: dataAppCreatePayload,
        })
      : await createDataApp.mutateAsync(dataAppCreatePayload);

    if (!response?.data?.attributes) {
      onClose();
      return;
    }

    const updatedInterfaceConfig = {
      ...interfaceConfig,
      export_config: exportConfig,
      dataAppId: response.data.id.toString(),
      dataAppToken: response.data.attributes.data_app_token,
    };

    setInterfaceConfig(updatedInterfaceConfig);
    setWorkflow({
      workflow: {
        ...currentWorkflow!.workflow,
        configuration: {
          ...currentWorkflow!.workflow.configuration,
          interface: {
            ...updatedInterfaceConfig,
            component_type: 'chat_bot',
            configurable_id: agentId,
            configurable_type: 'workflow',
          },
        },
        trigger_type: triggerType,
        status: currentWorkflow?.workflow?.status ?? 'draft',
        version_description: versionDescription,
      },
    });

    setVersionDescription('');
    onClose();
  };

  const onSaveChanges = () => {
    if (!validateAgent()) {
      return;
    }
    onOpen();
  };

  return (
    <Box
      padding='20px'
      borderBottomWidth='1px'
      borderBottomColor='gray.400'
      display='flex'
      justifyContent='space-between'
      alignItems='center'
    >
      <Box display='flex' flexDirection='row' alignItems='center' gap='8px'>
        <Box
          onClick={() => {
            setWorkflow(null);
            navigate('/agents');
          }}
          cursor='pointer'
          color='gray.600'
        >
          <FiArrowLeft size={24} />
        </Box>
        <Flex alignItems='center' gap='12px'>
          <Text size='xl' fontWeight='bold'>
            {currentWorkflow?.workflow?.name || 'Untitled Workflow'}
          </Text>
          {activeTab === 0 && (
            <AutosaveStatus
              isSaving={isPending}
              status={currentWorkflow?.workflow.status ?? 'draft'}
            />
          )}
          {version && (
            <Box
              data-testid='workflow-version-chip'
              bg='gray.200'
              color='black.300'
              fontSize='12px'
              lineHeight='18px'
              fontWeight='600'
              px='8px'
              py='2px'
              borderRadius='4px'
              border='1px solid'
              borderColor='gray.500'
            >
              {version}
            </Box>
          )}
        </Flex>
      </Box>
      <TabsWrapper index={activeTab} onChange={(tabIndex) => setActiveTab(tabIndex)}>
        <TabList gap='8px'>
          <Box data-testid='tab-workflow'>
            <TabItem text='Workflow' icon={<Image src={WorkflowTabIcon} />} />
          </Box>
          <Box data-testid='tab-interface'>
            <TabItem text='Interface' icon={<FiMonitor />} />
          </Box>
        </TabList>
      </TabsWrapper>
      <Box display='flex' flexDirection='row' alignItems='center' gap='12px'>
        <FeatureFlagWrapper flags={['workflowReports']}>
          <IconButton
            aria-label='Reports'
            variant={'outline'}
            minWidth={0}
            width='auto'
            padding='16px'
            onClick={onReportsOpen}
            icon={<FiBarChart2 size={16} color='black' />}
          />
        </FeatureFlagWrapper>
        {activeTab === 0 && <WorkflowPlayground />}
        <ToolTip
          label={
            activeTab === 0 && currentWorkflow?.workflow?.status === 'published'
              ? 'Workflow already published'
              : ''
          }
        >
          <Button
            variant={'solid'}
            data-testid={activeTab === 0 ? 'workflow-publish-btn' : 'interface-save-btn'}
            minWidth={0}
            width='auto'
            isDisabled={activeTab === 0 && currentWorkflow?.workflow?.status === 'published'}
            onClick={onSaveChanges}
            isLoading={isPending && currentWorkflow?.workflow?.status === 'published'}
            loadingText={activeTab === 0 ? 'Publish Workflow' : 'Save Interface'}
          >
            {activeTab === 0 ? 'Publish Workflow' : 'Save Interface'}
          </Button>
        </ToolTip>
        <Box data-testid='workflow-editor-overflow-menu'>
          <HorizontalMenuActions
            variant='light'
            padding='20px'
            contentWidth='152px'
            ml={0}
            placement='bottom-end'
          >
            <>
              <VersionsMenuItem
                onClick={() => {
                  setSelectedComponent(null);
                  setVersionsOpen(true);
                  onClose();
                }}
              />
              <a href={DOCS_URL} target='_blank' rel='noreferrer'>
                <Flex
                  align='center'
                  p='8px 12px'
                  gap='8px'
                  borderRadius='4px'
                  _hover={{ bg: 'gray.200' }}
                  cursor='pointer'
                  onClick={() => {
                    onClose();
                  }}
                >
                  <Icon as={FiBookOpen} boxSize={4} color='gray.600' />
                  <Text
                    fontSize='14px'
                    lineHeight='20px'
                    fontWeight='400'
                    color='black.500'
                    letterSpacing='-0.01em'
                  >
                    Documentation
                  </Text>
                </Flex>
              </a>
            </>
          </HorizontalMenuActions>
        </Box>
      </Box>
      <BaseModal
        title={
          activeTab === 0 ? (
            <Flex align='center' gap='4px'>
              <Text as='span'>Publish workflow</Text>
              {version && (
                <Text as='span' fontSize='12px' fontWeight='400' color='black.100'>
                  • {version}
                </Text>
              )}
            </Flex>
          ) : (
            'Save interface'
          )
        }
        description={
          activeTab === 0
            ? 'Are you sure you want to publish this workflow?'
            : 'Are you sure you want to save this interface?'
        }
        openModal={isOpen}
        setModalOpen={onToggle}
        footer={
          <Flex gap='12px' justifyContent='end'>
            <Button
              variant='ghost'
              w='fit-content'
              onClick={onClose}
              isDisabled={updateDataApp.isPending || createDataApp.isPending}
            >
              Cancel
            </Button>
            <Button
              type='submit'
              data-testid={activeTab === 0 ? 'workflow-publish-confirm' : 'interface-save-confirm'}
              paddingX={4}
              minWidth='0'
              width='auto'
              isDisabled={updateDataApp.isPending || createDataApp.isPending}
              isLoading={updateDataApp.isPending || createDataApp.isPending}
              onClick={() => handleSave(activeTab)}
            >
              Confirm
            </Button>
          </Flex>
        }
      >
        {activeTab === 0 ? (
          <FormControl>
            <FormLabel fontSize='14px' fontWeight='600' lineHeight='20px' color='black.500'>
              Version Description{' '}
              <Box as='span' color='gray.600' fontWeight='400' fontSize='12px' lineHeight='18px'>
                (optional)
              </Box>
            </FormLabel>
            <Textarea
              data-testid='workflow-publish-version-description'
              placeholder='Enter a description for this workflow version'
              value={versionDescription}
              onChange={(e) => setVersionDescription(e.target.value)}
              fontSize='14px'
              resize='vertical'
              borderColor='gray.400'
              focusBorderColor='gray.600'
            />
          </FormControl>
        ) : (
          <></>
        )}
      </BaseModal>
      <VersionsPanel isOpen={isVersionsOpen} onClose={() => setVersionsOpen(false)} />
      <AgentWorkflowReports
        openModal={isReportsOpen}
        onToggle={onReportsToggle}
        workflowId={agentId}
      />
    </Box>
  );
};

export default AgentWorkflowHeader;
