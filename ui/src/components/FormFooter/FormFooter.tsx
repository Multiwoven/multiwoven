import { useUiConfig } from '@/utils/hooks';
import { Box, Button, ButtonGroup, Icon, Text } from '@chakra-ui/react';
import { useEffect, useState } from 'react';
import { FiBookOpen, FiHeadphones } from 'react-icons/fi';
import { Link, useNavigate } from 'react-router-dom';

type SourceFormFooterProps = {
  ctaName: string;
  ctaType?: 'button' | 'reset' | 'submit' | undefined;
  onCtaClick?: undefined | (() => void);
  isCtaDisabled?: boolean;
  isCtaLoading?: boolean;
  isBackRequired?: boolean;
  isAlignToContentContainer?: boolean;
  extra?: JSX.Element;
};

const FormFooter = ({
  ctaName,
  ctaType = 'button',
  isAlignToContentContainer,
  onCtaClick,
  isBackRequired,
  extra,
  isCtaLoading = false,
  isCtaDisabled = false,
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
      bottom='0'
      backgroundColor='#fff'
      padding='30px'
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
      >
        <Box display='flex'>
          <Link to='https://docs.multiwoven.com'>
            <Box display='flex' alignItems='center' marginRight='20px'>
              <Icon as={FiBookOpen} color='gray.600' />
              <Text ml={2} size='sm'>
                Read Documentation
              </Text>
            </Box>
          </Link>
          <Link to='https://docs.multiwoven.com'>
            <Box display='flex' alignItems='center'>
              <Icon as={FiHeadphones} color='gray.600' />
              <Text ml={2} size='sm'>
                Contact Support
              </Text>
            </Box>
          </Link>
        </Box>
        <ButtonGroup>
          {extra}
          {isBackRequired ? (
            <Button
              onClick={() => navigate(-1)}
              marginRight='10px'
              variant='ghost'
              minWidth={0}
              width='auto'
            >
              Back
            </Button>
          ) : null}
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
        </ButtonGroup>
      </Box>
    </Box>
  );
};

export default FormFooter;
