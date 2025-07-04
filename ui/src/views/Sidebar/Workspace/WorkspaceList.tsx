import {
  Box,
  Text,
  ModalBody,
  ModalCloseButton,
  ModalContent,
  ModalFooter,
  ModalHeader,
  Flex,
  Button,
} from '@chakra-ui/react';
import { FiChevronRight, FiBriefcase } from 'react-icons/fi';
// Removed navigation import as we'll handle adding member inline
import { Dispatch, SetStateAction } from 'react';
import { WorkspaceAPIResponse } from '@/services/settings';

interface WorkspacListProps {
  setIsModalOpen: Dispatch<SetStateAction<boolean>>;
  handleCreateNewWorkspace: () => void;
  workspaceDetails: WorkspaceAPIResponse;
  organizationName: string;
  handleAddMember: (workspaceId: string) => void;
}

const WorkspaceList = ({
  setIsModalOpen,
  handleCreateNewWorkspace,
  workspaceDetails,
  organizationName,
  handleAddMember,
}: WorkspacListProps) => {
  return (
    <ModalContent>
      <ModalHeader paddingX='24px' paddingY='20px'>
        <Text fontWeight={700} size='xl' color='black.500' letterSpacing='-0.2px'>
          Select a workspace
        </Text>
        <ModalCloseButton color='gray.600' />
      </ModalHeader>

      <ModalBody
        marginX='24px'
        marginY='8px'
        borderWidth='1px'
        borderStyle='solid'
        borderColor='gray.400'
        borderRadius='12px'
        padding={0}
      >
        <Flex direction='column'>
          <Box
            display='flex'
            justifyContent='space-between'
            alignItems='center'
            paddingX='24px'
            paddingY='20px'
          >
            <Text size='md' fontWeight='semibold'>
              {organizationName}
            </Text>
            <Text color='gray.600' fontWeight='bold' size='xs' letterSpacing='2.4px'>
              ORGANIZATION
            </Text>
          </Box>
          {workspaceDetails?.data?.map?.((workspace) => (
            <Box
              display='flex'
              justifyContent='space-between'
              alignItems='center'
              paddingY='10px'
              paddingX='24px'
              _hover={{ bgColor: 'gray.200' }}
              key={workspace?.id}
            >
              <Box display='flex' gap='12px' alignItems='center'>
                <Box>
                  <FiBriefcase />
                </Box>
                <Text>{workspace?.attributes?.name}</Text>
              </Box>
              <Box display='flex' gap='24px' alignItems='center'>
                <Text size='xs' fontWeight={500}>
                  {`${workspace?.attributes?.members_count} members`}
                </Text>
                <Box 
                  color='gray.600' 
                  cursor='pointer' 
                  onClick={() => handleAddMember(String(workspace?.id))}
                  title="Add member to workspace"
                >
                  <FiChevronRight />
                </Box>
              </Box>
            </Box>
          ))}
        </Flex>
      </ModalBody>

      <ModalFooter paddingX='24px' paddingY='20px'>
        <Box w='full'>
          <Flex flexDir='row' justifyContent='end'>
            <Button
              variant='ghost'
              mr={3}
              onClick={() => setIsModalOpen(false)}
              size='md'
              color='black.500'
              minWidth={0}
              width='auto'
            >
              Cancel
            </Button>
            <Button
              variant='solid'
              color='white'
              rounded='lg'
              onClick={handleCreateNewWorkspace}
              minWidth={0}
              width='auto'
            >
              Create New Workspace
            </Button>
          </Flex>
        </Box>
      </ModalFooter>
    </ModalContent>
  );
};

export default WorkspaceList;
