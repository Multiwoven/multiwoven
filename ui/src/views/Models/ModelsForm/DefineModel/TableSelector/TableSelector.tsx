import { Box, Button, Flex, HStack } from '@chakra-ui/react';
import ContentContainer from '@/components/ContentContainer';
import FormFooter from '@/components/FormFooter';
import ModelQueryResults from '../ModelQueryResults';
import { SteppedFormContext } from '@/components/SteppedForm/SteppedForm';
import { PrefillValue } from '../DefineSQL/types';
import { useContext, useEffect, useState } from 'react';
import { extractData } from '@/utils';
import { useQuery } from '@tanstack/react-query';
import { getCatalog } from '@/services/syncs';
import { useStore } from '@/stores';
import Loader from '@/components/Loader';
import ListTables from './ListTables';
import { getModelPreviewById, putModelById } from '@/services/models';
import useCustomToast from '@/hooks/useCustomToast';
import { CustomToastStatus } from '@/components/Toast/index';
import { TableDataType } from '@/components/Table/types';
import { ConvertModelPreviewToTableData } from '@/utils/ConvertToTableData';
import GenerateTable from '@/components/Table/Table';
import { UpdateModelPayload } from '@/views/Models/ViewModel/types';
import { useNavigate } from 'react-router-dom';
import { QueryType } from '@/views/Models/types';
import ViewSQLModal from './ViewSQLModal';
import SearchBar from '@/components/SearchBar/SearchBar';
import { useAPIErrorsToast, useErrorToast } from '@/hooks/useErrorToast';
import RefreshModelCatalog from '../RefreshModelCatalog';

const generateQuery = (table: string) => `SELECT * FROM ${table}`;

