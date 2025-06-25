import { Box, Text, Modal, ModalOverlay } from '@chakra-ui/react';
import { useState } from 'react';
import { FiSettings } from 'react-icons/fi';
import WorkspaceList from './WorkspaceList';
import CreateWorkspace from './CreateWorkspace';
import AddMember from './AddMember';
import { WorkspaceAPIResponse } from '@/services/settings';
import { UseQueryResult } from '@tanstack/react-query';

enum WORKSPACE_STATE {
  LIST = 'list',
  NEW = 'new',
  ADD_MEMBER = 'add_member',
}

const ManageWorkspaceModal = ({
  workspaces,
  refetchWorkspace,
}: {
  workspaces: WorkspaceAPIResponse;
  refetchWorkspace: UseQueryResult<WorkspaceAPIResponse>['refetch'];
}) => {
  const [isModalOpen, setIsModalOpen] = useState(false);
  const [activeState, setActiveState] = useState(WORKSPACE_STATE.LIST);
  const [selectedWorkspaceId, setSelectedWorkspaceId] = useState<string>('');

  const organizationName = workspaces?.data?.[0]?.attributes?.organization_name || '';
  const organizationId = workspaces?.data?.[0]?.attributes?.organization_id || 0;

  return (
    <>
      <Box
        _hover={{ bgColor: 'gray.300' }}
        w='100%'
        py='8px'
        px='12px'
        display='flex'
        flexDir='row'
        alignItems='center'
        color='gray.600'
        onClick={() => {
          setIsModalOpen(true);
          setActiveState(WORKSPACE_STATE.LIST);
        }}
        justifyContent='start'
        border={0}
        cursor='pointer'
        gap={2}
      >
        <FiSettings />
        <Text size='sm' fontWeight={400} color='black.500'>
          Manage Workspaces
        </Text>
      </Box>
      <Modal isOpen={isModalOpen} onClose={() => setIsModalOpen(false)} isCentered size='xl'>
        <ModalOverlay bg='blackAlpha.400' />
        {activeState === WORKSPACE_STATE.LIST && (
          <WorkspaceList
            organizationName={organizationName}
            setIsModalOpen={setIsModalOpen}
            handleCreateNewWorkspace={() => setActiveState(WORKSPACE_STATE.NEW)}
            workspaceDetails={workspaces}
            handleAddMember={(workspaceId) => {
              setSelectedWorkspaceId(workspaceId);
              setActiveState(WORKSPACE_STATE.ADD_MEMBER);
            }}
          />
        )}
        {activeState === WORKSPACE_STATE.NEW && (
          <CreateWorkspace
            organizationName={organizationName}
            organizationId={organizationId}
            handleWorkspaceCreate={() => {
              setActiveState(WORKSPACE_STATE.LIST);
              setIsModalOpen(false);
              refetchWorkspace();
            }}
            handleCancelClick={() => setActiveState(WORKSPACE_STATE.LIST)}
          />
        )}
        {activeState === WORKSPACE_STATE.ADD_MEMBER && (
          <AddMember
            onCancel={() => setActiveState(WORKSPACE_STATE.LIST)}
            workspaceId={selectedWorkspaceId}
            onSuccess={() => {
              // Refresh the workspace data
              refetchWorkspace();
            }}
          />
        )}
      </Modal>
    </>
  );
};

export default ManageWorkspaceModal;
