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
import { useNavigate } from 'react-router-dom';
import ExitWarningImage from '@/assets/images/ExitWarning.png';

const ExitModal = (): JSX.Element => {
  const { isOpen, onOpen, onClose } = useDisclosure();
  const navigate = useNavigate();

  return (
    <>
      <Button
        variant='shell'
        onClick={onOpen}
        paddingX={6}
        height='32px'
        minWidth='0'
        width='auto'
        color='black.500'
        borderRadius='6px'
        letterSpacing='-0.12px'
      >
        Exit
      </Button>

      <Modal isOpen={isOpen} onClose={onClose} isCentered>
        <ModalOverlay bg='blackAlpha.400' />
        <ModalContent>
          <ModalCloseButton color='gray.600' />
          <ModalBody mx='auto' pt={8} pb={0}>
            <Flex direction='column'>
              <Image src={ExitWarningImage} h={32} w={48} mx='auto' my={8} />
              <Text
                fontWeight={700}
                size='xl'
                textAlign='center'
                color='black.500'
                letterSpacing='-0.2px'
              >
                Are you sure you want to exit?
              </Text>
              <Text fontWeight={400} size='sm' textAlign='center' color='black.200' pt={2}>
                Your progress will be lost
              </Text>
            </Flex>
          </ModalBody>

          <ModalFooter pt={8} pb={8}>
            <Box w='full'>
              <Flex flexDir='row' justifyContent='center'>
                <Button
                  variant='ghost'
                  mr={3}
                  onClick={onClose}
                  size='md'
                  color='black.500'
                  letterSpacing='-0.14px'
                >
                  Cancel
                </Button>
                <Button
                  variant='solid'
                  color='white'
                  rounded='lg'
                  onClick={() => navigate('*')}
                  letterSpacing='-0.14px'
                >
                  Exit
                </Button>
              </Flex>
            </Box>
          </ModalFooter>
        </ModalContent>
      </Modal>
    </>
  );
};

export default ExitModal;
