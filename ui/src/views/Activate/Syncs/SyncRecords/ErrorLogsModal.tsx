import {
  Box,
  Button,
  Flex,
  Modal,
  ModalBody,
  ModalCloseButton,
  ModalContent,
  ModalFooter,
  ModalOverlay,
  Text,
  useDisclosure,
  Image,
  ModalHeader,
  Icon,
} from '@chakra-ui/react';
import { FiCopy, FiArrowRight, FiAlertTriangle } from 'react-icons/fi';
import { FaBug } from 'react-icons/fa';

import { useSyncStore } from '@/stores/useSyncStore';
import { SyncRecordStatus } from '../types';
import copy from 'copy-to-clipboard';
import truncateText from '@/utils/truncateText';

const ErrorLogsModal = ({
  request,
  response,
  status,
  level,
}: {
  request: string;
  response: string;
  status: SyncRecordStatus;
  level: string;
}): JSX.Element => {
  const { isOpen, onOpen, onClose } = useDisclosure();
  const selectedSync = useSyncStore((state) => state.selectedSync);

  const handleCopy = () => {
    const textToCopy = `Request: ${request}\nResponse: ${response}`;
    copy(textToCopy);
  };

  return (
    <>
      <Box
        height='32px'
        width='32px'
        marginRight='10px'
        borderStyle='solid'
        borderWidth='1px'
        borderColor='gray.400'
        borderRadius='8px'
        display='flex'
        justifyContent='center'
        alignItems='center'
        backgroundColor='gray.100'
        onClick={onOpen}
        cursor='pointer'
        data-testid='logs-button'
      >
        <Icon as={FaBug} boxSize='4' />
      </Box>

      <Modal isOpen={isOpen} onClose={onClose} isCentered size='xl'>
        <ModalOverlay bg='blackAlpha.400' />

        <ModalContent>
          <ModalHeader paddingX='24px' paddingY='20px'>
            <Text fontWeight={700} size='xl' color='black.500' letterSpacing='-0.2px'>
              {`Log messaage received by ${selectedSync.destinationName}`}
            </Text>
            <ModalCloseButton color='gray.600' />
          </ModalHeader>
          <ModalCloseButton color='gray.600' />
          <ModalBody pt={8} pb={0}>
            <Flex direction='column' gap='24px'>
              <Box display='flex' gap='16px' alignItems='center'>
                <Box
                  key={selectedSync.sourceName}
                  display='flex'
                  alignItems='center'
                  borderWidth='thin'
                  padding='12px'
                  borderRadius='8px'
                  borderColor='gray.400'
                  backgroundColor='gray.200'
                  height='56px'
                  flex={1}
                >
                  <Box
                    height='40px'
                    width='40px'
                    marginRight='10px'
                    borderWidth='thin'
                    padding='5px'
                    borderRadius='8px'
                    display='flex'
                    justifyContent='center'
                    alignItems='center'
                    borderColor='gray.400'
                    backgroundColor='gray.100'
                  >
                    <Image
                      src={selectedSync.sourceIcon}
                      alt='source icon'
                      maxHeight='100%'
                      height='24px'
                      width='24px'
                    />
                  </Box>
                  <Box display='flex' flexDirection='column'>
                    <Text size='xs' letterSpacing='2.4px' fontWeight='bold' color='gray.600'>
                      SOURCE
                    </Text>
                    <Text fontWeight='semibold' size='sm'>
                      {truncateText(selectedSync.sourceName || '', 20)}
                    </Text>
                  </Box>
                </Box>
                <Box color='gray.600'>
                  <FiArrowRight />
                </Box>
                <Box
                  key={selectedSync.destinationName}
                  display='flex'
                  alignItems='center'
                  borderWidth='thin'
                  padding='12px'
                  borderRadius='8px'
                  borderColor={status === SyncRecordStatus.success ? 'gray.400' : 'error.200'}
                  backgroundColor={status === SyncRecordStatus.success ? 'gray.200' : 'error.100'}
                  height='56px'
                  flex={1}
                  justifyContent={status === SyncRecordStatus.failed ? 'space-between' : ''}
                >
                  <Box display='flex'>
                    <Box
                      height='40px'
                      width='40px'
                      marginRight='10px'
                      borderWidth='thin'
                      padding='5px'
                      borderRadius='8px'
                      display='flex'
                      justifyContent='center'
                      alignItems='center'
                      backgroundColor='gray.100'
                      borderColor={status === SyncRecordStatus.success ? 'gray.400' : 'error.200'}
                    >
                      <Image
                        src={selectedSync.destinationIcon}
                        alt='source icon'
                        maxHeight='100%'
                        height='24px'
                        width='24px'
                      />
                    </Box>
                    <Box display='flex' flexDirection='column'>
                      <Text size='xs' letterSpacing='2.4px' fontWeight='bold' color='gray.600'>
                        DESTINATION
                      </Text>
                      <Text fontWeight='semibold' size='sm'>
                        {truncateText(selectedSync.destinationName || '', 20)}
                      </Text>
                    </Box>
                  </Box>
                  {status === SyncRecordStatus.failed && (
                    <Box color='error.400'>
                      <FiAlertTriangle />
                    </Box>
                  )}
                </Box>
              </Box>
              <Box>
                <Text
                  size='sm'
                  fontWeight='semibold'
                >{`Logs received by ${selectedSync.destinationName}`}</Text>
                <Box
                  marginTop='12px'
                  backgroundColor='gray.200'
                  borderWidth='1px'
                  borderStyle='solid'
                  borderColor='gray.500'
                  padding='16px'
                  height='320px'
                  position='relative'
                >
                  <Box
                    height='220px'
                    overflow='auto'
                    display='flex'
                    flexDirection='column'
                    gap='8px'
                  >
                    <Text color='black.200' fontWeight='semibold' size='sm'>
                      Level
                    </Text>
                    <Text color='black.200' fontWeight={400} size='sm'>
                      {level}
                    </Text>
                    <Text color='black.200' fontWeight='semibold' size='sm'>
                      Request
                    </Text>
                    <Text color='black.200' fontWeight={400} size='sm'>
                      {request}
                    </Text>
                    <Text color='black.200' fontWeight='semibold' size='sm'>
                      Response
                    </Text>
                    <Text color='black.200' fontWeight={400} size='sm'>
                      {response}
                    </Text>
                  </Box>
                  <Button
                    color='black.500'
                    rounded='lg'
                    onClick={handleCopy}
                    letterSpacing='-0.14px'
                    leftIcon={<FiCopy color='gray.100' />}
                    backgroundColor='gray.200'
                    borderColor='gray.500'
                    borderWidth='1px'
                    borderStyle='solid'
                    marginTop='16px'
                    _hover={{ bgColor: 'gray.400', color: 'black' }}
                    position='absolute'
                    bottom='16px'
                  >
                    Copy Code
                  </Button>
                </Box>
              </Box>
            </Flex>
          </ModalBody>

          <ModalFooter pt={8} pb={8}>
            <Box w='full'>
              <Flex flexDir='row' justifyContent='end'>
                <Button
                  color='black.500'
                  rounded='lg'
                  onClick={onClose}
                  letterSpacing='-0.14px'
                  backgroundColor='gray.300'
                  minWidth={0}
                  width='auto'
                  _hover={{ bgColor: 'gray.400', color: 'black' }}
                >
                  Cancel
                </Button>
              </Flex>
            </Box>
          </ModalFooter>
        </ModalContent>
      </Modal>
    </>
  );
};

export default ErrorLogsModal;
