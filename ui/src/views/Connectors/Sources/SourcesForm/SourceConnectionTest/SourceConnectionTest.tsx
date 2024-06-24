import { SteppedFormContext } from '@/components/SteppedForm/SteppedForm';
import { getConnectionStatus } from '@/services/connectors';
import { processConnectorConfigData } from '@/views/Connectors/helpers';
import { TestConnectionPayload } from '@/views/Connectors/types';
import { Alert, AlertDescription, AlertTitle, Box, Button } from '@chakra-ui/react';
import { useQuery } from '@tanstack/react-query';
import { useContext, useMemo } from 'react';
import SourceFormFooter from '../SourceFormFooter';
import ContentContainer from '@/components/ContentContainer';
import { useStore } from '@/stores';
import ConnectorConnectionTest from '@/views/Connectors/ConnectorConnectionTest/ConnectorConnectionTest';

const CONNECT_TO_SOURCES_KEY = 'connectToSources';

const SourceConnectionTest = (): JSX.Element | null => {
  const activeWorkspaceId = useStore((state) => state.workspaceId);

  const { state, stepInfo, handleMoveForward } = useContext(SteppedFormContext);
  const { forms } = state;

  const selectedDataSource = forms.find(({ stepKey }) => stepKey === 'datasource')?.data
    ?.datasource as string;

  const sourceConfigForm = forms.find(({ stepKey }) => stepKey === CONNECT_TO_SOURCES_KEY);
  const { data } = sourceConfigForm ?? {};
  const sourceConfig = data?.[CONNECT_TO_SOURCES_KEY];
  const processedSourceConfig = useMemo(
    () => processConnectorConfigData(sourceConfig, selectedDataSource, 'source'),
    [forms],
  );

  const {
    data: connectionResponse,
    refetch: retrySourceConnection,
    isFetching,
  } = useQuery({
    queryKey: ['connector_definition', 'test-connection', 'source', activeWorkspaceId],
    queryFn: () => getConnectionStatus(processedSourceConfig as TestConnectionPayload),
    enabled: !!processedSourceConfig && activeWorkspaceId > 0,
    refetchOnMount: true,
    refetchOnWindowFocus: false,
  });

  const isAnyFailed = connectionResponse?.connection_status.status !== 'succeeded';

  const handleOnContinueClick = () => {
    handleMoveForward(stepInfo?.formKey as string, processedSourceConfig);
  };

  return (
    <Box width='100%' display='flex' justifyContent='center'>
      <ContentContainer>
        <Box width='100%'>
          <Box padding='24px' backgroundColor='gray.300' borderRadius='8px' marginBottom='16px'>
            <ConnectorConnectionTest
              connectionResponse={connectionResponse}
              isFetching={isFetching}
              connectorConfig={sourceConfig}
              selectedConnectorSource={selectedDataSource}
            />

            {isAnyFailed && connectionResponse ? (
              <Button
                borderColor='gray.500'
                isDisabled={isFetching}
                onClick={() => retrySourceConnection()}
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
            ) : null}
          </Box>
          {!isFetching ? (
            <Alert
              status={isAnyFailed ? 'error' : 'success'}
              borderRadius='8px'
              backgroundColor={isAnyFailed ? 'error.100' : 'success.100'}
              paddingX='16px'
              paddingY='12px'
            >
              <Box>
                <AlertTitle fontSize='14px' fontWeight='semibold' letterSpacing='-0.14px'>
                  {isAnyFailed
                    ? 'Could not open a connection to remote host'
                    : 'Connected successfully!'}
                </AlertTitle>
                <AlertDescription
                  color='black.200'
                  fontSize='12px'
                  fontWeight={400}
                  letterSpacing='-0.14px'
                >
                  {isAnyFailed
                    ? connectionResponse?.connection_status.message
                    : `All tests passed. Continue to finish setting up your ${selectedDataSource} Source`}
                </AlertDescription>
              </Box>
            </Alert>
          ) : null}
        </Box>
        <SourceFormFooter
          ctaName='Continue'
          onCtaClick={handleOnContinueClick}
          isContinueCtaRequired
          isBackRequired
          isDocumentsSectionRequired
          isCtaDisabled={isFetching}
        />
      </ContentContainer>
    </Box>
  );
};

export default SourceConnectionTest;
