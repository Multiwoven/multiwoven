import React from 'react';
import { Box, Button, Text } from '@chakra-ui/react';
import { CheckCircleIcon, InfoIcon, Icon, CloseIcon } from '@chakra-ui/icons';

export enum CustomToastStatus {
  Success = 'success',
  Info = 'info',
  Warning = 'warning',
  Error = 'error',
  Default = 'default',
}
interface CustomToastIconProps {
  status: CustomToastStatus;
}
interface ToastProps {
  title: string;
  description?: string;
  status: CustomToastStatus;
  toastContainerStyle?: Record<string, string>;
  onClose: () => void;
}

const CustomToastIcon: React.FC<CustomToastIconProps> = ({
  status = CustomToastStatus.Default,
}) => {
  const color: string = status ? `${status}.400` : 'info.400';
  return (
    <Icon
      as={status === CustomToastStatus.Success ? CheckCircleIcon : InfoIcon}
      color={color}
      marginRight='16px'
      boxSize='20px'
    />
  );
};

const Toast: React.FC<ToastProps> = ({
  title = '',
  status = CustomToastStatus.Default,
  toastContainerStyle = {},
  description,
  onClose = () => {},
}) => {
  let backgroundColor: string = `${status}.100`;
  let borderColor: string = `${status}.200`;

  if (status === CustomToastStatus.Default) {
    backgroundColor = 'gray.200';
    borderColor = 'gray.500';
  }

  return (
    <Box
      bg={backgroundColor}
      border='1px solid'
      borderColor={borderColor}
      width='400px'
      paddingX='16px'
      paddingY='20px'
      borderRadius='8px'
      display='flex'
      justifyContent='space-between'
      style={toastContainerStyle}
    >
      <Box display='flex' justifyContent='flex-start' alignItems='center'>
        <CustomToastIcon status={status as CustomToastStatus} />
        <Box>
          <Text color='black.500' size='sm' fontWeight='semibold'>
            {title}
          </Text>
          {description && (
            <Text color='black.200' size='sm'>
              {description}
            </Text>
          )}
        </Box>
      </Box>

      <Button
        variant='unstyled'
        width='20px'
        onClick={onClose}
        marginX='16px'
        height='20px'
        minWidth='0'
      >
        <Icon as={CloseIcon} color='black.100' />
      </Button>
    </Box>
  );
};

export default Toast;
