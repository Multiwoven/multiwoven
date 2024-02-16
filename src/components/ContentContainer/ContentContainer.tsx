import { useUiConfig } from '@/utils/hooks';
import { Box } from '@chakra-ui/react';
import { ReactNode, RefObject } from 'react';

const ContentContainer = ({
  children,
  containerRef,
  applyPadding = true,
}: {
  children: ReactNode;
  containerRef?: RefObject<HTMLDivElement>;
  applyPadding?: boolean;
}): JSX.Element => {
  const { maxContentWidth } = useUiConfig();

  return (
    <Box
      maxWidth={maxContentWidth}
      width='100%'
      padding={applyPadding ? '30px' : '0'}
      ref={containerRef}
    >
      {children}
    </Box>
  );
};

export default ContentContainer;
