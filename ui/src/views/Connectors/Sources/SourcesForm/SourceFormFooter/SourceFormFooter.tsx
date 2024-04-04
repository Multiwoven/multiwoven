import { useUiConfig } from '@/utils/hooks';
import { Box, Button, ButtonGroup, Icon, Text } from '@chakra-ui/react';
import { useEffect, useState } from 'react';
import { FiBookOpen, FiSlack } from 'react-icons/fi';
import { Link, useNavigate } from 'react-router-dom';

type SourceFormFooterProps = {
  ctaName: string;
  secondaryCtaText?: string;
  ctaType?: 'button' | 'reset' | 'submit' | undefined;
  onCtaClick?: undefined | (() => void);
  isCtaDisabled?: boolean;
  isCtaLoading?: boolean;
  isBackRequired?: boolean;
  isContinueCtaRequired?: boolean;
  isDocumentsSectionRequired?: boolean;
  isAlignToContentContainer?: boolean;
  extra?: JSX.Element;
};

const SourceFormFooter = ({
  ctaName,
  ctaType = 'button',
  isAlignToContentContainer,
  onCtaClick,
  isBackRequired,
  extra,
  isCtaLoading = false,
  isCtaDisabled = false,
  isContinueCtaRequired = false,
  isDocumentsSectionRequired = false,
  secondaryCtaText = 'Back',
}: SourceFormFooterProps): JSX.Element => {
  const [leftOffset, setLeftOffet] = useState<number>(0);
  const { maxContentWidth } = useUiConfig();
  const navigate = useNavigate();
  const { contentContainerId } = useUiConfig();

  useEffect(() => {
    if (isAlignToContentContainer) {
      setLeftOffet(document.getElementById(contentContainerId)?.getBoundingClientRect()?.left ?? 0);
    }
  }, [isAlignToContentContainer]);

  return (
    <Box
      position='fixed'
      left={leftOffset}
      right='0'
      borderWidth='thin'
      borderColor='gray.400'
      bottom='0'
      backgroundColor='gray.100'
      display='flex'
      justifyContent='center'
      minHeight='80px'
      zIndex='1'
    >
      <Box
        maxWidth={maxContentWidth}
        width='100%'
        display='flex'
        justifyContent='space-between'
        alignItems='center'
        paddingX='30px'
      >
        <Box display='flex' paddingX='16px' paddingY='10px'>
          {isDocumentsSectionRequired ? (
            <>
              <Link to='https://docs.multiwoven.com'>
                <Box display='flex' alignItems='center' marginRight='20px'>
                  <Icon as={FiBookOpen} color='gray.600' />
                  <Text ml={2} size='sm'>
                    Read Documentation
                  </Text>
                </Box>
              </Link>
              <Link
                to='https://join.slack.com/t/multiwoven/shared_invite/zt-2bnjye26u-~lu_FFOMLpChOYxvovep7g'
                target='_blank'
              >
                <Box display='flex' alignItems='center'>
                  <Icon as={FiSlack} color='gray.600' />
                  <Text ml={2} size='sm'>
                    Contact Support
                  </Text>
                </Box>
              </Link>
            </>
          ) : null}
        </Box>
        <ButtonGroup>
          {extra}
          {isBackRequired ? (
            <Button
              onClick={() => navigate(-1)}
              marginRight={isContinueCtaRequired ? '10px' : '0'}
              variant='ghost'
              minWidth={0}
              width='auto'
            >
              {secondaryCtaText}
            </Button>
          ) : null}
          {isContinueCtaRequired ? (
            <Button
              type={ctaType}
              onClick={() => onCtaClick?.()}
              isDisabled={isCtaDisabled}
              isLoading={isCtaLoading}
              minWidth={0}
              width='auto'
            >
              {ctaName}
            </Button>
          ) : null}
        </ButtonGroup>
      </Box>
    </Box>
  );
};

export default SourceFormFooter;
