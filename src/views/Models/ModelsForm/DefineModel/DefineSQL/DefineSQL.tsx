import {
  Box,
  Button,
  Flex,
  HStack,
  Image,
  Spacer,
  Text,
  VStack,
  useToast,
} from "@chakra-ui/react";

import StarsImage from "@/assets/images/stars.svg";
import EmptyQueryPreviewImage from "@/assets/images/EmptyQueryPreview.png";

import Editor from "@monaco-editor/react";
import { useContext, useRef, useState } from "react";
import { Field, getModelPreviewById, putModelById } from "@/services/models";
import { ConvertModelPreviewToTableData } from "@/utils/ConvertToTableData";
import GenerateTable from "@/components/Table/Table";
import { TableDataType } from "@/components/Table/types";
import { SteppedFormContext } from "@/components/SteppedForm/SteppedForm";
import { extractData } from "@/utils";
import ModelFooter from "../../ModelFooter";
import { useNavigate } from "react-router-dom";
import { DefineSQLProps } from "./types";
import { UpdateModelPayload } from "@/views/Models/ViewModel/types";
import ContentContainer from "@/components/ContentContainer";

const DefineSQL = ({
  hasPrefilledValues = false,
  prefillValues,
  isFooterVisible = true,
  isUpdateButtonVisible = false,
  isAlignToContentContainer = false,
}: DefineSQLProps): JSX.Element => {
  const [tableData, setTableData] = useState<null | TableDataType>();

  const { state, stepInfo, handleMoveForward } = useContext(SteppedFormContext);
  const [loading, setLoading] = useState(false);
  const [moveForward, canMoveForward] = useState(false);
  const [runQuery, canRunQuery] = useState(prefillValues ? true : false);

  let connector_id: string = "";
  let connector_icon: JSX.Element = <></>;
  let user_query: string = "";

  if (!hasPrefilledValues) {
    const extracted = extractData(state.forms);
    const connector_data = extracted.find((data) => data?.id);
    connector_id = connector_data?.id || "";
    connector_icon = connector_data?.icon || <></>;
  } else {
    if (!prefillValues) return <></>;

    connector_id = prefillValues.connector_id.toString();
    connector_icon = prefillValues.connector_icon;
    user_query = prefillValues.query;
  }

  const toast = useToast();
  const navigate = useNavigate();
  const editorRef = useRef(null);

  function handleEditorDidMount(editor: any) {
    editorRef.current = editor;
  }

  function handleContinueClick(
    query: string,
    connector_id: string | number,
    tableData: TableDataType | null | undefined
  ) {
    if (stepInfo?.formKey) {
      const formData = {
        query: query,
        id: connector_id,
        query_type: "raw_sql",
        columns: tableData?.columns,
      };
      handleMoveForward(stepInfo.formKey, formData);
    }
  }

  async function getPreview() {
    setLoading(true);
    const query = (editorRef?.current as any)?.getValue() as string;
    const response = await getModelPreviewById(query, connector_id?.toString());
    if ("data" in response && response.data.errors) {
      response.data.errors.forEach(
        (error: { title: string; detail: string }) => {
          toast({
            title: "An Error Occurred",
            description:
              error.detail || "Please check your query and try again",
            status: "error",
            duration: 9000,
            isClosable: true,
            position: "bottom-right",
          });
        }
      );
    } else {
      setTableData(ConvertModelPreviewToTableData(response as Field[]));
      canMoveForward(true);
    }

    setLoading(false);
  }

  async function handleModelUpdate() {
    const query = (editorRef?.current as any)?.getValue() as string;
    const updatePayload: UpdateModelPayload = {
      model: {
        name: prefillValues?.model_name || "",
        description: prefillValues?.model_description || "",
        primary_key: prefillValues?.primary_key || "",
        connector_id: prefillValues?.connector_id || "",
        query: query,
        query_type: prefillValues?.query_type || "",
      },
    };

    const modelUpdateResponse = await putModelById(
      prefillValues?.model_id || "",
      updatePayload
    );
    if (modelUpdateResponse.data) {
      toast({
        title: "Model updated successfully",
        status: "success",
        duration: 3000,
        isClosable: true,
        position: "bottom-right",
      });
      navigate("/define/models/" + prefillValues?.model_id || "");
    }
  }

  return (
    <Box justifyContent="center" display="flex">
      <ContentContainer>
        <Box w="full" mx="auto">
          <VStack>
            <Box
              border="1px"
              borderColor="gray.400"
              w="full"
              minW="4xl"
              minH="100%"
              h="xs"
              rounded="xl"
            >
              <Flex bgColor="gray.300" p={2} roundedTop="xl">
                <Flex w="full" alignItems="center">
                  {connector_icon}
                </Flex>
                <Spacer />
                <HStack spacing={3}>
                  <Button
                    variant="shell"
                    onClick={getPreview}
                    isLoading={loading}
                    isDisabled={!runQuery}
                  >
                    {" "}
                    Run Query{" "}
                  </Button>
                  <Button variant="shell">
                    <Image src={StarsImage} w={6} mr={2} /> Beautify
                  </Button>
                </HStack>
              </Flex>
              <Box p={3} w="100%" maxH="250px" bgColor="gray.100">
                <Editor
                  width="100%"
                  height="240px"
                  language="mysql"
                  defaultLanguage="mysql"
                  defaultValue="Enter your query..."
                  value={user_query}
                  saveViewState={true}
                  onMount={handleEditorDidMount}
                  onChange={() => {
                    canMoveForward(false);
                    canRunQuery(true);
                  }}
                  theme="light"
                  options={{
                    minimap: {
                      enabled: false,
                    },
                    formatOnType: true,
                    formatOnPaste: true,
                    autoIndent: "full",
                    wordBasedSuggestions: true,
                    quickSuggestions: true,
                    tabCompletion: "on",
                    contextmenu: true,
                    smoothScrolling: true,
                    scrollBeyondLastLine: false,
                  }}
                />
              </Box>
            </Box>

            {tableData ? (
              <Box w="full" h="fit" maxHeight="xs">
                <GenerateTable
                  maxHeight="xs"
                  minWidth="4xl"
                  data={tableData}
                  size="sm"
                  borderRadius="xl"
                />
              </Box>
            ) : (
              <Box
                border="1px"
                borderColor="gray.400"
                w="full"
                minW="4xl"
                minH="100%"
                h="2xs"
                rounded="xl"
                p={1}
                alignItems="center"
                justifyContent="center"
              >
                <VStack mx="auto" mt={12}>
                  <Image src={EmptyQueryPreviewImage} h="20" />
                  <Text fontSize="md" fontWeight="bold">
                    Ready to test your query?
                  </Text>
                  <Text fontSize="sm">Run your query to preview the rows</Text>
                </VStack>
              </Box>
            )}
          </VStack>
        </Box>
        {isFooterVisible ? (
          <ModelFooter
            isAlignToContentContainer={isAlignToContentContainer}
            buttons={[
              {
                name: "Back",
                variant: "ghost",
                color: "black",
                onClick: () => navigate(-1),
              },
              {
                name: "Continue",
                isDisabled: !moveForward,
                variant: "solid",
                onClick: () =>
                  handleContinueClick(
                    (editorRef?.current as any).getValue(),
                    connector_id,
                    tableData
                  ),
              },
            ]}
          />
        ) : (
          <></>
        )}
        {isUpdateButtonVisible ? (
          <ModelFooter
            isAlignToContentContainer={isAlignToContentContainer}
            buttons={[
              {
                name: "Cancel",
                variant: "ghost",
                color: "black",
                onClick: () => navigate(-1),
              },
              {
                name: "Save Changes",
                isDisabled: !moveForward,
                variant: "solid",
                onClick: () => handleModelUpdate(),
              },
            ]}
          />
        ) : (
          <></>
        )}
      </ContentContainer>
    </Box>
  );
};

export default DefineSQL;
