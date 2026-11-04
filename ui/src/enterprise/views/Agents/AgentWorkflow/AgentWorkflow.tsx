import { Box, Drawer, DrawerBody, DrawerContent, DrawerOverlay, Flex } from '@chakra-ui/react';
import { useNavigate, useParams, useSearchParams } from 'react-router-dom';
import useCustomToast from '@/hooks/useCustomToast';
import { CustomToastStatus } from '@/components/Toast';
import AgentWorkflowHeader from './AgentWorkflowHeader';
import AgentWorkflowCanvas from './AgentWorkflowCanvas';
import { useEffect, useState } from 'react';
import Interface from '../Interface/Interface';
import useAgentStore from '@/enterprise/store/useAgentStore';
import useAgentQueries from '@/enterprise/hooks/queries/useAgentQueries';
import useAgentMutations from '@/enterprise/hooks/mutations/useAgentMutations';
import { INTERFACE_TYPE } from '../types';
import { WorkflowInterfaceConfig } from '@/enterprise/services/types';
import Loader from '@/components/Loader';
import { transformComponents, transformEdges } from './utils';
import VersionPreviewBanner from '@/enterprise/components/Versions/VersionPreviewBanner';
import VersionDiffModal from './Versions/VersionDiffModal';
import { Edge } from '@xyflow/react';
import { INTERFACE_COMPONENT_CONFIG } from '../constants';

