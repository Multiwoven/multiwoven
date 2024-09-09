import { useContext, useMemo } from 'react';
import { useQuery } from '@tanstack/react-query';
import { Alert, AlertDescription, AlertTitle, Box, Button } from '@chakra-ui/react';
import { SteppedFormContext } from '@/components/SteppedForm/SteppedForm';
import { getConnectionStatus } from '@/services/connectors';
import { processConnectorConfigData } from '@/views/Connectors/helpers';
import { ConnectorTypes, TestConnectionPayload } from '@/views/Connectors/types';
import FormFooter from '@/components/FormFooter';
import ContentContainer from '@/components/ContentContainer';
import { useStore } from '@/stores';
import ConnectorConnectionTestProgress from '@/views/Connectors/ConnectorConnectionTest/ConnectorConnectionTestProgress';

const CONNECT_TO_SOURCES_KEY = 'connectToSources';
const CONNECT_TO_DESTINATION_KEY = 'destinationConfig';

const ConnectorConnectionTest = ({
  connectorType,
}: {
  connectorType: ConnectorTypes;
}): JSX.Element | null => {
  const activeWorkspaceId = useStore((state) => state.workspaceId);
  const { state, stepInfo, handleMoveForward } = useContext(SteppedFormContext);
  const { forms } = state;

  const connectorKey = connectorType === 'source' ? 'datasource' : connectorType;
  const selectedConnector = forms.find(({ stepKey }) => stepKey === connectorKey)?.data?.[
    connectorKey
  ] as string;

  const configKey =
    connectorType === 'source' ? CONNECT_TO_SOURCES_KEY : CONNECT_TO_DESTINATION_KEY;
  const connectorConfigForm = forms.find(({ stepKey }) => stepKey === configKey);
  const connectorConfig = connectorConfigForm?.data?.[configKey];

  const processedConnectorConfig = useMemo(
    () => processConnectorConfigData(connectorConfig, selectedConnector, connectorType),
    [connectorConfig, selectedConnector, connectorType],
  );

  const {
    data: connectionResponse,
    refetch: retryConnectorConnection,
    isFetching,
  } = useQuery({
    queryKey: ['connector_definition', 'test-connection', connectorType, activeWorkspaceId],
    queryFn: () => getConnectionStatus(processedConnectorConfig as TestConnectionPayload),
    enabled: !!processedConnectorConfig && activeWorkspaceId > 0,
    refetchOnMount: true,
    refetchOnWindowFocus: false,
  });

  const isConnectionFailed = connectionResponse?.connection_status.status !== 'succeeded';

  const handleContinueClick = () => {
    handleMoveForward(stepInfo?.formKey as string, processedConnectorConfig);
  };

  return (
    <Box width='100%' display='flex' justifyContent='center'>
      <ContentContainer>
        <Box width='100%'>
          <Box padding='24px' backgroundColor='gray.300' borderRadius='8px' marginBottom='16px'>
            <ConnectorConnectionTestProgress
              connectionResponse={connectionResponse}
              isFetching={isFetching}
              connectorConfig={connectorConfig}
              selectedConnectorSource={selectedConnector}
            />
            {isConnectionFailed && (
              <Button
                borderColor='gray.500'
                isDisabled={isFetching}
                onClick={() => retryConnectorConnection()}
                minWidth={0}
                width='auto'
                borderStyle='solid'
                borderWidth='1px'
                backgroundColor='gray.200'
                color='black.500'
                fontSize='12px'
                _hover={{ bgColor: 'gray.300', color: 'black' }}
                height='32px'
              >
                Test Again
              </Button>
            )}
          </Box>
          {!isFetching && (
            <Alert
              status={isConnectionFailed ? 'error' : 'success'}
              borderRadius='8px'
              backgroundColor={isConnectionFailed ? 'error.100' : 'success.100'}
              paddingX='16px'
              paddingY='12px'
            >
              <Box>
                <AlertTitle fontSize='14px' fontWeight='semibold' letterSpacing='-0.14px'>
                  {isConnectionFailed
                    ? 'Could not open a connection to remote host'
                    : 'Connected successfully!'}
                </AlertTitle>
                <AlertDescription
                  color='black.200'
                  fontSize='12px'
                  fontWeight={400}
                  letterSpacing='-0.14px'
                >
                  {isConnectionFailed
                    ? connectionResponse?.connection_status.message
                    : `All tests passed. Continue to finish setting up your ${selectedConnector} ${connectorType}.`}
                </AlertDescription>
              </Box>
            </Alert>
          )}
        </Box>
        <FormFooter
          ctaName='Continue'
          onCtaClick={handleContinueClick}
          isContinueCtaRequired
          isBackRequired
          isDocumentsSectionRequired
          isCtaDisabled={isFetching}
        />
      </ContentContainer>
    </Box>
  );
};

export default ConnectorConnectionTest;
