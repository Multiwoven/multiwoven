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
} from '@chakra-ui/react';
import { FiChevronRight, FiCopy, FiArrowRight, FiAlertTriangle } from 'react-icons/fi';
import { useSyncStore } from '@/stores/useSyncStore';

const ErrorLogsModal = ({ errorMessage }: { errorMessage: string }): JSX.Element => {
  const { isOpen, onOpen, onClose } = useDisclosure();
  const selectedSync = useSyncStore((state) => state.selectedSync);

  return (
    <>
      <Box display='flex' alignItems='center' cursor='pointer' onClick={onOpen}>
        <Text color='error.500'>Error</Text>
        <Box color='error.500'>
          <FiChevronRight />
        </Box>
      </Box>

      <Modal isOpen={isOpen} onClose={onClose} isCentered size='lg'>
        <ModalOverlay bg='blackAlpha.400' />

        <ModalContent>
          <ModalHeader paddingX='24px' paddingY='20px'>
            <Text fontWeight={700} size='xl' color='black.500' letterSpacing='-0.2px'>
              {`Error messaage from ${selectedSync.destinationName}`}
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
                      {selectedSync.sourceName}
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
                  borderColor='error.200'
                  backgroundColor='error.100'
                  height='56px'
                  flex={1}
                  justifyContent='space-between'
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
                    backgroundColor='gray.100'
                    borderColor='error.200'
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
                      {selectedSync.destinationName}
                    </Text>
                  </Box>
                  <Box color='error.400'>
                    <FiAlertTriangle />
                  </Box>
                </Box>
              </Box>
              <Box>
                <Text
                  size='sm'
                  fontWeight='semibold'
                >{`Error message received by ${selectedSync.destinationName}`}</Text>
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
                  <Text color='black.200' fontWeight={400} size='sm' height='220px' overflow='auto'>
                    {errorMessage}
                  </Text>
                  <Button
                    color='black.500'
                    rounded='lg'
                    onClick={onClose}
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
