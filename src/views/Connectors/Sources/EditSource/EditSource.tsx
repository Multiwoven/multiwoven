import {
  getConnectionStatus,
  getConnectorDefinition,
  getConnectorInfo,
  updateConnector,
} from "@/services/connectors";
import { useMutation, useQuery } from "@tanstack/react-query";
import { useNavigate, useParams } from "react-router-dom";

import validator from "@rjsf/validator-ajv8";
import { Form } from "@rjsf/chakra-ui";
import { Box, Button, Spinner, useToast } from "@chakra-ui/react";
import SourceFormFooter from "../SourcesForm/SourceFormFooter";
import TopBar from "@/components/TopBar";
import ContentContainer from "@/components/ContentContainer";
import { useRef, useState } from "react";
import { CreateConnectorPayload, TestConnectionPayload } from "../../types";

const EditSource = (): JSX.Element => {
  const { sourceId } = useParams();
  const containerRef = useRef(null);
  const toast = useToast();
  const navigate = useNavigate();

  const [isTestRunning, setIsTestRunning] = useState<boolean>(false);
  const [testedFormData, setTestedFormData] = useState<unknown>(null);

  const { data: connectorInfoResponse, isLoading: isConnectorInfoLoading } =
    useQuery({
      queryKey: ["connectorInfo", sourceId],
      queryFn: () => getConnectorInfo(sourceId as string),
      refetchOnMount: true,
      refetchOnWindowFocus: false,
      enabled: !!sourceId,
    });

  const connectorInfo = connectorInfoResponse?.data;
  const connectorName = connectorInfo?.attributes?.connector_name;

  const {
    data: connectorDefinitionResponse,
    isLoading: isConnectorDefinitionLoading,
  } = useQuery({
    queryKey: ["connector_definition", connectorName],
    queryFn: () => getConnectorDefinition("source", connectorName as string),
    refetchOnMount: false,
    refetchOnWindowFocus: false,
    enabled: !!connectorName,
  });

  const handleOnSaveChanges = async () => {
    if (!connectorInfo?.attributes) return;
    const payload: CreateConnectorPayload = {
      connector: {
        configuration: testedFormData,
        name: connectorInfo?.attributes?.name,
        connector_type: "source",
        connector_name: connectorInfo?.attributes?.connector_name,
        description: connectorInfo?.attributes?.description ?? "",
      },
    };
    return updateConnector(payload, sourceId as string);
  };

  const { isPending: isEditLoading, mutate } = useMutation({
    mutationFn: handleOnSaveChanges,
    onSettled: () => {
      toast({
        status: "success",
        title: "Success!!",
        description: "Connector Updated",
        position: "bottom-right",
        isClosable: true,
      });
      navigate("/setup/sources");
    },
    onError: () => {
      toast({
        status: "error",
        title: "Error!!",
        description: "Something went wrong",
        position: "bottom-right",
        isClosable: true,
      });
    },
  });

  const connectorSchema = connectorDefinitionResponse?.data?.connector_spec;

  const handleOnTestClick = async (formData: unknown) => {
    setIsTestRunning(true);

    if (!connectorInfo?.attributes) return;

    try {
      const payload: TestConnectionPayload = {
        connection_spec: formData,
        name: connectorInfo?.attributes?.name,
        type: "source",
      };

      const testingConnectionResponse = await getConnectionStatus(payload);
      const isConnectionSucceeded =
        testingConnectionResponse?.connection_status?.status === "succeeded";

      if (isConnectionSucceeded) {
        toast({
          status: "success",
          title: "Connection successful",
          position: "bottom-right",
          isClosable: true,
        });
      }

      toast({
        status: "error",
        title: "Connection failed",
        description: testingConnectionResponse?.connection_status?.message,
        position: "bottom-right",
        isClosable: true,
      });
    } catch (e) {
      toast({
        status: "error",
        title: "Connection failed",
        description: "Something went wrong!",
        position: "bottom-right",
        isClosable: true,
      });
    } finally {
      setIsTestRunning(false);
      setTestedFormData(formData);
    }
  };

  if (isConnectorInfoLoading || isConnectorDefinitionLoading)
    return (
      <Box
        height="30vh"
        width="100%"
        display="flex"
        alignItems="center"
        justifyContent="center"
      >
        <Spinner size="lg" />
      </Box>
    );

  return (
    <Box width="100%" display="flex" justifyContent="center">
      <ContentContainer containerRef={containerRef}>
        <Box marginBottom="20px">
          <TopBar name={"Sources"} isCtaVisible={false} />
        </Box>

        <Box
          backgroundColor="#fff"
          padding="24px"
          borderWidth="thin"
          borderRadius="8px"
          marginBottom="100px"
        >
          <Form
            schema={connectorSchema?.connection_specification}
            validator={validator}
            onSubmit={({ formData }) => handleOnTestClick(formData)}
            formData={connectorInfo?.attributes?.configuration}
          >
            <SourceFormFooter
              ctaName="Save Changes"
              ctaType="button"
              alignTo={containerRef}
              isCtaDisabled={!testedFormData}
              onCtaClick={mutate}
              isCtaLoading={isEditLoading}
              extra={
                <Button
                  size="lg"
                  marginRight="10px"
                  type="submit"
                  isLoading={isTestRunning}
                >
                  Test Connection
                </Button>
              }
            />
          </Form>
        </Box>
      </ContentContainer>
    </Box>
  );
};

export default EditSource;
