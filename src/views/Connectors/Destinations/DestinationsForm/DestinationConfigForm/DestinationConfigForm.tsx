import { SteppedFormContext } from '@/components/SteppedForm/SteppedForm';
import { getConnectorDefinition } from '@/services/connectors';
import { Box } from '@chakra-ui/react';
import { useQuery } from '@tanstack/react-query';
import { useContext } from 'react';

import validator from '@rjsf/validator-ajv8';
import { Form } from '@rjsf/chakra-ui';
import Loader from '@/components/Loader';
import ContentContainer from '@/components/ContentContainer';
import SourceFormFooter from '@/views/Connectors/Sources/SourcesForm/SourceFormFooter';
import ObjectFieldTemplate from '@/views/Connectors/Sources/rjsf/ObjectFieldTemplate';
import TitleFieldTemplate from '@/views/Connectors/Sources/rjsf/TitleFieldTemplate';
import FieldTemplate from '@/views/Connectors/Sources/rjsf/FieldTemplate';
import BaseInputTemplate from '@/views/Connectors/Sources/rjsf/BaseInputTemplate';
import DescriptionFieldTemplate from '@/views/Connectors/Sources/rjsf/DescriptionFieldTemplate';
import { FormProps } from '@rjsf/core';
import { RJSFSchema } from '@rjsf/utils';
import { uiSchemas } from '@/views/Connectors/Sources/SourcesForm/SourceConfigForm/SourceConfigForm';

const DestinationConfigForm = (): JSX.Element | null => {
  const { state, stepInfo, handleMoveForward } = useContext(SteppedFormContext);
  const { forms } = state;
  const selectedDestination = forms.find(({ stepKey }) => stepKey === 'destination');

  const destination = selectedDestination?.data?.destination as string;
  if (!destination) return null;

  const { data, isLoading } = useQuery({
    queryKey: ['connector_definition', destination],
    queryFn: () => getConnectorDefinition('destination', destination),
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

  const templateOverrides: FormProps<any, RJSFSchema, any>['templates'] = {
    ObjectFieldTemplate: ObjectFieldTemplate,
    TitleFieldTemplate: TitleFieldTemplate,
    FieldTemplate: FieldTemplate,
    BaseInputTemplate: BaseInputTemplate,
    DescriptionFieldTemplate: DescriptionFieldTemplate,
  };

  return (
    <Box width='100%' display='flex' justifyContent='center'>
      <ContentContainer>
        <Box backgroundColor='gray.300' padding='20px' borderRadius='8px' marginBottom='100px'>
          <Form
            schema={connectorSchema}
            validator={validator}
            onSubmit={({ formData }) => handleFormSubmit(formData)}
            templates={templateOverrides}
            uiSchema={
              connectorSchema.title ? uiSchemas[connectorSchema.title.toLowerCase()] : undefined
            }
          >
            <SourceFormFooter
              ctaName='Finish'
              ctaType='submit'
              isBackRequired
              isDocumentsSectionRequired
              isContinueCtaRequired
            />
          </Form>
        </Box>
      </ContentContainer>
    </Box>
  );
};

export default DestinationConfigForm;
