import { SteppedFormContext } from "@/components/SteppedForm/SteppedForm";
import { getConnectorDefinition } from "@/services/connectors";
import { useUiConfig } from "@/utils/hooks";
import SourceFormFooter from "@/views/Connectors/Sources/SourcesForm/SourceFormFooter";
import { Box } from "@chakra-ui/react";
import { useQuery } from "@tanstack/react-query";
import { useContext } from "react";

import validator from "@rjsf/validator-ajv8";
import { Form } from "@rjsf/chakra-ui";
import Loader from "@/components/Loader";

const DestinationConfigForm = (): JSX.Element | null => {
  const { state, stepInfo, handleMoveForward } = useContext(SteppedFormContext);
  const { maxContentWidth } = useUiConfig();
  const { forms } = state;
  const selectedDestination = forms.find(
    ({ stepKey }) => stepKey === "destination"
  );

  const destination = selectedDestination?.data?.destination as string;
  if (!destination) return null;

  const { data, isLoading } = useQuery({
    queryKey: ["connector_definition", destination],
    queryFn: () => getConnectorDefinition("destination", destination),
    enabled: !!destination,
    refetchOnMount: false,
    refetchOnWindowFocus: false,
  });

  if (isLoading) return <Loader />;

  const connectorSchema = data?.data?.connector_spec?.connection_specification;
  if (!connectorSchema) return null;

  const handleFormSubmit = async (formData: FormData) => {
    handleMoveForward(stepInfo?.formKey as string, formData);
  };

  return (
    <Box
      padding="20px"
      display="flex"
      justifyContent="center"
      marginBottom="80px"
    >
      <Box maxWidth={maxContentWidth} width="100%">
        <Form
          schema={connectorSchema}
          validator={validator}
          onSubmit={({ formData }) => handleFormSubmit(formData)}
        >
          <SourceFormFooter ctaName="Continue" ctaType="submit" />
        </Form>
      </Box>
    </Box>
  );
};

export default DestinationConfigForm;
