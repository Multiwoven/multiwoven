import { SteppedFormContext } from '@/components/SteppedForm/SteppedForm';
import { getConnectionStatus } from '@/services/connectors';
import { processConnectorConfigData } from '@/views/Connectors/helpers';
import { TestConnectionPayload } from '@/views/Connectors/types';
import { Alert, AlertDescription, AlertTitle, Box, Button } from '@chakra-ui/react';
import { useQuery } from '@tanstack/react-query';
import { useContext, useMemo } from 'react';
import { useUiConfig } from '@/utils/hooks';
import SourceFormFooter from '@/views/Connectors/Sources/SourcesForm/SourceFormFooter';
import ContentContainer from '@/components/ContentContainer';
import { useStore } from '@/stores';
import ConnectorConnectionTest from '@/views/Connectors/ConnectorConnectionTest/ConnectorConnectionTest';

const CONNECT_TO_DESTINATION_KEY = 'destinationConfig';

const DestinationConnectionTest = (): JSX.Element | null => {
  const { state, stepInfo, handleMoveForward } = useContext(SteppedFormContext);
  const { forms } = state;
  const { maxContentWidth } = useUiConfig();

  let selectedDestination = forms.find(({ stepKey }) => stepKey === 'destination')?.data
    ?.destination as string;

  const destinationConfigForm = forms.find(({ stepKey }) => stepKey === CONNECT_TO_DESTINATION_KEY);

  const { data } = destinationConfigForm ?? {};
  const destinationConfig = data?.[CONNECT_TO_DESTINATION_KEY];
  const processedDestinationConfig = useMemo(
    () => processConnectorConfigData(destinationConfig, selectedDestination, 'destination'),
    [forms],
  );

  const activeWorkspaceId = useStore((state) => state.workspaceId);

  if (+activeWorkspaceId === 18 && selectedDestination.toLowerCase() === 'postgresql') {
    selectedDestination = 'AIS Datastore';
  }

  const {
    data: connectionResponse,
    refetch: retryDestinationConnection,
    isFetching,
  } = useQuery({
    queryKey: ['connector_definition', 'test-connection', 'destination', activeWorkspaceId],
    queryFn: () => getConnectionStatus(processedDestinationConfig as TestConnectionPayload),
    enabled: !!processedDestinationConfig && activeWorkspaceId > 0,
    refetchOnMount: true,
    refetchOnWindowFocus: false,
  });

  const isAnyFailed = connectionResponse?.connection_status?.status !== 'succeeded';

  const handleOnContinueClick = () => {
    handleMoveForward(stepInfo?.formKey as string, processedDestinationConfig);
  };

  return (
    <Box width='100%' display='flex' justifyContent='center'>
      <ContentContainer>
        <Box maxWidth={maxContentWidth} width='100%'>
          <Box padding='24px' backgroundColor='gray.300' borderRadius='8px' marginBottom='16px'>
            <ConnectorConnectionTest
              connectionResponse={connectionResponse}
              isFetching={isFetching}
              connectorConfig={destinationConfig}
              selectedConnectorSource={selectedDestination}
            />

            {isAnyFailed && connectionResponse ? (
              <Button
                borderColor='gray.500'
                isDisabled={isFetching}
                onClick={() => retryDestinationConnection()}
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
                    ? connectionResponse?.connection_status?.message
                    : `All tests passed. Continue to finish setting up your ${selectedDestination} Destination`}
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

export default DestinationConnectionTest;
