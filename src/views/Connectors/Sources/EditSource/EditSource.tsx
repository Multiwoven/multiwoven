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
import { useEffect, useState } from "react";
import { CreateConnectorPayload, TestConnectionPayload } from "../../types";
import { RJSFSchema } from "@rjsf/utils";

const EditSource = (): JSX.Element => {
  const { sourceId } = useParams();
  const toast = useToast();
  const navigate = useNavigate();
  const [formData, setFormData] = useState<unknown>(null);

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

  const connectorSchema = connectorDefinitionResponse?.data?.connector_spec;

  useEffect(() => {
    setFormData(connectorInfo?.attributes?.configuration);
  }, [connectorDefinitionResponse]);

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

        return;
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
      <ContentContainer>
        <Box marginBottom="20px">
          <TopBar name={"Sources"} isCtaVisible={false} />
        </Box>

        <Box
          backgroundColor="gray.200"
          padding="24px"
          borderWidth="thin"
          borderRadius="8px"
          marginBottom="100px"
          border='1px'
          borderColor='gray.400'
        >
          <Form
            schema={connectorSchema?.connection_specification as RJSFSchema}
            validator={validator}
            formData={formData}
            onSubmit={({ formData }) => handleOnTestClick(formData)}
            onChange={({ formData }) => setFormData(formData)}
          >
            <SourceFormFooter
              ctaName="Save Changes"
              ctaType="button"
              isCtaDisabled={!testedFormData}
              onCtaClick={mutate}
              isCtaLoading={isEditLoading}
              isAlignToContentContainer
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
