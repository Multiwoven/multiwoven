import { useState } from 'react';
import { Box, Flex, Text, Spinner } from '@chakra-ui/react';
import { useParams } from 'react-router-dom';
import VersionCard from './VersionCard';
import useAgentStore, { AgentVersion } from '@/enterprise/store/useAgentStore';
import { FiX } from 'react-icons/fi';
import IconEntity from '@/components/IconEntity';
import EditVersionModal from './EditVersionModal';
import ConfirmDeleteModal from '@/components/ConfirmDeleteModal/ConfirmDeleteModal';
import useAgentQueries from '@/enterprise/hooks/queries/useAgentQueries';
import useAgentMutations from '@/enterprise/hooks/mutations/useAgentMutations';
import { WorkflowVersionResponse } from '@/enterprise/services/types';
import { constructEdgeId } from '../utils';

interface VersionsPanelProps {
  isOpen: boolean;
  onClose: () => void;
}

const transformVersionToPreview = (
  version: WorkflowVersionResponse,
  isCurrent: boolean,
): AgentVersion | null => {
  if (!version.attributes.workflow) return null;

  const flowEdges = version.attributes.workflow.attributes.edges || [];
  const transformedEdges = flowEdges.map((edge) => ({
    id: constructEdgeId(edge),
    source: edge.source_component_id,
    target: edge.target_component_id,
    sourceHandle: `${edge.source_handle.field}-${edge.source_handle.type}-${edge.source_component_id}`,
    targetHandle: `${edge.target_handle.field}-${edge.target_handle.type}-${edge.target_component_id}`,
  }));

  const flowComponents = version.attributes.workflow.attributes.components || [];
  const transformedComponents = flowComponents.map((component) => ({
    ...component,
    type: component.component_category ?? 'generic_component',
    ...(component.position && { position: component.position }),
  }));

  // Get status from the version's workflow
  const versionStatus = version.attributes.workflow.attributes.status;
  let status: 'draft' | 'live' | 'archived' = 'archived';
  if (versionStatus === 'published') {
    status = 'live';
  } else if (isCurrent && versionStatus === 'draft') {
    status = 'draft';
  }

  return {
    id: version.id,
    versionNumber: `v${version.attributes.version_number}`,
    description: version.attributes.version_description || '',
    status,
    author: version.attributes.whodunnit || '-',
    timestamp: version.attributes.created_at || '',
    isCurrent,
    configuration: {
      components: transformedComponents,
      edges: transformedEdges,
    },
  };
};

