import { SteppedFormContext } from "@/components/SteppedForm/SteppedForm";
import { getConnectionStatus } from "@/services/connectors";
import { processConnectorConfigData } from "@/views/Connectors/helpers";
import { TestConnectionPayload } from "@/views/Connectors/types";
import {
  Alert,
  AlertDescription,
  AlertTitle,
  Box,
  Button,
  Icon,
  Spinner,
  Text,
} from "@chakra-ui/react";
import { useQuery } from "@tanstack/react-query";
import { useContext, useMemo } from "react";
import { CONNECTION_STATUS } from "@/views/Connectors/constant";
import { FiAlertOctagon, FiCheck } from "react-icons/fi";
import { useUiConfig } from "@/utils/hooks";
import SourceFormFooter from "@/views/Connectors/Sources/SourcesForm/SourceFormFooter";

const CONNECT_TO_DESTINATION_KEY = "destinationConfig";

const STATUS_COLOR_MAP = {
  success: "green.400",
  failed: "red.400",
  loading: "gray.800",
};

const DestinationConnectionTest = (): JSX.Element | null => {
  const { state, stepInfo, handleMoveForward } = useContext(SteppedFormContext);
  const { forms } = state;
  const { maxContentWidth } = useUiConfig();

  const selectedDestination = forms.find(
    ({ stepKey }) => stepKey === "destination"
  )?.data?.destination as string;

  const destinationConfigForm = forms.find(
    ({ stepKey }) => stepKey === CONNECT_TO_DESTINATION_KEY
  );

  const { data } = destinationConfigForm ?? {};
  const destinationConfig = data?.[CONNECT_TO_DESTINATION_KEY];
  const processedDestinationConfig = useMemo(
    () =>
      processConnectorConfigData(
        destinationConfig,
        selectedDestination,
        "destination"
      ),
    [forms]
  );

  const {
    data: connectionResponse,
    refetch: retryDestinationConnection,
    isFetching,
  } = useQuery({
    queryKey: ["connector_definition", "test-connection", "destination"],
    queryFn: () =>
      getConnectionStatus(processedDestinationConfig as TestConnectionPayload),
    enabled: !!processedDestinationConfig,
    refetchOnMount: true,
    refetchOnWindowFocus: false,
  });

  const isAnyFailed =
    connectionResponse?.connection_status.status !== "succeeded";

  const handleOnContinueClick = () => {
    handleMoveForward(stepInfo?.formKey as string, processedDestinationConfig);
  };

  return (
    <Box display="flex" justifyContent="center">
      <Box maxWidth={maxContentWidth} width="100%">
        <Box
          padding="24px"
          backgroundColor="gray.100"
          borderRadius="8px"
          marginBottom="20px"
        >
          {CONNECTION_STATUS.map(({ status }) => {
            const statusMetaInfo = status({
              data: connectionResponse,
              isLoading: isFetching,
              configFormData: destinationConfig,
              datasource: selectedDestination,
            });

            return (
              <Box
                key={statusMetaInfo.text}
                display="flex"
                marginBottom="20px"
                alignItems="center"
                height="30px"
              >
                <Box>
                  {statusMetaInfo.status === "loading" ? <Spinner /> : null}
                  {statusMetaInfo.status === "success" ? (
                    <Box
                      display="flex"
                      alignItems="center"
                      justifyContent="center"
                      backgroundColor={STATUS_COLOR_MAP.success}
                      padding="5px"
                      borderRadius="50%"
                    >
                      <Icon as={FiCheck} boxSize={4} color="gray.100" />
                    </Box>
                  ) : null}

                  {statusMetaInfo.status === "failed" ? (
                    <Box
                      display="flex"
                      alignItems="center"
                      justifyContent="center"
                      backgroundColor={STATUS_COLOR_MAP.failed}
                      padding="5px"
                      borderRadius="50%"
                    >
                      <Icon as={FiAlertOctagon} boxSize={4} color="gray.100" />
                    </Box>
                  ) : null}
                </Box>
                <Box marginLeft="10px">
                  <Text fontWeight="600">{statusMetaInfo.text}</Text>
                </Box>
              </Box>
            );
          })}
          {isAnyFailed && connectionResponse ? (
            <Button
              variant="outline"
              borderColor="gray.500"
              isDisabled={isFetching}
              onClick={() => retryDestinationConnection()}
            >
              Test Again
            </Button>
          ) : null}
        </Box>
        {!isFetching ? (
          <Alert status={isAnyFailed ? "error" : "success"} borderRadius="8px">
            <Box>
              <AlertTitle>
                {isAnyFailed
                  ? "Could not open a connection to remote host"
                  : "Connected successfully!"}
              </AlertTitle>
              <AlertDescription>
                {isAnyFailed
                  ? connectionResponse?.connection_status.message
                  : `All tests passed. Continue to finish setting up your ${selectedDestination} source`}
              </AlertDescription>
            </Box>
          </Alert>
        ) : null}
      </Box>
      <SourceFormFooter ctaName="Continue" onCtaClick={handleOnContinueClick} />
    </Box>
  );
};

export default DestinationConnectionTest;
