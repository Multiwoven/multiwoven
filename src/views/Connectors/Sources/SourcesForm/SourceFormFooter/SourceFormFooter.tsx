import { Box, Button } from "@chakra-ui/react";

type SourceFormFooterProps = {
  ctaName: string;
  ctaType?: "button" | "reset" | "submit" | undefined;
  onCtaClick: undefined | (() => void);
  isBackRequired?: boolean;
};

const SourceFormFooter = ({
  ctaName,
  ctaType = "button",
  onCtaClick,
  isBackRequired,
}: SourceFormFooterProps): JSX.Element => {
  return (
    <Box
      position="fixed"
      left="0"
      right="0"
      borderWidth="thin"
      bottom="0"
      backgroundColor="#fff"
      padding="10px"
      display="flex"
      justifyContent="center"
    >
      <Box maxWidth="1300px" width="100%">
        <Button type={ctaType} onClick={() => onCtaClick?.()}>
          {ctaName}
        </Button>
      </Box>
    </Box>
  );
};

export default SourceFormFooter;