const TableSelector = ({
  hasPrefilledValues = false,
  prefillValues,
  isUpdateButtonVisible = false,
}: {
  hasPrefilledValues?: boolean;
  prefillValues?: PrefillValue;
  isUpdateButtonVisible: boolean;
}) => {
  const activeWorkspaceId = useStore((state) => state.workspaceId);
  const [selectedTableName, setSelectedTableName] = useState('');
  const [loadingPreviewData, setLoadingPreviewData] = useState(false);
  const [userQuery, setUserQuery] = useState('');
  const [tableData, setTableData] = useState<null | TableDataType>();

  const [searchTerm, setSearchTerm] = useState('');

  const navigate = useNavigate();

  const showToast = useCustomToast();
  const apiErrorsToast = useAPIErrorsToast();
  const errorToast = useErrorToast();

  const { state, stepInfo, handleMoveForward } = useContext(SteppedFormContext);

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

  const { data: modelDiscoverData, isLoading } = useQuery({
    queryKey: ['syncs', 'catalog', connector_id, activeWorkspaceId],
    queryFn: () => getCatalog(connector_id),
    enabled: !!connector_id && activeWorkspaceId > 0,
    refetchOnMount: false,
    refetchOnWindowFocus: false,
  });

  const streams = modelDiscoverData?.data?.attributes?.catalog?.streams;

  // Filtered streams based on search term
  const filteredStreams = streams?.filter((stream) =>
    stream?.name?.toLowerCase().includes(searchTerm.toLowerCase()),
  );

  const handleTableNameSelection = (tableName: string) => {
    const sql = generateQuery(tableName);

    setUserQuery(sql);
    setSelectedTableName(tableName);
  };

  async function handleModelUpdate() {
    const updatePayload: UpdateModelPayload = {
      model: {
        name: prefillValues?.model_name || '',
        description: prefillValues?.model_description || '',
        primary_key: prefillValues?.primary_key || '',
        connector_id: prefillValues?.connector_id || '',
        query: userQuery,
        query_type: prefillValues?.query_type || '',
      },
    };

    const modelUpdateResponse = await putModelById(prefillValues?.model_id || '', updatePayload);
    if (modelUpdateResponse.errors) {
      apiErrorsToast(modelUpdateResponse.errors);
    } else {
      showToast({
        title: 'Model updated successfully',
        status: CustomToastStatus.Success,
        duration: 3000,
        isClosable: true,
        position: 'bottom-right',
      });
      navigate('/define/models/' + prefillValues?.model_id || '');
    }
  }

  const getPreview = async () => {
    setLoadingPreviewData(true);

    try {
      const response = await getModelPreviewById(userQuery, connector_id?.toString());
      if (response.errors) {
        if (response.errors) {
          apiErrorsToast(response.errors);
        } else {
          errorToast('Error fetching preview data', true, null, true);
        }
        setLoadingPreviewData(false);
      } else {
        if (response.data && response.data.length > 0) {
          setTableData(ConvertModelPreviewToTableData(response.data));
          setLoadingPreviewData(false);
        } else {
          showToast({
            title: 'No data found',
            status: CustomToastStatus.Success,
            duration: 3000,
            isClosable: true,
            position: 'bottom-right',
          });
          setTableData(null);
          setLoadingPreviewData(false);
        }
      }
    } catch (error) {
      errorToast('Error fetching preview data', true, null, true);
      setLoadingPreviewData(false);
    }
  };

  const handleContinueClick = () => {
    if (stepInfo?.formKey) {
      const formData = {
        query: userQuery,
        id: connector_id,
        query_type: QueryType.TableSelector,
        columns: tableData?.columns,
      };
      handleMoveForward(stepInfo.formKey, formData);
    }
  };

  useEffect(() => {
    if (hasPrefilledValues && prefillValues) {
      // extracting table name from the query for table_selector method
      const tableName = prefillValues?.query?.split('FROM')?.[1]?.trim();

      // generate query
      const sql = generateQuery(tableName);

      setUserQuery(sql);
      setSelectedTableName(tableName);
    }
  }, []);

  if (isLoading) {
    return <Loader />;
  }

  return (
    <Box justifyContent='center' display='flex'>
      <ContentContainer>
        <Box display='flex' flexDirection='column'>
          <Box
            border='1px'
            borderColor='gray.400'
            w='full'
            minW='4xl'
            h='280px'
            rounded='xl'
            marginBottom='24px'
          >
            <Flex bgColor='gray.300' padding='12px 20px' roundedTop='xl'>
              <Flex flex={1} alignItems='center'>
                {connector_icon}
              </Flex>
              <Box flex={1}>
                <SearchBar
                  setSearchTerm={setSearchTerm}
                  placeholder='Search for tables'
                  borderColor='white'
                />
              </Box>
              <HStack spacing={3} flex={1} justifyContent='flex-end'>
                <RefreshModelCatalog source_id={connector_id} />
                <Button
                  variant='shell'
                  onClick={getPreview}
                  isLoading={loadingPreviewData}
                  minWidth='0'
                  width='auto'
                  fontSize='12px'
                  height='32px'
                  paddingX={3}
                  borderWidth={1}
                  borderStyle='solid'
                  borderColor='gray.500'
                  isDisabled={!selectedTableName}
                >
                  Preview Results
                </Button>
                <ViewSQLModal tableName={selectedTableName} userQuery={userQuery} />
              </HStack>
            </Flex>
            <Box p={3} w='100%' bgColor='gray.100'>
              <ListTables
                streams={filteredStreams}
                selectedTableName={selectedTableName}
                handleTableNameSelection={handleTableNameSelection}
              />
            </Box>
          </Box>
          {tableData ? (
            <Box w='full' h='fit' maxHeight='16rem'>
              <GenerateTable
                maxHeight='16rem'
                minWidth='4xl'
                data={tableData}
                size='sm'
                borderRadius='xl'
              />
            </Box>
          ) : (
            <ModelQueryResults />
          )}
        </Box>
      </ContentContainer>
      {isUpdateButtonVisible ? (
        <FormFooter
          ctaName='Save Changes'
          ctaType='button'
          isCtaDisabled={!tableData}
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
          isCtaDisabled={!tableData}
          onCtaClick={handleContinueClick}
        />
      )}
    </Box>
  );
};

export default TableSelector;
