import {
  Box,
  Heading,
  Input,
  Text,
  Textarea,
  useToast,
} from "@chakra-ui/react";
import { useFormik } from "formik";
import { useContext, useState } from "react";
import { SteppedFormContext } from "@/components/SteppedForm/SteppedForm";
import {
  CreateConnectorPayload,
  TestConnectionPayload,
} from "@/views/Connectors/types";
import { useNavigate } from "react-router-dom";
import { createNewConnector } from "@/services/connectors";
import { useQueryClient } from "@tanstack/react-query";
import { DESTINATIONS_LIST_QUERY_KEY } from "@/views/Connectors/constant";
import { useUiConfig } from "@/utils/hooks";
import SourceFormFooter from "@/views/Connectors/Sources/SourcesForm/SourceFormFooter";

const finalDestinationConfigFormKey = "testDestination";

const DestinationFinalizeForm = (): JSX.Element | null => {
  const [isLoading, setIsLoading] = useState<boolean>(false);
  const { maxContentWidth } = useUiConfig();
  const { state } = useContext(SteppedFormContext);
  const { forms } = state;
  const toast = useToast();
  const navigate = useNavigate();
  const queryClient = useQueryClient();
  const finalDestinationConfigForm = forms.find(
    ({ stepKey }) => stepKey === finalDestinationConfigFormKey
  )?.data?.[finalDestinationConfigFormKey] as TestConnectionPayload | undefined;

  if (!finalDestinationConfigForm) return null;

  const formik = useFormik({
    initialValues: {
      connector_name: finalDestinationConfigForm.name,
      description: "",
    },
    onSubmit: async (formData) => {
      setIsLoading(true);
      try {
        const payload: CreateConnectorPayload = {
          connector: {
            configuration: finalDestinationConfigForm.connection_spec,
            name: formData.connector_name,
            connector_type: "destination",
            connector_name: finalDestinationConfigForm.name,
            description: formData.description,
          },
        };

        const createConnectorResponse = await createNewConnector(payload);
        if (createConnectorResponse?.data) {
          queryClient.removeQueries({
            queryKey: DESTINATIONS_LIST_QUERY_KEY,
          });

          toast({
            status: "success",
            title: "Success!!",
            description: "Destination created successfully!",
            position: "bottom-right",
          });
          navigate("/setup/destinations");
        } else {
          throw new Error();
        }
      } catch {
        toast({
          status: "error",
          title: "An error occurred.",
          description: "Something went wrong while creating the Destination.",
          position: "bottom-right",
          isClosable: true,
        });
      } finally {
        setIsLoading(false);
      }
    },
  });

  return (
    <Box display="flex" justifyContent="center">
      <Box maxWidth={maxContentWidth} width="100%">
        <form onSubmit={formik.handleSubmit}>
          <Box padding="24px" backgroundColor="gray.100" borderRadius="8px">
            <Heading size="md" fontWeight="600" marginBottom="24px">
              Finalize settings for this Destination
            </Heading>
            <Box>
              <Text marginBottom="8px" fontWeight="600">
                Destination Name
              </Text>
              <Input
                name="connector_name"
                type="text"
                placeholder="Enter Destination name"
                background="gray.100"
                marginBottom="24px"
                onChange={formik.handleChange}
                value={formik.values.connector_name}
                required
              />
              <Box display="flex">
                <Text marginBottom="8px" fontWeight="600">
                  Description
                </Text>{" "}
                <Text>(Optional)</Text>
              </Box>
              <Textarea
                name="description"
                placeholder="Enter a description"
                background="gray.100"
                resize="none"
                onChange={formik.handleChange}
                value={formik.values.description}
              />
            </Box>
          </Box>
          <SourceFormFooter
            ctaName="Finish"
            ctaType="submit"
            isCtaLoading={isLoading}
          />
        </form>
      </Box>
    </Box>
  );
};

export default DestinationFinalizeForm;
