import { SteppedFormContext } from '@/components/SteppedForm/SteppedForm';
import { getConnectorDefinition } from '@/services/connectors';
import { Box } from '@chakra-ui/react';
import { useQuery } from '@tanstack/react-query';
import { useContext } from 'react';

import Loader from '@/components/Loader';
import ContentContainer from '@/components/ContentContainer';
import SourceFormFooter from '@/views/Connectors/Sources/SourcesForm/SourceFormFooter';
import JSONSchemaForm from '@/components/JSONSchemaForm';
import { generateUiSchema } from '@/utils/generateUiSchema';
import { useStore } from '@/stores';

const DestinationConfigForm = (): JSX.Element | null => {
  const { state, stepInfo, handleMoveForward } = useContext(SteppedFormContext);
  const { forms } = state;
  const selectedDestination = forms.find(({ stepKey }) => stepKey === 'destination');
  const activeWorkspaceId = useStore((state) => state.workspaceId);

  const destination = selectedDestination?.data?.destination as string;
  if (!destination) return null;

  const { data, isLoading } = useQuery({
    queryKey: ['connector_definition', destination, activeWorkspaceId],
    queryFn: () => getConnectorDefinition('destination', destination),
    enabled: !!destination && activeWorkspaceId > 0,
    refetchOnMount: false,
    refetchOnWindowFocus: false,
  });

  if (isLoading) return <Loader />;

  const connectorSchema = data?.data?.connector_spec?.connection_specification;
  if (!connectorSchema) return null;

  const handleFormSubmit = async (formData: FormData) => {
    handleMoveForward(stepInfo?.formKey as string, formData);
  };

  const generatedSchema = generateUiSchema(connectorSchema);

  return (
    <Box width='100%' display='flex' justifyContent='center'>
      <ContentContainer>
        <Box backgroundColor='gray.300' padding='20px' borderRadius='8px' marginBottom='100px'>
          <JSONSchemaForm
            schema={connectorSchema}
            uiSchema={generatedSchema}
            onSubmit={(formData: FormData) => handleFormSubmit(formData)}
          >
            <SourceFormFooter
              ctaName='Finish'
              ctaType='submit'
              isBackRequired
              isDocumentsSectionRequired
              isContinueCtaRequired
            />
          </JSONSchemaForm>
        </Box>
      </ContentContainer>
    </Box>
  );
};

export default DestinationConfigForm;
