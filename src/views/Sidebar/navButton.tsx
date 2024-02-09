import { As, Button, ButtonProps, HStack, Icon, Text } from "@chakra-ui/react";

interface NavButtonProps extends ButtonProps {
  icon: As;
  label: string;
}

export const NavButton = (props: NavButtonProps): JSX.Element => {
  const { icon, label, isActive } = props;
  return (
    <Button
      variant="tertiary"
      justifyContent="start"
      backgroundColor={isActive ? "gray.400" : "none"}
      _hover={{ bg: "gray.400" }}
      marginBottom="10px"
      width="100%"
      size="sm"
    >
      <HStack spacing="2">
        <Icon as={icon} boxSize="4" color={isActive ? "black.500" : "gray.600"} />
        <Text color={"black.500"} fontWeight={isActive ? "600" : "500"} fontSize="sm">
          {label}
        </Text>
      </HStack>
    </Button>
  );
};
