import { PrefillValue } from '../ModelsForm/DefineModel/DefineSQL/types';
import TopBar from '@/components/TopBar/TopBar';
import { getModelById, putModelById, ModelAPIResponse } from '@/services/models';
import { useNavigate, useParams } from 'react-router-dom';
import { Step } from '@/components/Breadcrumbs/types';

import {
  Box,
  Button,
  Flex,
  FormControl,
  FormLabel,
  Select,
  Spacer,
  Text,
  VStack,
  Tag,
  Icon,
  Divider,
} from '@chakra-ui/react';
import { Editor } from '@monaco-editor/react';
import { ErrorMessage, Field, Form, Formik } from 'formik';
import * as Yup from 'yup';
import { UpdateModelPayload } from './types';
import ContentContainer from '@/components/ContentContainer';
import EntityItem from '@/components/EntityItem';
import Loader from '@/components/Loader';
import moment from 'moment';
import ModelActions from './ModelActions';
import { CustomToastStatus } from '@/components/Toast/index';
import useCustomToast from '@/hooks/useCustomToast';
import useQueryWrapper from '@/hooks/useQueryWrapper';
import { GetModelByIdResponse } from '@/views/Models/types';
import { useStore } from '@/stores';
import { FiLayout } from 'react-icons/fi';
import { QueryType } from '@/views/Models/types';

