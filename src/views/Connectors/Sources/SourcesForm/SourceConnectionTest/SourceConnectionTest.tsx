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
import SourceFormFooter from "../SourceFormFooter";
import { CONNECTION_STATUS } from "@/views/Connectors/constant";
import { FiAlertOctagon, FiCheck } from "react-icons/fi";
import ContentContainer from "@/components/ContentContainer";

const CONNECT_TO_SOURCES_KEY = "connectToSources";

const STATUS_COLOR_MAP = {
  success: "green.400",
  failed: "red.400",
  loading: "gray.800",
};

const SourceConnectionTest = (): JSX.Element | null => {
  const { state, stepInfo, handleMoveForward } = useContext(SteppedFormContext);
  const { forms } = state;

  const selectedDataSource = forms.find(
    ({ stepKey }) => stepKey === "datasource"
  )?.data?.datasource as string;

  const sourceConfigForm = forms.find(
    ({ stepKey }) => stepKey === CONNECT_TO_SOURCES_KEY
  );
  const { data } = sourceConfigForm ?? {};
  const sourceConfig = data?.[CONNECT_TO_SOURCES_KEY];
  const processedSourceConfig = useMemo(
    () =>
      processConnectorConfigData(sourceConfig, selectedDataSource, "source"),
    [forms]
  );

  const {
    data: connectionResponse,
    refetch: retrySourceConnection,
    isFetching,
  } = useQuery({
    queryKey: ["connector_definition", "test-connection", "source"],
    queryFn: () =>
      getConnectionStatus(processedSourceConfig as TestConnectionPayload),
    enabled: !!processedSourceConfig,
    refetchOnMount: true,
    refetchOnWindowFocus: false,
  });

  const isAnyFailed =
    connectionResponse?.connection_status.status !== "succeeded";

  const handleOnContinueClick = () => {
    handleMoveForward(stepInfo?.formKey as string, processedSourceConfig);
  };

  return (
    <Box display="flex" justifyContent="center">
      <ContentContainer>
        <Box
          backgroundColor="gray.200"
          borderRadius="8px"
          padding="24px"
          marginBottom="25px"
        >
          {CONNECTION_STATUS.map(({ status }) => {
            const statusMetaInfo = status({
              data: connectionResponse,
              isLoading: isFetching,
              configFormData: sourceConfig,
              datasource: selectedDataSource,
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
                  <Text fontWeight="600"  color={STATUS_COLOR_MAP?.[statusMetaInfo.status]}>{statusMetaInfo.text}</Text>
                </Box>
              </Box>
            );
          })}
          {isAnyFailed && connectionResponse ? (
            <Button
              variant="shell"
              borderColor="gray.500"
              isDisabled={isFetching}
              onClick={() => retrySourceConnection()}
              color="black.500"
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
                  : `All tests passed. Continue to finish setting up your ${selectedDataSource} Source`}
              </AlertDescription>
            </Box>
          </Alert>
        ) : null}
     </ContentContainer>
      <SourceFormFooter
        ctaName="Continue"
        onCtaClick={handleOnContinueClick}
        isBackRequired
      />
    </Box>
  );
};

export default SourceConnectionTest;
