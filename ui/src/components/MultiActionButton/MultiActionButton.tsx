import { Button, ChakraProps, Icon, Text } from '@chakra-ui/react';
import { IconType } from 'react-icons/lib';

type MultiActionButtonProps = {
  buttonTextColor: ChakraProps['bgColor'] | 'red.600' | 'gray.200';
  buttonHoverColor: ChakraProps['bgColor'] | 'gray.200';
  textColor: ChakraProps['color'] | 'red.500' | 'black.500';
  icon: IconType;
  iconColor: ChakraProps['color'] | 'red.600' | 'gray.600';
  text: string;
  onClick: () => void;
};

const MultiActionButton = ({
  buttonTextColor = 'gray.200',
  buttonHoverColor = 'gray.300',
  textColor = 'black.500',
  icon,
  iconColor = 'gray.600',
  text,
  onClick,
}: MultiActionButtonProps) => {
  return (
    <>
      <Button
        _hover={{ bgColor: buttonHoverColor }}
        w='100%'
        py={3}
        px={2}
        display='flex'
        flexDir='row'
        alignItems='center'
        color={buttonTextColor}
        rounded='lg'
        onClick={onClick}
        as='button'
        justifyContent='start'
        border={0}
        variant='shell'
        data-testid='multi-action-button'
      >
        <Icon as={icon} color={iconColor} />
        <Text size='sm' fontWeight='medium' ml={3} color={textColor}>
          {text}
        </Text>
      </Button>
    </>
  );
};

export default MultiActionButton;
