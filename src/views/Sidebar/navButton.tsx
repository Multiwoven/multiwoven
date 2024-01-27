import { As, Button, ButtonProps, HStack, Icon, Text } from "@chakra-ui/react";

interface NavButtonProps extends ButtonProps {
  icon: As;
  label: string;
}

export const NavButton = (props: NavButtonProps): JSX.Element => {
  const { icon, label, isActive, ...buttonProps } = props;
  return (
    <Button
      variant="tertiary"
      justifyContent="start"
      backgroundColor={isActive ? "gray.200" : "none"}
      _hover={{ bg: "gray.200" }}
      marginBottom="10px"
      width="100%"
      size="sm"
    >
      <HStack spacing="2">
        <Icon as={icon} boxSize="4" color="fg.subtle" />
        <Text color={"#101828"} fontWeight={"500"} fontSize="sm">
          {label}
        </Text>
      </HStack>
    </Button>
  );
};
