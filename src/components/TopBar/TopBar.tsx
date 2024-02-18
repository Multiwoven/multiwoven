import { Box, Button, Flex, HStack, Heading, Text } from '@chakra-ui/react';
import { Step } from '../Breadcrumbs/types';
import Breadcrumbs from '../Breadcrumbs';

type TopBarType = {
  name: string;
  ctaName?: string;
  ctaIcon?: JSX.Element;
  ctaColor?: string;
  ctaBgColor?: string;
  ctaHoverBgColor?: string;
  onCtaClicked?: () => void;
  isCtaVisible?: boolean;
  extra?: JSX.Element | null;
  breadcrumbSteps?: Step[];
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
  breadcrumbSteps = [],
}: TopBarType): JSX.Element => (
  <Flex
    justifyContent='space-between'
    borderColor='gray.400'
    marginBottom='30px'
  >
    <Box>
      {breadcrumbSteps.length > 0 ? (
        <Breadcrumbs steps={breadcrumbSteps} />
      ) : null}
      <Heading fontWeight='bold' size='sm'>
        {name}
      </Heading>
    </Box>
    <HStack spacing={2}>
      {extra}
      {isCtaVisible ? (
        <Button
          variant={ctaButtonVariant}
          leftIcon={ctaIcon}
          width={ctaButtonWidth || '126px'}
          height={ctaButtonHeight || '40px'}
          onClick={onCtaClicked}
          fontSize='16px'
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
