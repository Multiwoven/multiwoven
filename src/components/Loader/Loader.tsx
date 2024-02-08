import { Box, Spinner } from "@chakra-ui/react"

const Loader = () => {
    return(
        <Box width="100%" display="flex" justifyContent="center">
        <Spinner
          thickness="4px"
          speed="0.65s"
          emptyColor="gray.200"
          color="blue.500"
          size="xl"
        />
      </Box>
    )
}

export default Loader;