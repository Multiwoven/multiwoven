import { useUiConfig } from '@/utils/hooks';
import { Box, Button, ButtonGroup, Text } from '@chakra-ui/react'; // Removed `Icon`
import { useEffect, useState } from 'react';
import { Link, useNavigate } from 'react-router-dom';

type FormFooterProps = {
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
  navigateToListScreen?: boolean;
  listScreenUrl?: string;
};

const FormFooter = ({
  ctaName,
  ctaType = 'button',
  isAlignToContentContainer,
  onCtaClick,
  isBackRequired,
  extra,
  listScreenUrl,
  isCtaLoading = false,
  isCtaDisabled = false,
  isContinueCtaRequired = false,
  isDocumentsSectionRequired = false,
  secondaryCtaText = 'Back',
  navigateToListScreen = false,
}: FormFooterProps): JSX.Element => {
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
              <Link to='https://docs.squared.ai/guides/core-concepts'>
                <Box display='flex' alignItems='center' marginRight='20px'>
                  <Text ml={2} size='sm'></Text>
                </Box>
              </Link>
              <Link
                to='https://join.slack.com/t/multiwoven/shared_invite/zt-2bnjye26u-~lu_FFOMLpChOYxvovep7g'
                target='_blank'
              >
                <Box display='flex' alignItems='center'>
                  <Text ml={2} size='sm'></Text>
                </Box>
              </Link>
            </>
          ) : null}
        </Box>
        <ButtonGroup>
          {extra}
          {isBackRequired ? (
            <Button
              onClick={() =>
                navigateToListScreen && listScreenUrl
                  ? navigate(listScreenUrl, { replace: true })
                  : navigate(-1)
              }
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

export default FormFooter;
