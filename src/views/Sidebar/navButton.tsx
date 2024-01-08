import { As, Button, ButtonProps, HStack, Icon, Text } from '@chakra-ui/react'

interface NavButtonProps extends ButtonProps {
  icon: As
  label: string
}

export const NavButton = (props: NavButtonProps) => {
  const { icon, label, ...buttonProps } = props
  return (
    <Button variant="tertiary" justifyContent="start" {...buttonProps}>
      <HStack spacing="2">
        <Icon as={icon} boxSize="4" color="fg.subtle" />
        <Text color={'#101828'} fontWeight={'500'} fontSize='sm'>{label}</Text>
      </HStack>
    </Button>
  )
}