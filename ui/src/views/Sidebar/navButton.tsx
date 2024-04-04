import Badge from '@/components/Badge';
import { As, Button, ButtonProps, HStack, Icon, Text } from '@chakra-ui/react';

interface NavButtonProps extends ButtonProps {
  icon: As;
  label: string;
  disabled?: boolean;
}

export const NavButton = (props: NavButtonProps): JSX.Element => {
  const { icon, label, isActive, disabled } = props;
  return (
    <Button
      variant='tertiary'
      justifyContent='start'
      backgroundColor={isActive ? 'gray.300' : 'none'}
      _hover={!disabled ? { bg: 'gray.300' } : {}}
      marginBottom='10px'
      width='100%'
      size='sm'
      isDisabled={disabled}
      height='36px'
    >
      <HStack spacing='2'>
        <Icon as={icon} boxSize='4' color={isActive ? 'black.500' : 'gray.600'} />
        <Text color='black.500' fontWeight={isActive ? 'semibold' : 'medium'} size='sm'>
          {label}
        </Text>
        {disabled ? <Badge text='weaving soon' variant='default' /> : <></>}
      </HStack>
    </Button>
  );
};
