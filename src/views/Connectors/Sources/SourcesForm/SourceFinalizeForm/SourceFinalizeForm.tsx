import { Box, Heading, Input, Text, Textarea } from "@chakra-ui/react";
import SourceFormFooter from "../SourceFormFooter";

const SourceFinalizeForm = (): JSX.Element | null => {
  return (
    <Box display="flex" justifyContent="center">
      <Box maxWidth="850px" width="100%">
        <Box padding="24px" backgroundColor="gray.100" borderRadius="8px">
          <Heading size="md" fontWeight="600" marginBottom="24px">
            Finalize settings for this source
          </Heading>
          <Box>
            <Text marginBottom="8px" fontWeight="600">
              Source Name
            </Text>
            <Input
              name="connector_name"
              type="text"
              placeholder="Enter source name"
              background="#fff"
              marginBottom="24px"
            />
            <Text marginBottom="8px" fontWeight="600">
              Description
            </Text>
            <Textarea
              name="connector_description"
              placeholder="Enter a description"
              background="#fff"
              resize="none"
            />
          </Box>
        </Box>
        <SourceFormFooter ctaName="Finish" ctaType="submit" />
      </Box>
    </Box>
  );
};

export default SourceFinalizeForm;
