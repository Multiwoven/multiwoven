import { useQuery } from "@tanstack/react-query";

import { SteppedFormContext } from "@/components/SteppedForm/SteppedForm";
import { getConnectorDefinition } from "@/services/connectors";
import { useContext } from "react";
import { Box, Spinner } from "@chakra-ui/react";

import validator from "@rjsf/validator-ajv8";
import { Form } from "@rjsf/chakra-ui";
import SourceFormFooter from "@/views/Connectors/Sources/SourcesForm/SourceFormFooter";

const SourceConfigForm = (): JSX.Element | null => {
  const { state, stepInfo, handleMoveForward } = useContext(SteppedFormContext);
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

  const handleFormSubmit = async (formData: FormData) => {
    console.log(formData);
    handleMoveForward(stepInfo?.formKey as string, formData);
  };

  const connectorSchema = data?.data?.connector_spec?.connection_specification;
  if (!connectorSchema) return null;

  const formData = {
    credentials: {
      auth_type: "username/password",
      username: "MULTIWOVEN_USER",
      password: "asdad",
    },
    host: "accountname.us-east-2.aws.snowflakecomputing.com",
    role: "MULTIWOVEN_ROLE",
    warehouse: "MULTIWOVEN_WAREHOUSE",
    database: "MULTIWOVEN_DATABASE",
    schema: "MULTIWOVEN_SCHEMA",
    jdbc_url_params: "addsadad",
  };

  return (
    <Box
      padding="20px"
      display="flex"
      justifyContent="center"
      marginBottom="80px"
    >
      <Box maxWidth="850px" width="100%">
        <Form
          schema={connectorSchema}
          validator={validator}
          onSubmit={({ formData }) => handleFormSubmit(formData)}
          formData={formData}
        >
          <SourceFormFooter ctaName="Continue" ctaType="submit" />
        </Form>
      </Box>
    </Box>
  );
};

export default SourceConfigForm;
