import { Box, Heading, Input, Text, Textarea } from "@chakra-ui/react";
import SourceFormFooter from "../SourceFormFooter";
import { useFormik } from "formik";

const SourceFinalizeForm = (): JSX.Element | null => {
  const formik = useFormik({
    initialValues: {
      connector_name: "Something",
      description: "",
    },
    onSubmit: (values) => {
      console.log(values);
    },
  });

  return (
    <Box display="flex" justifyContent="center">
      <Box maxWidth="850px" width="100%">
        <form onSubmit={formik.handleSubmit}>
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
                onChange={formik.handleChange}
                value={formik.values.connector_name}
                required
              />
              <Box display="flex">
                <Text marginBottom="8px" fontWeight="600">
                  Description
                </Text>{" "}
                <Text>(Optional)</Text>
              </Box>
              <Textarea
                name="description"
                placeholder="Enter a description"
                background="#fff"
                resize="none"
                onChange={formik.handleChange}
                value={formik.values.description}
              />
            </Box>
          </Box>
          <SourceFormFooter ctaName="Finish" ctaType="submit" />
        </form>
      </Box>
    </Box>
  );
};

export default SourceFinalizeForm;
