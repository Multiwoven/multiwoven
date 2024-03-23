import { deleteModelById } from '@/services/models';
import {
  Box,
  Button,
  Flex,
  Image,
  Modal,
  ModalBody,
  ModalCloseButton,
  ModalContent,
  ModalFooter,
  ModalOverlay,
  Text,
  useDisclosure,
} from '@chakra-ui/react';
import { FiTrash2 } from 'react-icons/fi';
import { useNavigate, useParams } from 'react-router-dom';
import ExitWarningImage from '@/assets/images/ExitWarning.png';

import { CustomToastStatus } from '@/components/Toast/index';
import useCustomToast from '@/hooks/useCustomToast';

const DeleteModelModal = (): JSX.Element => {
  const { isOpen, onOpen, onClose } = useDisclosure();

  const params = useParams();
  const showToast = useCustomToast();
  const navigate = useNavigate();

  const model_id = params.id || '';

  async function handleDeleteModel() {
    try {
      await deleteModelById(model_id);
      showToast({
        title: 'Model deleted successfully',
        status: CustomToastStatus.Success,
        isClosable: true,
        duration: 5000,
        position: 'bottom-right',
      });
      navigate('/define/models');
    } catch (error) {
      showToast({
        title: 'Unable to delete Model',
        description: 'error',
        status: CustomToastStatus.Error,
        isClosable: true,
        duration: 5000,
        position: 'bottom-right',
      });
    }
  }

  return (
    <>
      <Button
        _hover={{ bgColor: 'gray.200' }}
        w='100%'
        py={3}
        px={2}
        display='flex'
        flexDir='row'
        alignItems='center'
        color={'red.600'}
        rounded='lg'
        onClick={onOpen}
        as='button'
        justifyContent='start'
        border={0}
        variant='shell'
      >
        <FiTrash2 color='#F45757' />
        <Text size='sm' fontWeight='medium' ml={3} color='#C82727'>
          Delete
        </Text>
      </Button>

      <Modal isOpen={isOpen} onClose={onClose} isCentered>
        <ModalOverlay bg='blackAlpha.400' />
        <ModalContent minWidth='540px'>
          <ModalCloseButton color='gray.600' />
          <ModalBody mx='auto' pt={10}>
            <Flex direction='column'>
              <Image src={ExitWarningImage} h={32} w={48} mx='auto' my={8} />
              <Text fontWeight='bold' pt={8} fontSize={20} textAlign='center'>
                Are you sure you want to delete this Model?
              </Text>
              <Text fontWeight='light' fontSize={14} textAlign='center'>
                This action will permanently delete the Model and cannot be undone.
              </Text>
            </Flex>
          </ModalBody>

          <ModalFooter paddingBottom='8'>
            <Box w='full'>
              <Flex flexDir='row' justifyContent='center'>
                <Button
                  bgColor='gray.300'
                  variant='ghost'
                  color='black'
                  mr={3}
                  onClick={onClose}
                  size='md'
                  pr={8}
                  pl={8}
                >
                  Cancel
                </Button>
                <Button
                  variant='solid'
                  pr={10}
                  pl={10}
                  onClick={handleDeleteModel}
                  backgroundColor='error.500'
                  _hover={{ bgColor: 'error.400' }}
                >
                  Delete
                </Button>
              </Flex>
            </Box>
          </ModalFooter>
        </ModalContent>
      </Modal>
    </>
  );
};

export default DeleteModelModal;
