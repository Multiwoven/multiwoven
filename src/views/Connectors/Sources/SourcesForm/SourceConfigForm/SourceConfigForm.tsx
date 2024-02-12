import { useQuery } from "@tanstack/react-query";

import { SteppedFormContext } from "@/components/SteppedForm/SteppedForm";
import { getConnectorDefinition } from "@/services/connectors";
import { useContext } from "react";
import { Box } from "@chakra-ui/react";

import validator from "@rjsf/validator-ajv8";
import { Form } from "@rjsf/chakra-ui";
import SourceFormFooter from "@/views/Connectors/Sources/SourcesForm/SourceFormFooter";
import { useUiConfig } from "@/utils/hooks";
import Loader from "@/components/Loader";

const SourceConfigForm = (): JSX.Element | null => {
  const { state, stepInfo, handleMoveForward } = useContext(SteppedFormContext);
  const { maxContentWidth } = useUiConfig();
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

  if (isLoading) return <Loader />;

  const handleFormSubmit = async (formData: FormData) => {
    handleMoveForward(stepInfo?.formKey as string, formData);
  };

  const connectorSchema = data?.data?.connector_spec?.connection_specification;
  if (!connectorSchema) return null;

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

export default SourceConfigForm;
