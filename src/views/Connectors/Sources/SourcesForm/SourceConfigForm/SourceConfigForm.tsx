import { useQuery } from "@tanstack/react-query";

import { SteppedFormContext } from "@/components/SteppedForm/SteppedForm";
import { getConnectorDefinition } from "@/services/connectors";
import { useContext } from "react";
import { Box } from "@chakra-ui/react";

import validator from "@rjsf/validator-ajv8";
import { Form } from "@rjsf/chakra-ui";
import SourceFormFooter from "@/views/Connectors/Sources/SourcesForm/SourceFormFooter";

import Loader from "@/components/Loader";
import { processFormData } from "@/views/Connectors/helpers";
import ContentContainer from "@/components/ContentContainer";
import MWObjectFieldTemplate from "@/views/Connectors/Sources/SourcesForm/SourceConfigForm/MWObjectFieldTemplate";
import MWTitleField from "@/views/Connectors/Sources/SourcesForm/SourceConfigForm/MWTitleField";

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

  if (isLoading) return <Loader />;

  const handleFormSubmit = async (formData: FormData) => {
    const processedFormData = processFormData(formData);
    handleMoveForward(stepInfo?.formKey as string, processedFormData);
  };

  const connectorSchema = data?.data?.connector_spec?.connection_specification;
  if (!connectorSchema) return null;
  return (
    <Box display="flex" justifyContent="center" marginBottom="80px">
      <ContentContainer>
        <Box backgroundColor="gray.200" padding="20px" borderRadius="8px">
          <Form
            uiSchema={(connectorSchema as any).title.toLowerCase() === "amazon redshift" ? uiSchema : undefined}
            schema={connectorSchema}
            validator={validator}
            templates={{ObjectFieldTemplate: MWObjectFieldTemplate, TitleFieldTemplate: MWTitleField}}
            onSubmit={({ formData }) => handleFormSubmit(formData)}
          >
            <SourceFormFooter ctaName="Continue" ctaType="submit" />
          </Form>
        </Box>
      </ContentContainer>
    </Box>
  );
};

const uiSchema = {
  "ui:order": ["host", "port", "database", "credentials", "schema"],
  "ui:layout": {
    display: "grid",
    cols: 2,
    colspans: [2, 1, 1, 2, 2]
  },
  host: {
    "ui:placeholder": "redshift-host.us-east-1.redshift.amazonaws.com",
  },
  credentials: {
    "ui:layout": {
      display: "grid",
      cols: 2,
      colspans: [1, 1]
    },
    auth_type: {
      "ui:widget": "hidden"
    }
  }
}

export default SourceConfigForm;
