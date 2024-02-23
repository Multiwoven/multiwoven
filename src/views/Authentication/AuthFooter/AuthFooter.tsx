import { Box, HStack, Text } from "@chakra-ui/layout";
import { Link } from "react-router-dom";

const AuthFooter = (): JSX.Element => {
  return (
    <Box
      backgroundColor="gray.100"
      display="flex"
      justifyContent="center"
      height="10vh"
      zIndex="1"
      width="full"
      alignItems="center"
    >
      <HStack>
        <Text color="black.100" fontWeight={400} size="xs">
          © Multiwoven Inc. All rights reserved.
        </Text>
        <Link to="https://multiwoven.com/terms">
          <Text color="brand.500" size="xs" fontWeight={500}>
            Terms of use
          </Text>
        </Link>
        <Text size="xs" color="black.100">
          •
        </Text>
        <Link to="https://multiwoven.com/privacy">
          <Text color="brand.500" size="xs" fontWeight={500}>
            Privacy Policy
          </Text>
        </Link>
      </HStack>
    </Box>
  );
};

export default AuthFooter;
