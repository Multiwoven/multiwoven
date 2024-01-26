import { useUiConfig } from "@/utils/hooks";
import { Box } from "@chakra-ui/react";
import { ReactNode, RefObject } from "react";

const ContentContainer = ({
  children,
  containerRef,
}: {
  children: ReactNode;
  containerRef?: RefObject<HTMLDivElement>;
}): JSX.Element => {
  const { maxContentWidth } = useUiConfig();

  return (
    <Box
      maxWidth={maxContentWidth}
      width="100%"
      padding="30px"
      ref={containerRef}
    >
      {children}
    </Box>
  );
};

export default ContentContainer;
