import {
  getConnectorDefinition,
  getConnectorInfo,
} from "@/services/connectors";
import { useQuery } from "@tanstack/react-query";
import { useParams } from "react-router-dom";

import validator from "@rjsf/validator-ajv8";
import { Form } from "@rjsf/chakra-ui";
import { Box, Spinner } from "@chakra-ui/react";
import SourceFormFooter from "../SourcesForm/SourceFormFooter";
import TopBar from "@/components/TopBar";
import ContentContainer from "@/components/ContentContainer";
import { useRef } from "react";

const EditSource = (): JSX.Element => {
  const { sourceId } = useParams();
  const containerRef = useRef(null);
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
            onSubmit={({ formData }) => {}}
            formData={connectorInfo?.attributes?.configuration}
          >
            <SourceFormFooter
              ctaName="Continue"
              ctaType="submit"
              alignTo={containerRef}
            />
          </Form>
        </Box>
      </ContentContainer>
    </Box>
  );
};

export default EditSource;