const AgentWorkflow = (): JSX.Element => {
  const [activeTab, setActiveTab] = useState(0);
  const navigate = useNavigate();
  const params = useParams();
  const [searchParams] = useSearchParams();
  const showToast = useCustomToast();

  const {
    currentWorkflow,
    setNodes,
    setEdges,
    setWorkflow,
    setTriggerType,
    setInterfaceConfig,
    isPreviewMode,
    previewVersion,
    cancelPreview,
    originalDraftState,
  } = useAgentStore((state) => state);
  const agentId = params.id ?? '';
  const templateId = searchParams.get('template');

  const { useGetWorkflowById, useGetAgentTemplateById } = useAgentQueries();
  const { restoreVersion: restoreVersionMutation } = useAgentMutations();
  const { data: workflowData, isLoading } = useGetWorkflowById(agentId);
  const { data: templateData } = useGetAgentTemplateById(templateId);

  // State to track when nodes are set and ready for edges
  const [pendingEdges, setPendingEdges] = useState<Edge[]>([]);

  const [isDiffModalOpen, setDiffModalOpen] = useState(false);

  useEffect(() => {
    if (workflowData?.data) {
      const workflow = { ...workflowData.data };
      workflow.attributes.components = workflow.attributes.components
        ? transformComponents(workflow.attributes.components)
        : [];
      const edges = transformEdges(workflowData.data.attributes.edges);
      setWorkflow({
        workflow: {
          ...workflow.attributes,
          access_control: workflow.attributes.access_control || {
            allowed_role_ids: [],
            allowed_users: [],
          },
        },
      });
      // First set nodes
      setNodes(() => [...workflow.attributes.components]);
      // Store edges to be set after nodes are rendered
      setPendingEdges(edges);
      setTriggerType(workflow.attributes.trigger_type ?? INTERFACE_TYPE.WEBSITE_CHATBOT);
      setInterfaceConfig(
        (workflow.attributes.configuration.interface as WorkflowInterfaceConfig) ??
          INTERFACE_COMPONENT_CONFIG,
      );
    }
    if (workflowData?.data?.attributes.components.length === 0 && templateData?.data) {
      const template = { ...templateData.data };

      const templateComponents = template.components.map((component) => ({
        ...component,
        id: `${component.id}-${workflowData?.data?.id}`,
      }));
      const transformedComponents = transformComponents(templateComponents);

      const templateEdges = template.edges.map((edge) => ({
        ...edge,
        source_component_id: `${edge.source_component_id}-${workflowData?.data?.id}`,
        target_component_id: `${edge.target_component_id}-${workflowData?.data?.id}`,
      }));
      const transformedEdges = transformEdges(templateEdges);

      setWorkflow({
        ...currentWorkflow,
        workflow: {
          name: workflowData?.data?.attributes.name,
          description: template.description,
          components: transformedComponents,
          edges: templateEdges,
          access_control_enabled: workflowData.data.attributes.access_control_enabled || false,
          access_control: {
            allowed_role_ids: workflowData.data.attributes.access_control.allowed_role_ids || [],
            allowed_users: workflowData.data.attributes.access_control.allowed_users || [],
          },
          configuration: {},
        },
      });
      // First set nodes
      setNodes(() => transformedComponents);
      // Store edges to be set after nodes are rendered
      setPendingEdges(transformedEdges);
    }
  }, [workflowData, templateData]);

  // Set edges after nodes are rendered
  useEffect(() => {
    if (pendingEdges.length > 0) {
      // Small delay to ensure nodes and their handles are fully rendered
      const timer = setTimeout(() => {
        setEdges(() => pendingEdges);
        setPendingEdges([]);
      }, 100);
      return () => clearTimeout(timer);
    }
  }, [pendingEdges, setEdges]);

  if (isLoading) {
    return <Loader />;
  }

  return (
    <>
      <Drawer isOpen onClose={() => navigate(-1)} placement='right' size='100%' closeOnEsc={false}>
        <DrawerOverlay />
        <DrawerContent padding='0px'>
          <DrawerBody padding='0px' height='100vh'>
            <Flex direction='column' height='100%'>
              <Box flexShrink={0}>
                <AgentWorkflowHeader activeTab={activeTab} setActiveTab={setActiveTab} />
              </Box>
              <Box flex='1' height='calc(100vh - 81px)' position='relative' overflow='hidden'>
                {activeTab === 0 ? <AgentWorkflowCanvas /> : <Interface />}

                {isPreviewMode && previewVersion && (
                  <VersionPreviewBanner
                    versionLabel={previewVersion.versionNumber}
                    onCancel={cancelPreview}
                    onPrimaryAction={() => setDiffModalOpen(true)}
                    primaryActionLabel='Show Version Changes'
                    primaryActionTestId='workflow-version-show-changes-button'
                  />
                )}
              </Box>
            </Flex>
          </DrawerBody>
        </DrawerContent>
      </Drawer>

      {previewVersion && (
        <VersionDiffModal
          isOpen={isDiffModalOpen}
          onClose={() => setDiffModalOpen(false)}
          previewVersion={previewVersion}
          currentVersionNumber={currentWorkflow?.workflow?.version_number}
          currentVersionStatus={currentWorkflow?.workflow?.status}
          originalComponents={originalDraftState?.nodes}
          onRestore={async () => {
            const versionId = previewVersion.id;
            if (!versionId || !agentId) {
              showToast({
                title: 'Error',
                description: 'Unable to restore version: version ID not found',
                status: CustomToastStatus.Error,
              });
              return;
            }

            try {
              const response = await restoreVersionMutation.mutateAsync({
                workflowId: agentId,
                versionId,
              });

              if (response?.data?.attributes) {
                setWorkflow({
                  workflow: {
                    ...response.data.attributes,
                    components: response.data.attributes.components || [],
                    edges: response.data.attributes.edges || [],
                  },
                });

                const restoredComponents = transformComponents(response.data.attributes.components);
                const restoredEdges = transformEdges(response.data.attributes.edges);

                setNodes(() => restoredComponents);
                setEdges(() => restoredEdges);
              }

              cancelPreview();
              setDiffModalOpen(false);
              showToast({
                title: 'Success',
                description: `Draft replaced with version ${previewVersion.versionNumber}`,
                status: CustomToastStatus.Success,
              });
            } catch {
              // Error is handled by the mutation's onError handler
            }
          }}
          onBackToDraft={() => {
            cancelPreview();
            setDiffModalOpen(false);
          }}
        />
      )}
    </>
  );
};

export default AgentWorkflow;
