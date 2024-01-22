import { Box, Button, Icon, Text } from "@chakra-ui/react";
import { FiBookOpen, FiHeadphones } from "react-icons/fi";
import { Link } from "react-router-dom";

type SourceFormFooterProps = {
  ctaName: string;
  ctaType?: "button" | "reset" | "submit" | undefined;
  onCtaClick?: undefined | (() => void);
  isCtaDisabled?: boolean;
  isCtaLoading?: boolean;
  isBackRequired?: boolean;
};

const SourceFormFooter = ({
  ctaName,
  ctaType = "button",
  onCtaClick,
  isCtaLoading = false,
  isCtaDisabled = false,
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
      minHeight="80px"
      zIndex="1"
    >
      <Box
        maxWidth="850px"
        width="100%"
        display="flex"
        justifyContent="space-between"
        alignItems="center"
      >
        <Box display="flex">
          <Link to="https://docs.multiwoven.com">
            <Box display="flex" alignItems="center" marginRight="20px">
              <Icon as={FiBookOpen} color="gray.600" />
              <Text marginLeft="5px">Read Documentation</Text>
            </Box>
          </Link>
          <Link to="https://docs.multiwoven.com">
            <Box display="flex" alignItems="center">
              <Icon as={FiHeadphones} color="gray.600" />
              <Text marginLeft="5px">Contact Support</Text>
            </Box>
          </Link>
        </Box>
        <Button
          type={ctaType}
          onClick={() => onCtaClick?.()}
          size="lg"
          isDisabled={isCtaDisabled}
          isLoading={isCtaLoading}
        >
          {ctaName}
        </Button>
      </Box>
    </Box>
  );
};

export default SourceFormFooter;
