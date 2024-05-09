import {
  Box,
  Text,
  Modal,
  ModalBody,
  ModalCloseButton,
  ModalContent,
  ModalFooter,
  ModalHeader,
  ModalOverlay,
  Flex,
  Button,
} from '@chakra-ui/react';
import { FiSettings, FiChevronRight, FiBriefcase } from 'react-icons/fi';

const ManageWorkspaceModal = () => {
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
        onClick={() => {}}
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
      <Modal isOpen={true} onClose={() => {}} isCentered size='xl'>
        <ModalOverlay bg='blackAlpha.400' />
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
                  abc
                </Text>
                <Text color='gray.600' fontWeight='bold' size='xs' letterSpacing='2.4px'>
                  ORGANIZATION
                </Text>
              </Box>
              <Box
                display='flex'
                justifyContent='space-between'
                alignItems='center'
                paddingY='10px'
                paddingX='24px'
                _hover={{ bgColor: 'gray.200' }}
              >
                <Box display='flex' gap='12px' alignItems='center'>
                  <Box>
                    <FiBriefcase />
                  </Box>
                  <Text>abcprod</Text>
                </Box>
                <Box display='flex' gap='24px' alignItems='center'>
                  <Text size='xs' fontWeight={500}>
                    3 members
                  </Text>
                  <Box color='gray.600'>
                    <FiChevronRight />
                  </Box>
                </Box>
              </Box>
              <Box
                display='flex'
                justifyContent='space-between'
                alignItems='center'
                paddingY='10px'
                paddingX='24px'
                _hover={{ bgColor: 'gray.200' }}
              >
                <Box display='flex' gap='12px' alignItems='center'>
                  <Box>
                    <FiBriefcase />
                  </Box>
                  <Text>abcprod</Text>
                </Box>
                <Box display='flex' gap='24px' alignItems='center'>
                  <Text size='xs' fontWeight={500}>
                    3 members
                  </Text>
                  <Box color='gray.600'>
                    <FiChevronRight />
                  </Box>
                </Box>
              </Box>
            </Flex>
          </ModalBody>

          <ModalFooter paddingX='24px' paddingY='20px'>
            <Box w='full'>
              <Flex flexDir='row' justifyContent='end'>
                <Button
                  variant='ghost'
                  mr={3}
                  onClick={() => {}}
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
                  onClick={() => {}}
                  minWidth={0}
                  width='auto'
                >
                  Create New Workspace
                </Button>
              </Flex>
            </Box>
          </ModalFooter>
        </ModalContent>
      </Modal>
    </>
  );
};

export default ManageWorkspaceModal;
