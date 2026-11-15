import { Box, Button, Flex, HStack, Heading, Icon, Text, Tooltip } from '@chakra-ui/react';
import { Step } from '../Breadcrumbs/types';
import Breadcrumbs from '../Breadcrumbs';
import { FiInfo } from 'react-icons/fi';

type TopBarType = {
  name: string;
  nameTooltip?: string;
  nameTooltipVisible?: boolean;
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
  nameTooltip = '',
  nameTooltipVisible = false,
  ctaName = '',
  ctaIcon,
  onCtaClicked = () => {},
  isCtaVisible,
  extra,
  ctaButtonVariant = 'solid',
  ctaButtonWidth,
  ctaButtonHeight,
  breadcrumbSteps = [],
<<<<<<< HEAD
}: TopBarType): JSX.Element => (
  <Flex justifyContent='space-between' borderColor='gray.400' marginBottom='30px'>
    <Box>
      {breadcrumbSteps.length > 0 ? <Breadcrumbs steps={breadcrumbSteps} /> : null}
      <Heading fontWeight='bold' size='sm'>
        {name}
      </Heading>
    </Box>
    <HStack spacing={2} style={{ alignItems: 'flex-end' }}>
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
=======
}: TopBarType): JSX.Element => {
  return (
    <Flex justifyContent='space-between' borderColor='gray.400' marginBottom='30px'>
      <Box>
        {breadcrumbSteps.length > 0 ? <Breadcrumbs steps={breadcrumbSteps} /> : null}
        <Box display='flex' alignItems='center' gap='4px'>
          <Heading fontWeight='bold' size='sm'>
            {name}
          </Heading>
          {nameTooltipVisible && nameTooltip.length > 0 && (
            <Box h='32px' w='32px' display='flex' alignItems='center' justifyContent='center'>
              <Tooltip
                hasArrow
                label={nameTooltip}
                fontSize='xs'
                placement='bottom-start'
                backgroundColor='black.500'
                color='gray.100'
                borderRadius='6px'
                padding='8px'
                width='auto'
              >
                <span>
                  <Icon as={FiInfo} color='gray.600' w='16px' h='16px' />
                </span>
              </Tooltip>
            </Box>
          )}
        </Box>
      </Box>
      <HStack spacing={2} style={{ alignItems: 'flex-end' }}>
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
};
>>>>>>> d2c965ab (feat(CE): added tooltip to titlebar)

export default TopBar;
