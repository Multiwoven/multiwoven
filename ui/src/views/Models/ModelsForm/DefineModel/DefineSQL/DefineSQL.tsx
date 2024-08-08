import { Box, Button, Flex, HStack, Image, Spacer, VStack } from '@chakra-ui/react';

import StarsImage from '@/assets/images/stars.svg';

import Editor, { useMonaco } from '@monaco-editor/react';
import { useContext, useEffect, useRef, useState } from 'react';
import { getModelPreviewById, putModelById } from '@/services/models';
import { ConvertModelPreviewToTableData } from '@/utils/ConvertToTableData';
import GenerateTable from '@/components/Table/Table';
import { TableDataType } from '@/components/Table/types';
import { SteppedFormContext } from '@/components/SteppedForm/SteppedForm';
import { extractData } from '@/utils';
import { useNavigate } from 'react-router-dom';
import { DefineSQLProps } from './types';
import { UpdateModelPayload } from '@/views/Models/ViewModel/types';
import ContentContainer from '@/components/ContentContainer';
import FormFooter from '@/components/FormFooter';
import { CustomToastStatus } from '@/components/Toast/index';
import useCustomToast from '@/hooks/useCustomToast';
import { format } from 'sql-formatter';
import { autocompleteEntries } from './autocomplete';
import titleCase from '@/utils/TitleCase';
import ModelQueryResults from '../ModelQueryResults';

