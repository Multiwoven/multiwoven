import { Button, Flex, Heading } from "@chakra-ui/react";

type TopBarType = {
  name: string;
  ctaName: string;
  ctaIcon: JSX.Element;
  onCtaClicked: () => void;
  isCtaVisible?: boolean;
};

const TopBar = ({
  name,
  ctaName = "",
  ctaIcon,
  onCtaClicked = () => {},
  isCtaVisible,
}: TopBarType): JSX.Element => (
  <Flex justifyContent="space-between" p={4} borderColor="gray.300" mb={4}>
    <Heading size="xl" _dark={{ color: "white" }}>
      {name}
    </Heading>
    {isCtaVisible ? (
      <Button
        leftIcon={ctaIcon}
        backgroundColor="orange.500"
        _hover={{ bgColor: "orange.400" }}
        p={4}
        fontSize={16}
        size="sm"
        onClick={onCtaClicked}
      >
        {ctaName}
      </Button>
    ) : (
      <></>
    )}
  </Flex>
);

export default TopBar;
