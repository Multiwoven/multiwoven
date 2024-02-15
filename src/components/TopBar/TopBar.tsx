import { Button, Flex, HStack, Heading, Text } from '@chakra-ui/react';

type TopBarType = {
  name: string;
  ctaName?: string;
  ctaIcon?: JSX.Element;
  ctaColor?: string;
  ctaBgColor?: string;
  ctaHoverBgColor?: string;
  onCtaClicked?: () => void;
  isCtaVisible?: boolean;
  extra?: JSX.Element;
  ctaButtonVariant?: string;
  ctaButtonWidth?: string;
  ctaButtonHeight?: string;
};

const TopBar = ({
  name,
  ctaName = '',
  ctaIcon,
  onCtaClicked = () => {},
  isCtaVisible,
  extra,
  ctaButtonVariant = 'solid',
  ctaButtonWidth,
  ctaButtonHeight,
}: TopBarType): JSX.Element => (
  <Flex
    justifyContent='space-between'
    borderColor='gray.400'
    marginBottom='48px'
  >
    <Heading
      fontWeight='700'
      size='sm'
      color='black.500'
      letterSpacing='-0.3px'
    >
      {name}
    </Heading>
    <HStack spacing={2}>
      {extra}
      {isCtaVisible ? (
        <Button
          variant={ctaButtonVariant}
          leftIcon={ctaIcon}
          width={ctaButtonWidth || '126px'}
          height={ctaButtonHeight || '40px'}
          onClick={onCtaClicked}
          letterSpacing="-0.14px"
        >
          <Text size='sm'>{ctaName}</Text>
        </Button>
      ) : (
        <></>
      )}
    </HStack>
  </Flex>
);

export default TopBar;
