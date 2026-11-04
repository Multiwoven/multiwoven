import {
  Box,
  Modal,
  ModalBody,
  ModalCloseButton,
  ModalContent,
  ModalFooter,
  ModalHeader,
  ModalOverlay,
  Text,
  useDisclosure,
} from '@chakra-ui/react';

type ModalProps = {
  children: JSX.Element;
  footer?: JSX.Element;
  openModal: boolean;
  title: string | React.ReactNode;
  description?: string;
  footerAlignment?: string;
  addHeaderStroke?: boolean;
  addFooterStroke?: boolean;
  bodyPaddingX?: string;
  bodyPaddingY?: string;
  maxHeight?: string;
  bodyPaddingTop?: string;
  bodyPaddingBottom?: string;
  enableOverflowY?: boolean;
  showCloseButton?: boolean;
  modalWidth?: string;
  modalBodyWidth?: string;
  descriptionColor?: string;
  closeOnOverlayClick?: boolean;
  closeOnEscape?: boolean;
  setModalOpen: (open: boolean) => void;
  handleCloseComplete?: () => void;
  contentDataTestId?: string;
  closeButtonDataTestId?: string;
};

const BaseModal = ({
  openModal,
  setModalOpen,
  title,
  footer,
  children,
  addHeaderStroke,
  addFooterStroke,
  description,
  footerAlignment = 'end',
  bodyPaddingX = '24px',
  bodyPaddingY = '8px',
  maxHeight,
  bodyPaddingTop = '8px',
  bodyPaddingBottom = '8px',
  enableOverflowY = true,
  showCloseButton = true,
  modalWidth = 'xl',
  descriptionColor = 'black.100',
  closeOnOverlayClick,
  closeOnEscape = true,
  handleCloseComplete,
  modalBodyWidth,
  contentDataTestId,
  closeButtonDataTestId,
}: ModalProps) => {
  const { isOpen, onClose } = useDisclosure({ isOpen: openModal });
  return (
    <Modal
      isOpen={isOpen}
      onClose={() => {
        onClose();
        setModalOpen(false);
      }}
      isCentered
      size={modalWidth}
      onCloseComplete={handleCloseComplete}
      closeOnOverlayClick={closeOnOverlayClick}
      closeOnEsc={closeOnEscape}
    >
      <ModalOverlay bg='blackAlpha.600' />
      <ModalContent
        data-testid={contentDataTestId}
        width={modalBodyWidth}
        display='flex'
        flexDirection='column'
        h={maxHeight}
        maxH={maxHeight}
      >
        <ModalHeader
          paddingX='24px'
          paddingY='20px'
          borderBottom={addHeaderStroke ? '1px solid' : 'none'}
          borderBottomColor={addHeaderStroke ? 'gray.400' : ''}
        >
          {typeof title === 'string' ? (
            <Text fontWeight={700} size='xl' color='black.500' letterSpacing='-0.2px'>
              {title}
            </Text>
          ) : (
            <Box>{title}</Box>
          )}
          {description && (
            <Text fontWeight={400} size='sm' color={descriptionColor} letterSpacing='-0.2px'>
              {description}
            </Text>
          )}
          {showCloseButton && (
            <ModalCloseButton color='gray.600' data-testid={closeButtonDataTestId} />
          )}
        </ModalHeader>
        <ModalBody
          paddingX={bodyPaddingX}
          paddingY={bodyPaddingY}
          flex='1'
          overflowY={enableOverflowY ? 'auto' : 'hidden'}
          paddingTop={bodyPaddingTop}
          paddingBottom={bodyPaddingBottom}
          width={modalBodyWidth}
        >
          {children}
        </ModalBody>

        {footer && (
          <ModalFooter
            paddingX='24px'
            paddingY='20px'
            justifyContent={footerAlignment}
            borderTop={addFooterStroke ? '1px solid' : 'none'}
            borderTopColor={addFooterStroke ? 'gray.400' : ''}
          >
            {footer}
          </ModalFooter>
        )}
      </ModalContent>
    </Modal>
  );
};

export default BaseModal;