const ViewModel = (): JSX.Element => {
  const params = useParams();
  const showToast = useCustomToast();
  const navigate = useNavigate();

  const activeWorkspaceId = useStore((state) => state.workspaceId);

  const model_id = params.id || '';

  const { data, isLoading, isError } = useQueryWrapper<
    ModelAPIResponse<GetModelByIdResponse>,
    Error
  >(['modelByID', activeWorkspaceId, model_id], () => getModelById(model_id || ''), {
    refetchOnMount: true,
    refetchOnWindowFocus: true,
    retryOnMount: true,
    refetchOnReconnect: true,
  });

  const validationSchema = Yup.object().shape({
    primaryKey: Yup.string().required('Primary Key is required'),
  });

  if (isLoading) {
    return <Loader />;
  }

  if (isError) {
    return <>Error....</>;
  }

  if (!data) return <></>;

  const prefillValues: PrefillValue = {
    connector_id: data?.data?.attributes.connector.id || '',
    connector_icon: (
      <EntityItem
        name={data?.data?.attributes.connector.name || ''}
        icon={data?.data?.attributes.connector.icon || ''}
      />
    ),
    connector_name: data?.data?.attributes.connector.name || '',
    model_name: data?.data?.attributes.name || '',
    model_description: data?.data?.attributes.description || '',
    primary_key: data?.data?.attributes.primary_key || '',
    query: data?.data?.attributes.query || '',
    query_type: data?.data?.attributes.query_type || QueryType.RawSql,
    model_id: model_id,
  };

  async function handleModelUpdate(primary_key: string) {
    const updatePayload: UpdateModelPayload = {
      model: {
        name: prefillValues.model_name,
        description: prefillValues.model_description,
        primary_key: primary_key || '',
        connector_id: data?.data?.attributes.connector.id || '',
        query: prefillValues.query,
        query_type: prefillValues.query_type,
      },
    };
    const modelUpdateResponse = await putModelById(model_id, updatePayload);
    if (modelUpdateResponse.data) {
      showToast({
        title: 'Model updated successfully',
        status: CustomToastStatus.Success,
        duration: 3000,
        isClosable: true,
        position: 'bottom-right',
      });
    }
  }

  const EDIT_MODEL_FORM_STEPS: Step[] = [
    {
      name: 'Models',
      url: '/define/models',
    },
    {
      name: data.data?.attributes?.name || '',
      url: '',
    },
  ];

  // extracting table name from the query for table_selector method
  const tableName = prefillValues?.query?.split('FROM')?.[1]?.trim();

  return (
    <Box width='100%' display='flex' justifyContent='center'>
      <ContentContainer>
        <TopBar
          name={prefillValues?.model_name}
          breadcrumbSteps={EDIT_MODEL_FORM_STEPS}
          extra={
            <Box display='flex' alignItems='center'>
              <Box display='flex' alignItems='center'>
                <EntityItem
                  name={data.data?.attributes.connector.connector_name || ''}
                  icon={data.data?.attributes.connector.icon || ''}
                />
              </Box>
              <Divider
                orientation='vertical'
                height='24px'
                borderColor='gray.500'
                opacity='1'
                marginX='13px'
              />
              <Text size='sm' fontWeight='medium'>
                Last updated :{' '}
              </Text>
              <Text size='sm' fontWeight='semibold'>
                {moment(data.data?.attributes?.updated_at).format('DD/MM/YYYY')}
              </Text>
<<<<<<< HEAD
              <ModelActions prefillValues={prefillValues} />
=======
              <RoleAccess
                location='model'
                type='item'
                action={UserActions.Update}
                orAction={UserActions.Delete}
              >
                <ModelActions prefillValues={prefillValues} invalidateQuery={invalidateQuery} />
              </RoleAccess>
>>>>>>> 11791c77 (feat(CE): added Edit Details Modal (#791))
            </Box>
          }
        />
        <VStack>
          <Box w='full' mx='auto' bgColor='gray.100' rounded='xl'>
            <Flex
              w='full'
              roundedTop='xl'
              alignItems='center'
              bgColor='gray.300'
              padding='12px 20px'
              border='1px'
              borderColor='gray.400'
            >
              <EntityItem
                name={data.data?.attributes.connector.name || ''}
                icon={data.data?.attributes.connector.icon || ''}
              />
              <Spacer />
              <Button
                variant='shell'
                onClick={() => navigate('edit')}
                minWidth='0'
                width='auto'
                height='32px'
                fontSize='12px'
                paddingX={3}
              >
                Edit
              </Button>
            </Flex>
            <Box borderX='1px' borderBottom='1px' roundedBottom='lg' py={2} borderColor='gray.400'>
              {prefillValues?.query_type === QueryType.TableSelector ? (
                <Box padding='12px 20px' display='flex' gap='8px'>
                  <Text color='black.200' size='sm' fontWeight='semibold'>
                    Fetching all rows from the table
                  </Text>
                  <Tag
                    colorScheme='teal'
                    size='xs'
                    bgColor='gray.200'
                    padding='2px 8px'
                    fontWeight={600}
                    borderColor='gray.500'
                    borderWidth='1px'
                    borderStyle='solid'
                    height='22px'
                    borderRadius='4px'
                  >
                    <Icon as={FiLayout} color='black.200' height='12px' width='12px' />
                    <Text size='xs' fontWeight='semibold' color='black.300' marginLeft='4px'>
                      {tableName}
                    </Text>
                  </Tag>
                </Box>
              ) : (
                <Editor
                  width='100%'
                  height='280px'
                  language='mysql'
                  defaultLanguage='mysql'
                  defaultValue='Enter your query...'
                  value={prefillValues.query}
                  saveViewState={true}
                  theme='light'
                  options={{
                    minimap: {
                      enabled: false,
                    },
                    formatOnType: true,
                    formatOnPaste: true,
                    autoIndent: 'full',
                    wordBasedSuggestions: 'currentDocument',
                    scrollBeyondLastLine: false,
                    quickSuggestions: true,
                    tabCompletion: 'on',
                    contextmenu: true,
                    readOnly: true,
                  }}
                />
              )}
            </Box>
          </Box>
          <Box
            w='full'
            mx='auto'
            bgColor='gray.100'
            padding='24px'
            rounded='xl'
            border='1px'
            borderColor='gray.400'
          >
            <Text mb={6} fontWeight='bold'>
              Configure your model
            </Text>
            <Formik
              initialValues={{ primaryKey: '' }}
              validationSchema={validationSchema}
              onSubmit={(values) => handleModelUpdate(values.primaryKey)}
            >
              <Form>
                <VStack>
                  <FormControl>
                    <FormLabel htmlFor='primaryKey' fontSize='sm' fontWeight='bold'>
                      Primary Key
                    </FormLabel>
                    <Field
                      as={Select}
                      placeholder={prefillValues.primary_key}
                      name='primaryKey'
                      bgColor='gray.100'
                      borderColor='gray.600'
                      w='lg'
                      isDisabled
                    />
                    <Text color='red.500' fontSize='sm'>
                      <ErrorMessage name='primaryKey' />
                    </Text>
                  </FormControl>
                </VStack>
              </Form>
            </Formik>
          </Box>
        </VStack>
      </ContentContainer>
    </Box>
  );
};

export default ViewModel;
