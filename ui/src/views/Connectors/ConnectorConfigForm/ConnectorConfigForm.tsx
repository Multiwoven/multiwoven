import { useQuery } from '@tanstack/react-query';

import { SteppedFormContext } from '@/components/SteppedForm/SteppedForm';
import { getConnectorDefinition } from '@/services/connectors';
import { useContext } from 'react';
import { Box } from '@chakra-ui/react';
import { useMemo } from 'react';

import FormFooter from '@/components/FormFooter';

import Loader from '@/components/Loader';
import { processFormData } from '@/views/Connectors/helpers';
import ContentContainer from '@/components/ContentContainer';
import { generateUiSchema } from '@/utils/generateUiSchema';
import JSONSchemaForm from '@/components/JSONSchemaForm';
import { useStore } from '@/stores';

const ConnectorConfigForm = ({ connectorType }: { connectorType: string }): JSX.Element | null => {
<<<<<<< HEAD
  const { state, stepInfo, handleMoveForward } = useContext(SteppedFormContext);
  const { forms } = state;
=======
  const {
    forms,
    stepInfo,
    handleMoveForward,
    saveConnectorFormData,
    connectorFormData = {},
  } = useSteppedForm();
  const activeWorkspaceId = useStore((state) => state.workspaceId);

  const stepKey = connectorType === 'source' ? 'connectToSources' : 'destinationConfig';

>>>>>>> cd20cdf6 (feat(CE): added connector formstate persistence (#1429))
  const selectedConnector = forms.find(
    ({ stepKey: sk }) => sk === (connectorType === 'source' ? 'datasource' : connectorType),
  );
  const connector = selectedConnector?.data?.[
    connectorType === 'source' ? 'datasource' : connectorType
  ] as string;

  const formData = useMemo(() => {
    if (!connectorFormData || !connector) return {};
    const persistedData = connectorFormData[connector]?.[stepKey];
    return (persistedData as Record<string, unknown>) || {};
  }, [connector, stepKey, connectorFormData]);

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
    saveConnectorFormData(connector, stepKey, processedFormData);
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
            formData={formData}
            onSubmit={(formData: FormData) => handleFormSubmit(formData)}
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
