import { useQuery } from '@tanstack/react-query';

import { SteppedFormContext } from '@/components/SteppedForm/SteppedForm';
import { getConnectorDefinition } from '@/services/connectors';
import { useContext } from 'react';
import { Box } from '@chakra-ui/react';

import FormFooter from '@/components/FormFooter';

import Loader from '@/components/Loader';
import { processFormData } from '@/views/Connectors/helpers';
import ContentContainer from '@/components/ContentContainer';
import { generateUiSchema } from '@/utils/generateUiSchema';
import JSONSchemaForm from '@/components/JSONSchemaForm';
import { useStore } from '@/stores';

const ConnectorConfigForm = ({ connectorType }: { connectorType: string }): JSX.Element | null => {
  const { state, stepInfo, handleMoveForward } = useContext(SteppedFormContext);
  const { forms } = state;
  const selectedConnector = forms.find(
    ({ stepKey }) => stepKey === (connectorType === 'source' ? 'datasource' : connectorType),
  );
  const connector = selectedConnector?.data?.[
    connectorType === 'source' ? 'datasource' : connectorType
  ] as string;
  const activeWorkspaceId = useStore((state) => state.workspaceId);

  if (!connector) return null;

  const { data, isLoading } = useQuery({
    queryKey: ['connector_definition', connector, activeWorkspaceId],
    queryFn: () => getConnectorDefinition(connectorType, connector),
    enabled: !!connector && activeWorkspaceId > 0,
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

  const generatedSchema = generateUiSchema(connectorSchema);

  return (
    <Box display='flex' justifyContent='center' marginBottom='80px'>
      <ContentContainer>
        <Box backgroundColor='gray.200' padding='24px' borderRadius='8px'>
          <JSONSchemaForm
            schema={connectorSchema}
            uiSchema={generatedSchema}
            onSubmit={(formData: FormData) => handleFormSubmit(formData)}
            connectorId={connector}
            connectorType={connectorType}
          >
            <FormFooter
              ctaName='Continue'
              ctaType='submit'
              isContinueCtaRequired
              isDocumentsSectionRequired
              isBackRequired
            />
          </JSONSchemaForm>
        </Box>
      </ContentContainer>
    </Box>
  );
};

export default ConnectorConfigForm;
