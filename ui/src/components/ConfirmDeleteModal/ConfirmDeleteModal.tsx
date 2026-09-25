import {
  Box,
  Button,
  Drawer,
  DrawerBody,
  DrawerContent,
  DrawerFooter,
  DrawerHeader,
  DrawerOverlay,
  Flex,
  Image,
  Modal,
  ModalBody,
  ModalCloseButton,
  ModalContent,
  ModalFooter,
  ModalOverlay,
  Text,
} from '@chakra-ui/react';
import ExitWarning from '@/assets/images/ExitWarning.svg';

export type ConfirmDeleteModalProps = {
  open: boolean;
  title: string;
  description: string | React.ReactNode;
  onDelete: () => void;
  onClose: () => void;
  isDeleting?: boolean;
  buttonWidth?: string;
  deleteButtonText?: string;
  isWidget?: boolean;
  exitWarning?: boolean;
  titleAlign?: 'left' | 'center' | 'right';
  descriptionAlign?: 'left' | 'center' | 'right';
  footerAlign?: 'left' | 'center' | 'right';
  /** Root modal content test id. Defaults to `confirm-delete-modal`. */
  testId?: string;
};

const ConfirmDeleteModal = ({
  open,
  title,
  description,
  onDelete,
  onClose,
  isDeleting = false,
  buttonWidth,
  deleteButtonText,
  isWidget,
  exitWarning = true,
  titleAlign,
  descriptionAlign,
  footerAlign,
  testId = 'confirm-delete-modal',
}: ConfirmDeleteModalProps): JSX.Element => {
  const titleAlignment = titleAlign || 'center';
  const descriptionAlignment = descriptionAlign || (isWidget ? 'left' : 'center');
  const footerAlignment = footerAlign || 'center';
  const contentAlignItems =
    titleAlignment === 'left' || descriptionAlignment === 'left' ? 'flex-start' : 'center';

  const DeleteFormContent = () => (
    <Flex direction='column' alignItems={contentAlignItems}>
      {!isWidget && (
        <>
          {exitWarning && (
            <Box h='200px' w='200px'>
              <Image src={ExitWarning} alt='Exit Warning' />
            </Box>
          )}
          <Text
            fontWeight='bold'
            fontSize={20}
            textAlign={titleAlignment}
            data-testid={`${testId}-title`}
          >
            {title}
          </Text>
        </>
      )}
      <Text
        fontWeight='light'
        fontSize={14}
        textAlign={descriptionAlignment}
        data-testid={`${testId}-description`}
      >
        {description}
      </Text>
    </Flex>
  );

  const DeleteFormFooter = () => (
    <Box w='full'>
      <Flex flexDir='row' justifyContent={footerAlignment}>
        <Button
          bgColor='gray.300'
          variant='ghost'
          color='black'
          width={buttonWidth}
          mr={3}
          onClick={onClose}
          size='md'
          pr={8}
          pl={8}
          data-testid={`${testId}-cancel-button`}
        >
          Cancel
        </Button>
        <Button
          variant='danger'
          width={buttonWidth}
          paddingX='16px'
          onClick={onDelete}
          isLoading={isDeleting}
          data-testid={`${testId}-delete-button`}
        >
          {deleteButtonText || 'Delete'}
        </Button>
      </Flex>
    </Box>
  );

  return (
    <>
      {isWidget ? (
        <Drawer isOpen={open} placement='bottom' onClose={onClose} size='sm'>
          <DrawerOverlay />
          <DrawerContent
            borderRadius={'8px'}
            bgColor={'gray.200'}
            overflow={'hidden'}
            data-testid={testId}
          >
            <DrawerHeader
              bgColor={'gray.100'}
              fontSize={'sm'}
              fontWeight='bold'
              borderBottomRadius='8px'
              borderBottom={'1px solid'}
              borderBottomColor={'gray.400'}
              padding={'16px'}
            >
              {title}
            </DrawerHeader>

            <DrawerBody bgColor={'gray.200'} padding={'16px'}>
              <DeleteFormContent />
            </DrawerBody>

            <DrawerFooter padding={'0 16px 16px 16px'}>
              <DeleteFormFooter />
            </DrawerFooter>
          </DrawerContent>
        </Drawer>
      ) : (
        <Modal isOpen={open} onClose={onClose} isCentered>
          <ModalOverlay bg='blackAlpha.400' />
          <ModalContent minWidth='540px' data-testid={testId}>
            <ModalCloseButton color='gray.600' data-testid={`${testId}-close-button`} />
            <ModalBody mx='auto' pt={10}>
              <DeleteFormContent />
            </ModalBody>

            <ModalFooter paddingBottom='8'>
              <DeleteFormFooter />
            </ModalFooter>
          </ModalContent>
        </Modal>
      )}
    </>
  );
};

export default ConfirmDeleteModal;
