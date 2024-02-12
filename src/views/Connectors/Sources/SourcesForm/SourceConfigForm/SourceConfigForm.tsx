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
    const processedFormData = processFormData(formData)
    handleMoveForward(stepInfo?.formKey as string, processedFormData);
  };

  const connectorSchema = data?.data?.connector_spec?.connection_specification;
  if (!connectorSchema) return null;

  // const uiSchema = { 
  //   "title" : { 
  //     "ui:"
  //   }
  // }


  return (
    <Box
      display="flex"
      justifyContent="center"
      marginBottom="80px"
    >
       <ContentContainer>
        <Box backgroundColor="gray.200" padding="20px" borderRadius="8px">
        <Form
          schema={connectorSchema}
          validator={validator}
          onSubmit={({ formData }) => handleFormSubmit(formData)}
        >
          <SourceFormFooter ctaName="Continue" ctaType="submit" />
        </Form>
        </Box>
       </ContentContainer>
    </Box>
  );
};

export default SourceConfigForm;
