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
  ModalHeader,
} from '@chakra-ui/react';
import { format } from 'sql-formatter';
import Editor from '@monaco-editor/react';

const ViewSQLModal = ({
  tableName,
  userQuery,
}: {
  tableName: string;
  userQuery: string;
}): JSX.Element => {
  const { isOpen, onOpen, onClose } = useDisclosure();

  return (
    <>
      <Button
        variant='shell'
        onClick={onOpen}
        minWidth='0'
        width='auto'
        fontSize='12px'
        height='32px'
        paddingX={3}
        borderWidth={1}
        borderStyle='solid'
        borderColor='gray.500'
        isDisabled={!tableName}
      >
        View SQL
      </Button>

      <Modal isOpen={isOpen} onClose={onClose} isCentered size='lg'>
        <ModalOverlay bg='blackAlpha.400' />

        <ModalContent>
          <ModalHeader paddingX='24px' paddingY='20px'>
            <Text fontWeight={700} size='xl' color='black.500' letterSpacing='-0.2px'>
              {tableName}
            </Text>
            <ModalCloseButton color='gray.600' />
          </ModalHeader>
          <ModalCloseButton color='gray.600' />
          <ModalBody pt={8} pb={0}>
            <Flex direction='column'>
              <Box
                width='100%'
                borderStyle='solid'
                borderWidth='1px'
                borderColor='gray.400'
                backgroundColor='gray.100'
                borderRadius='12px'
                padding='12px'
              >
                <Editor
                  width='100%'
                  height='100px'
                  language='mysql'
                  defaultLanguage='mysql'
                  value={format(userQuery)}
                  saveViewState={true}
                  theme='light'
                  options={{
                    smoothScrolling: true,
                    scrollBeyondLastLine: false,
                    readOnly: true,
                  }}
                />
              </Box>
            </Flex>
          </ModalBody>

          <ModalFooter pt={8} pb={8}>
            <Box w='full'>
              <Flex flexDir='row' justifyContent='end'>
                <Button
                  variant='shell'
                  color='black.500'
                  rounded='lg'
                  onClick={onClose}
                  letterSpacing='-0.14px'
                  minWidth={0}
                  width='auto'
                  backgroundColor='gray.300'
                  border='none'
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

export default ViewSQLModal;
