import { Button, Flex, Heading } from "@chakra-ui/react";

type TopBarType = {
  name: string;
  ctaName?: string;
  ctaIcon?: JSX.Element;
  ctaColor?: string;
  ctaBgColor?: string;
  ctaHoverBgColor?: string;
  onCtaClicked?: () => void;
  isCtaVisible?: boolean;
};

const TopBar = ({
  name,
  ctaName = "",
  ctaIcon,
  onCtaClicked = () => {},
  isCtaVisible,
}: TopBarType): JSX.Element => (
  <Flex
    justifyContent="space-between"
    borderColor="gray.300"
    marginBottom="30px"
  >
    <Heading as="h6" fontWeight="500" size="lg">
      {name}
    </Heading>
    {isCtaVisible ? (
      <Button
        variant="solid"
        leftIcon={ctaIcon}
        size="lg"
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
