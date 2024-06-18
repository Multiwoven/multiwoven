import { useQuery } from '@tanstack/react-query';

import { SteppedFormContext } from '@/components/SteppedForm/SteppedForm';
import { getConnectorDefinition } from '@/services/connectors';
import { useContext } from 'react';
import { Box } from '@chakra-ui/react';

import SourceFormFooter from '@/views/Connectors/Sources/SourcesForm/SourceFormFooter';

import Loader from '@/components/Loader';
import { processFormData } from '@/views/Connectors/helpers';
import ContentContainer from '@/components/ContentContainer';
import { generateUiSchema } from '@/utils/generateUiSchema';
import JSONSchemaForm from '@/components/JSONSchemaForm';
import { useStore } from '@/stores';

const SourceConfigForm = (): JSX.Element | null => {
  const { state, stepInfo, handleMoveForward } = useContext(SteppedFormContext);
  const { forms } = state;
  const selectedDataSource = forms.find(({ stepKey }) => stepKey === 'datasource');
  const datasource = selectedDataSource?.data?.datasource as string;
  const activeWorkspaceId = useStore((state) => state.workspaceId);

  if (!datasource) return null;

  const { data, isLoading } = useQuery({
    queryKey: ['connector_definition', datasource, activeWorkspaceId],
    queryFn: () => getConnectorDefinition('source', datasource),
    enabled: !!datasource && activeWorkspaceId > 0,
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
          >
            <SourceFormFooter
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

export default SourceConfigForm;