const DefineSQL = ({
  hasPrefilledValues = false,
  prefillValues,
  isUpdateButtonVisible = false,
}: DefineSQLProps): JSX.Element => {
  const [tableData, setTableData] = useState<null | TableDataType>();

  const { state, stepInfo, handleMoveForward } = useContext(SteppedFormContext);
  const [loading, setLoading] = useState(false);
  const [moveForward, canMoveForward] = useState(false);
  const [runQuery, canRunQuery] = useState(prefillValues ? true : false);
  const [userQuery, setUserQuery] = useState(prefillValues?.query || '');

  const showToast = useCustomToast();
  const navigate = useNavigate();
  const editorRef = useRef<any>(null);
  const monaco = useMonaco();

  let connector_id: string = '';
  let connector_icon: JSX.Element = <></>;

  if (!hasPrefilledValues) {
    const extracted = extractData(state.forms);
    const connector_data = extracted.find((data) => data?.id);
    connector_id = connector_data?.id || '';
    connector_icon = connector_data?.icon || <></>;
  } else {
    if (!prefillValues) return <></>;

    connector_id = prefillValues.connector_id.toString();
    connector_icon = prefillValues.connector_icon;
  }

  function handleEditorDidMount(editor: any) {
    editorRef.current = editor;
  }

  function handleContinueClick(
    query: string,
    connector_id: string | number,
    tableData: TableDataType | null | undefined,
  ) {
    if (stepInfo?.formKey) {
      const formData = {
        query: query,
        id: connector_id,
        query_type: 'raw_sql',
        columns: tableData?.columns,
      };
      handleMoveForward(stepInfo.formKey, formData);
    }
  }

  async function getPreview() {
    setLoading(true);
    const query = editorRef.current?.getValue() as string;
<<<<<<< HEAD
    const response = await getModelPreviewById(query, connector_id?.toString());
    if ('errors' in response) {
      response.errors?.forEach((error) => {
        showToast({
          duration: 5000,
          isClosable: true,
          position: 'bottom-right',
          colorScheme: 'red',
          status: CustomToastStatus.Warning,
          title: titleCase(error.detail),
        });
      });
      setLoading(false);
    } else {
      setTableData(ConvertModelPreviewToTableData(response as Field[]));
      canMoveForward(true);
=======
    try {
      const response = await getModelPreviewById(query, connector_id?.toString());
      if (response.errors) {
        if (response.errors) {
          apiErrorsToast(response.errors);
        } else {
          errorToast('Error fetching preview data', true, null, true);
        }
        setLoading(false);
      } else {
        if (response.data && response.data.length > 0) {
          setTableData(ConvertModelPreviewToTableData(response.data));
          setLoading(false);
        } else {
          showToast({
            title: 'No data found',
            status: CustomToastStatus.Success,
            duration: 3000,
            isClosable: true,
            position: 'bottom-right',
          });
          setTableData(null);
          setLoading(false);
        }
      }
    } catch (error) {
      errorToast('Error fetching preview data', true, null, true);
>>>>>>> fc23d7b2 (refactor(CE): changed model query response format (#367))
      setLoading(false);
    }
  }

  async function handleModelUpdate() {
    const query = editorRef.current?.getValue() as string;
    const updatePayload: UpdateModelPayload = {
      model: {
        name: prefillValues?.model_name || '',
        description: prefillValues?.model_description || '',
        primary_key: prefillValues?.primary_key || '',
        connector_id: prefillValues?.connector_id || '',
        query: query,
        query_type: prefillValues?.query_type || '',
      },
    };

    const modelUpdateResponse = await putModelById(prefillValues?.model_id || '', updatePayload);
    if (modelUpdateResponse.data) {
      showToast({
        title: 'Model updated successfully',
        status: CustomToastStatus.Success,
        duration: 3000,
        isClosable: true,
        position: 'bottom-right',
      });
      navigate('/define/models/' + prefillValues?.model_id || '');
    } else {
      modelUpdateResponse.errors?.forEach((error) => {
        showToast({
          duration: 5000,
          isClosable: true,
          position: 'bottom-right',
          colorScheme: 'red',
          status: CustomToastStatus.Warning,
          title: titleCase(error.detail),
        });
      });
    }
  }

  useEffect(() => {
    if (monaco) {
      const entryKindMap = {
        Keyword: monaco.languages.CompletionItemKind.Keyword,
        Snippet: monaco.languages.CompletionItemKind.Snippet,
        Function: monaco.languages.CompletionItemKind.Function,
        Class: monaco.languages.CompletionItemKind.Class,
      };

      const providerHandle = monaco.languages.registerCompletionItemProvider('mysql', {
        provideCompletionItems: (model, position) => {
          const word = model.getWordUntilPosition(position);
          const range = {
            startLineNumber: position.lineNumber,
            endLineNumber: position.lineNumber,
            startColumn: word.startColumn,
            endColumn: word.endColumn,
          };

          return {
            suggestions: autocompleteEntries.map((entry) => ({
              label: entry.label,
              kind: entryKindMap[entry.kind],
              insertText: entry.insertText,
              insertTextRules: monaco.languages.CompletionItemInsertTextRule.InsertAsSnippet,
              documentation: entry.documentation,
              range: range,
            })),
          };
        },
      });

      return () => {
        providerHandle.dispose();
      };
    }
  }, [monaco, autocompleteEntries]);

  return (
    <Box justifyContent='center' display='flex'>
      <ContentContainer applyPadding={isUpdateButtonVisible ? false : true}>
        <Box w='full' mx='auto'>
          <VStack>
            <Box
              border='1px'
              borderColor='gray.400'
              w='full'
              minW='4xl'
              minH='100%'
              h='xs'
              rounded='xl'
            >
              <Flex bgColor='gray.300' p={2} roundedTop='xl'>
                <Flex w='full' alignItems='center'>
                  {connector_icon}
                </Flex>
                <Spacer />
                <HStack spacing={3}>
                  <Button
                    variant='shell'
                    onClick={getPreview}
                    isLoading={loading}
                    isDisabled={!runQuery}
                    minWidth='0'
                    width='auto'
                    fontSize='12px'
                    height='32px'
                    paddingX={3}
                    borderWidth={1}
                    borderStyle='solid'
                    borderColor='gray.500'
                  >
                    Run Query
                  </Button>
                  <Button
                    variant='shell'
                    minWidth='0'
                    width='auto'
                    borderWidth={1}
                    borderStyle='solid'
                    borderColor='gray.500'
                    fontSize='12px'
                    height='32px'
                    paddingX={3}
                    onClick={() => setUserQuery(format(userQuery))}
                  >
                    <Image src={StarsImage} w={6} mr={2} /> Beautify
                  </Button>
                </HStack>
              </Flex>
              <Box p={3} w='100%' maxH='250px' bgColor='gray.100'>
                <Editor
                  width='100%'
                  height='240px'
                  language='mysql'
                  defaultLanguage='mysql'
                  defaultValue='Enter your query...'
                  value={userQuery}
                  saveViewState={true}
                  onMount={handleEditorDidMount}
                  onChange={(query) => {
                    canMoveForward(false);
                    canRunQuery(true);
                    setUserQuery(query as string);
                  }}
                  theme='light'
                  options={{
                    minimap: {
                      enabled: false,
                    },
                    formatOnType: true,
                    formatOnPaste: true,
                    autoIndent: 'full',
                    wordBasedSuggestions: 'currentDocument',
                    quickSuggestions: true,
                    tabCompletion: 'on',
                    contextmenu: true,
                    smoothScrolling: true,
                    scrollBeyondLastLine: false,
                  }}
                />
              </Box>
            </Box>

            {tableData ? (
              <Box w='full' h='fit' maxHeight='xs'>
                <GenerateTable
                  maxHeight='xs'
                  minWidth='4xl'
                  data={tableData}
                  size='sm'
                  borderRadius='xl'
                />
              </Box>
            ) : (
              <ModelQueryResults />
            )}
          </VStack>
        </Box>
      </ContentContainer>
      {isUpdateButtonVisible ? (
        <FormFooter
          ctaName='Save Changes'
          ctaType='button'
          isCtaDisabled={!moveForward}
          isAlignToContentContainer
          isBackRequired
          onCtaClick={handleModelUpdate}
          isContinueCtaRequired
          isDocumentsSectionRequired
        />
      ) : (
        <FormFooter
          ctaName='Continue'
          ctaType='button'
          isBackRequired
          isContinueCtaRequired
          isCtaDisabled={!moveForward}
          onCtaClick={() => {
            handleContinueClick(editorRef.current.getValue(), connector_id, tableData);
          }}
        />
      )}
    </Box>
  );
};

export default DefineSQL;
