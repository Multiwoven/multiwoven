import { useUiConfig } from '@/utils/hooks';
import { Box, Button, HStack } from '@chakra-ui/react';
import { useEffect, useState } from 'react';

type ButtonConfig = {
  name: string;
  type?: 'button' | 'reset' | 'submit';
  onClick?: () => void;
  isDisabled?: boolean;
  isLoading?: boolean;
  color?: string;
  bgColor?: string;
  hoverColor?: string;
  hoverBgColor?: string;
  variant?: string;
};

type ModelFooterProps = {
  buttons: ButtonConfig[];
  isBackRequired?: boolean;
  isAlignToContentContainer?: boolean;
};

const ModelFooter = ({ buttons, isAlignToContentContainer }: ModelFooterProps): JSX.Element => {
  const [leftOffset, setLeftOffet] = useState<number>(0);
  const { maxContentWidth } = useUiConfig();
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
      padding='10px 20px'
      display='flex'
      justifyContent='center'
      minHeight='80px'
      zIndex='1'
    >
      <Box
        maxWidth={maxContentWidth}
        width='100%'
        display='flex'
        justifyContent='end'
        alignItems='center'
      >
        <HStack spacing={3}>
          {buttons.map((button, index) => (
            <Button
              key={index}
              type={button.type || 'button'}
              onClick={button.onClick}
              size='lg'
              w='fit'
              isDisabled={button.isDisabled}
              isLoading={button.isLoading}
              color={button.color}
              bgColor={button.bgColor}
              variant={button.variant || 'solid'}
              _hover={{
                color: button.hoverColor,
                bgColor: button.hoverBgColor,
              }}
            >
              {button.name}
            </Button>
          ))}
        </HStack>
      </Box>
    </Box>
  );
};

export default ModelFooter;