const VersionsPanel = ({ isOpen, onClose }: VersionsPanelProps) => {
  const params = useParams();
  const workflowId = params.id ?? '';
  const { setPreviewMode, currentWorkflow } = useAgentStore();
  const { useGetWorkflowVersions } = useAgentQueries();
  const { updateVersionDescription, deleteVersion } = useAgentMutations();

  const {
    data: versionsData,
    isLoading,
    error,
    refetch,
  } = useGetWorkflowVersions(workflowId, isOpen && !!workflowId);

  const versions = versionsData?.data || [];
  const currentVersionNumber = currentWorkflow?.workflow?.version_number;

  // Find the latest published version (highest version number with published status)
  const latestPublishedVersion = versions
    .filter((v) => v.attributes.workflow?.attributes?.status === 'published')
    .sort((a, b) => b.attributes.version_number - a.attributes.version_number)[0];

  const [editingVersion, setEditingVersion] = useState<WorkflowVersionResponse | null>(null);
  const [deletingVersion, setDeletingVersion] = useState<WorkflowVersionResponse | null>(null);

  const handleEditDescription = (version: WorkflowVersionResponse) => {
    setEditingVersion(version);
  };

  const handleDeleteVersion = (version: WorkflowVersionResponse) => {
    setDeletingVersion(version);
  };

  const onSaveDescription = async (description: string) => {
    if (!editingVersion) return;

    try {
      await updateVersionDescription.mutateAsync({
        workflowId,
        versionId: editingVersion.id,
        description,
      });
      setEditingVersion(null);
      refetch();
    } catch (error) {
      // Error is handled by the mutation's onError handler
    }
  };

  const onConfirmDelete = async () => {
    if (!deletingVersion) return;

    try {
      await deleteVersion.mutateAsync({
        workflowId,
        versionId: deletingVersion.id,
      });

      setDeletingVersion(null);
      refetch();
    } catch (error) {
      // Error is handled by the mutation's onError handler
    }
  };

  if (!isOpen) return null;

  return (
    <>
      <Box
        data-testid='workflow-versions-panel'
        position='absolute'
        height='calc(100vh - 83px)'
        top='83px'
        right='0'
        width='360px'
        bg='white'
        borderLeftWidth='1px'
        borderLeftColor='gray.400'
        zIndex={5}
        display='flex'
        flexDirection='column'
      >
        <Box borderBottomWidth='1px' borderColor='gray.400' p='20px'>
          <Flex justify='space-between' align='center'>
            <Box>
              <Text fontSize='14px' fontWeight='600' lineHeight='20px' color='black.500'>
                Versions
              </Text>
              <Flex align='center' gap='4px' mt='4px'>
                <Box w='6px' h='6px' borderRadius='full' bg='blue.400' />
                <Text fontSize='12px' lineHeight='18px' color='black.100' fontWeight='400'>
                  {versions.length} version{versions.length !== 1 ? 's' : ''} available
                </Text>
              </Flex>
            </Box>
            <IconEntity
              icon={FiX}
              marginRight='0px'
              onClick={onClose}
              cursor='pointer'
              _hover={{ bg: 'gray.50' }}
            />
          </Flex>
        </Box>

        <Box
          data-testid='workflow-versions-container'
          bg='white'
          p='20px'
          flex='1'
          overflowY='auto'
        >
          {isLoading ? (
            <Flex justify='center' align='center' height='200px'>
              <Spinner size='lg' />
            </Flex>
          ) : error ? (
            <Flex justify='center' align='center' height='200px'>
              <Text color='red.500'>Failed to load versions</Text>
            </Flex>
          ) : versions.length === 0 ? (
            <Flex justify='center' align='center' height='200px'>
              <Text color='gray.500'>No versions available</Text>
            </Flex>
          ) : (
            <Flex direction='column' gap='16px'>
              {[...versions].reverse().map((version: WorkflowVersionResponse) => {
                const isCurrent = version.attributes.version_number === currentVersionNumber;
                const isLatestPublished = latestPublishedVersion?.id === version.id;

                return (
                  <VersionCard
                    key={version.id}
                    version={version}
                    isCurrent={isCurrent}
                    isLatestPublished={isLatestPublished}
                    onPreview={() => {
                      const previewData = transformVersionToPreview(version, isCurrent);
                      if (previewData) {
                        setPreviewMode(previewData);
                      }
                    }}
                    onEditDescription={() => handleEditDescription(version)}
                    onDelete={() => handleDeleteVersion(version)}
                  />
                );
              })}
            </Flex>
          )}
        </Box>
      </Box>

      {editingVersion && (
        <EditVersionModal
          isOpen={true}
          onClose={() => setEditingVersion(null)}
          version={editingVersion}
          onSave={onSaveDescription}
          isLoading={updateVersionDescription.isPending}
        />
      )}

      {deletingVersion && (
        <ConfirmDeleteModal
          open={true}
          onClose={() => setDeletingVersion(null)}
          title='Are you sure you want to delete?'
          description='This will permanently delete this workflow version and all associated data. This action cannot be undone.'
          onDelete={onConfirmDelete}
          isDeleting={deleteVersion.isPending}
          exitWarning={false}
          titleAlign='left'
          descriptionAlign='left'
          footerAlign='right'
        />
      )}
    </>
  );
};

export default VersionsPanel;
