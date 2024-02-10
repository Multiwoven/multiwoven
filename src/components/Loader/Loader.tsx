import { Box, Center, Flex, Spinner } from "@chakra-ui/react";

const Loader = (): JSX.Element => {
  return (
    <Flex
      width="100%"
      height="100vh"
      alignContent="center"
      justifyContent="center"
    >
      <Center>
        <Box>
          <Spinner
            thickness="4px"
            speed="0.65s"
            emptyColor="gray.200"
            color="brand.500"
            size="xl"
          />
        </Box>
      </Center>
    </Flex>
  );
};

export default Loader;
