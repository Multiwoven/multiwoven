import { Box, Button, Flex, Icon, Text } from '@chakra-ui/react';
import { FiEye } from 'react-icons/fi';

interface VersionPreviewBannerProps {
  versionLabel: string;
  onCancel: () => void;
  onPrimaryAction: () => void;
  primaryActionLabel: string;
  primaryActionLoadingText?: string;
  isLoading?: boolean;
  placement?: 'top' | 'bottom';
  minWidth?: string;
  testId?: string;
  primaryActionTestId?: string;
}

const VersionPreviewBanner = ({
  versionLabel,
  onCancel,
  onPrimaryAction,
  primaryActionLabel,
  primaryActionLoadingText,
  isLoading = false,
  placement = 'top',
  minWidth = '640px',
  testId,
  primaryActionTestId = 'workflow-version-show-changes-button',
}: VersionPreviewBannerProps): JSX.Element => (
  <Box
    data-testid={testId}
    position='absolute'
    top={placement === 'top' ? '20px' : undefined}
    bottom={placement === 'bottom' ? '24px' : undefined}
    left='50%'
    transform='translateX(-50%)'
    zIndex={placement === 'top' ? 100 : 6}
    bg='gray.100'
    border='1px solid'
    borderColor='gray.400'
    borderRadius='8px'
    boxShadow='0px 4px 12px rgba(0, 0, 0, 0.08)'
    p='8px 16px'
    w='fit-content'
    minW={minWidth}
  >
    <Flex align='center' justify='space-between' gap='24px'>
      <Flex align='center' gap='12px'>
        <Icon as={FiEye} color='gray.600' boxSize='18px' />
        <Flex align='center' gap='6px'>
          <Text fontSize='14px' fontWeight='400' color='black.500' lineHeight='20px'>
            Previewing version
          </Text>
          <Box
            bg='gray.200'
            color='black.300'
            fontSize='12px'
            lineHeight='18px'
            fontWeight='600'
            px='8px'
            py='2px'
            borderRadius='4px'
            border='1px solid'
            borderColor='gray.500'
          >
            {versionLabel}
          </Box>
        </Flex>
      </Flex>

      <Flex align='center' gap='12px'>
        <Button
          variant='ghost'
          size='sm'
          onClick={onCancel}
          isDisabled={isLoading}
          fontWeight='700'
          fontSize='12px'
          bg='gray.300'
          border='1px solid'
          borderColor='gray.400'
          borderRadius='6px'
          color='black.500'
          px='12px'
          _hover={{ bg: 'gray.500' }}
        >
          Cancel
        </Button>
        <Button
          size='sm'
          bg='primary.400'
          color='gray.100'
          onClick={onPrimaryAction}
          isLoading={isLoading}
          loadingText={primaryActionLoadingText}
          fontWeight='700'
          fontSize='12px'
          width='auto'
          data-testid={primaryActionTestId}
        >
          {primaryActionLabel}
        </Button>
      </Flex>
    </Flex>
  </Box>
);

export default VersionPreviewBanner;
