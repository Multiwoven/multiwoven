import { useQuery } from '@tanstack/react-query';
import DefineSQL from '../ModelsForm/DefineModel/DefineSQL';
import { useParams } from 'react-router-dom';
import { Box, FormControl, FormLabel, Input, Text } from '@chakra-ui/react';
import { getModelById, putModelById } from '@/services/models';
import { PrefillValue } from '../ModelsForm/DefineModel/DefineSQL/types';
import TopBar from '@/components/TopBar';
import ContentContainer from '@/components/ContentContainer';
import EntityItem from '@/components/EntityItem';
import Loader from '@/components/Loader';
import { Step } from '@/components/Breadcrumbs/types';
import { useRef, useState, useEffect } from 'react';
import { Formik, Form, Field, ErrorMessage } from 'formik';
import * as Yup from 'yup';
import useCustomToast from '@/hooks/useCustomToast';
import { CustomToastStatus } from '@/components/Toast/index';
import { QueryType } from '../types';
import TableSelector from '../ModelsForm/DefineModel/TableSelector';

const EditModel = (): JSX.Element => {
  // State to track if the form is valid
  const [isModelNameValid, setIsModelNameValid] = useState<boolean>(true);
  const params = useParams();
  const containerRef = useRef(null);
  const showToast = useCustomToast();

  const model_id = params.id || '';

  const { data, isLoading: dataLoading, isError } = useQuery({
    queryKey: ['modelByID'],
    queryFn: () => getModelById(model_id || ''),
    refetchOnMount: true,
    refetchOnWindowFocus: true,
  });

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

  if (dataLoading) {
    return <Loader />;
  }

  if (isError) {
    return <>Error....</>;
  }

  const EDIT_QUERY_FORM_STEPS: Step[] = [
    {
      name: 'Models',
      url: '/define/models',
    },
    {
      name: data?.data?.attributes?.name || '',
      url: `/define/models/${model_id}`,
    },
    {
      name: 'Edit Query',
      url: '',
    },
  ];

  return (
    <Box width='100%' display='flex' justifyContent='center'>
      <ContentContainer containerRef={containerRef}>
        <Box w='full' mx='auto' paddingLeft='30px' paddingRight='30px'>
          <TopBar name='' breadcrumbSteps={EDIT_QUERY_FORM_STEPS} />
          <Box
            w='full'
            mx='auto'
            bgColor='gray.100'
            padding='24px'
            rounded='xl'
            border='1px'
            borderColor='gray.400'
            mb={6}
          >
            <Text mb={4} fontWeight='bold' fontSize='md'>
              Edit Model Details
            </Text>
            <Formik
              initialValues={{
                modelName: prefillValues.model_name,
              }}
              enableReinitialize
              validateOnChange={true}
              validateOnBlur={true}
              validationSchema={Yup.object().shape({
                modelName: Yup.string().required('Model name is required').trim(),
              })}
              onSubmit={async (values, { setSubmitting }) => {
                setSubmitting(true);
                try {
                  // Include all required fields in the payload
                  const updatePayload = {
                    model: {
                      name: values.modelName,
                      description: prefillValues.model_description || '',
                      primary_key: prefillValues.primary_key || '',
                      query: prefillValues.query || '',
                      query_type: prefillValues.query_type || '',
                      connector_id: prefillValues.connector_id || '',
                    },
                  };

                  try {
                    const response = await putModelById(model_id, updatePayload);
                    if (response && response.data) {
                      showToast({
                        title: 'Model name updated successfully',
                        status: CustomToastStatus.Success,
                        duration: 3000,
                        isClosable: true,
                        position: 'bottom-right',
                      });
                      
                      // Update breadcrumb with new name
                      EDIT_QUERY_FORM_STEPS[1].name = values.modelName;
                    }
                  } catch (innerError) {
                    console.error('API response error:', innerError);
                    throw innerError; // Re-throw to be caught by the outer catch
                  }
                } catch (error) {
                  console.error('Error updating model:', error);
                  showToast({
                    title: 'Failed to update model name',
                    status: CustomToastStatus.Error,
                    duration: 3000,
                    isClosable: true,
                    position: 'bottom-right',
                  });
                } finally {
                  setSubmitting(false);
                }
              }}
            >
              {({ handleChange, values, errors, validateField }) => {
                // Check if the model name is valid whenever it changes
                useEffect(() => {
                  // Validate the field
                  validateField('modelName');
                  
                  // Check if valid
                  const isValid = !errors.modelName && values.modelName && values.modelName.trim() !== '';
                  setIsModelNameValid(Boolean(isValid));
                  
                  // Always update prefillValues with the current value
                  if (values.modelName !== undefined) {
                    prefillValues.model_name = values.modelName;
                  }
                }, [values.modelName, errors.modelName, validateField]);
                
                return (
                  <Form>
                    <FormControl mb={4}>
                      <FormLabel htmlFor='modelName' fontSize='sm' fontWeight='semibold'>
                        Model Name <Text as='span' color='red.500'>*</Text>
                      </FormLabel>
                      <Field
                        as={Input}
                        id='modelName'
                        name='modelName'
                        value={values.modelName}
                        onChange={(e: React.ChangeEvent<HTMLInputElement>) => {
                          // Prevent spaces at the beginning of the name
                          const value = e.target.value;
                          if (value === ' ' || value.startsWith(' ')) {
                            e.target.value = value.trimStart();
                          }
                          handleChange(e);
                        }}
                        placeholder='Enter a name'
                        bgColor='white'
                        borderStyle='solid'
                        borderWidth='1'
                        borderColor='gray.400'
                        maxWidth='100%'
                        isRequired
                      />
                      <Text color='red.500' fontSize='sm'>
                        <ErrorMessage name='modelName' />
                      </Text>
                    </FormControl>
                  </Form>
                );
              }}
            </Formik>
          </Box>
        </Box>
        {/* Only allow the form submission if the model name is valid */}
        {prefillValues.query_type === QueryType.TableSelector ? (
          <TableSelector
            hasPrefilledValues={true}
            prefillValues={prefillValues}
            isUpdateButtonVisible={isModelNameValid}
          />
        ) : (
          <DefineSQL
            isFooterVisible={false}
            hasPrefilledValues={true}
            prefillValues={prefillValues}
            isUpdateButtonVisible={isModelNameValid}
            isAlignToContentContainer={true}
          />
        )}
      </ContentContainer>
    </Box>
  );
};

export default EditModel;