import { useQuery } from "@tanstack/react-query";

import { SteppedFormContext } from "@/components/SteppedForm/SteppedForm";
import { getConnectorDefinition } from "@/services/connectors";
import { useContext } from "react";
import { Box, ChakraProvider, Spinner } from "@chakra-ui/react";

import validator from "@rjsf/validator-ajv8";
import { Form } from "@rjsf/chakra-ui";
import { extendTheme } from "@chakra-ui/react";

const SourceConfigForm = (): JSX.Element | null => {
  const { state } = useContext(SteppedFormContext);
  const { forms } = state;
  const selectedDataSource = forms.find(
    ({ stepKey }) => stepKey === "datasource"
  );
  const datasource = selectedDataSource?.data?.datasource as string;

  if (!datasource) return null;

  const { data, isLoading } = useQuery({
    queryKey: ["connector_definition", datasource],
    queryFn: () => getConnectorDefinition("source", datasource),
    enabled: !!datasource,
    refetchOnMount: false,
    refetchOnWindowFocus: false,
  });

  const onFormSubmit = (data) => {};

  if (isLoading)
    return (
      <Box
        height="30vh"
        width="100%"
        display="flex"
        alignItems="center"
        justifyContent="center"
      >
        <Spinner size="lg" />
      </Box>
    );

  const connectorSchema = data?.data?.connector_spec?.connection_specification;
  if (!connectorSchema) return null;

  const theme = extendTheme({
    colors: {
      brand: {
        100: "#f7fafc",
        // ...
        900: "#1a202c",
      },
    },
  });

  return (
    <Box padding="20px" display="flex" justifyContent="center">
      <Box maxWidth="1300px" width="100%">
        <Form
          schema={connectorSchema}
          validator={validator}
          onChange={({ formData }) => {}}
          onSubmit={(data) => onFormSubmit(data)}
        >
          <button type="submit">Submit Custom</button>
        </Form>
      </Box>
    </Box>
  );
};

export default SourceConfigForm;
