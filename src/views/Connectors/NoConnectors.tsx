import { Container, Stack, Text } from "@chakra-ui/react";
import { Link } from "react-router-dom";

const NoConnectors = (connectorType: any) => {
  return (
    <>
      <Link to="new">
        <Container
          bgColor="gray.100"
          shadow="md"
          _hover={{ backgroundColor: "gray.200", borderColor: "gray.500" }}
          w="container.sm"
          border="2px"
          borderStyle="dashed"
          borderColor="gray.400"
        >
          <Stack spacing="6" textAlign="center" alignItems="center" p="12">
            <svg
              className="mx-auto h-12 w-12 text-gray-400"
              stroke="gray"
              fill="none"
              viewBox="0 0 48 48"
              aria-hidden="true"
              width="128"
            >
              <path
                strokeLinecap="round"
                strokeLinejoin="round"
                strokeWidth={2}
                d="M8 14v20c0 4.418 7.163 8 16 8 1.381 0 2.721-.087 4-.252M8 14c0 4.418 7.163 8 16 8s16-3.582 16-8M8 14c0-4.418 7.163-8 16-8s16 3.582 16 8m0 0v14m0-4c0 4.418-7.163 8-16 8S8 28.418 8 24m32 10v6m0 0v6m0-6h6m-6 0h-6"
              />
            </svg>

            <Text size="md" color="gray.900">Create a new {connectorType.connectorType}</Text>
          </Stack>
        </Container>
      </Link>
    </>
  );
};

export default NoConnectors;
