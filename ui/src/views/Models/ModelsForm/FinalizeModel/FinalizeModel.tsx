import { SteppedFormContext } from '@/components/SteppedForm/SteppedForm';
import { extractDataByKey } from '@/utils';
import { ColumnMapType } from '@/utils/types';
import {
  Box,
  Flex,
  FormControl,
  FormLabel,
  Input,
  Select,
  Text,
  Textarea,
  VStack,
} from '@chakra-ui/react';
import { Formik, Form, Field, ErrorMessage } from 'formik';
import { useContext, useState } from 'react';
import * as Yup from 'yup';
import { useQueryClient } from '@tanstack/react-query';

import { useNavigate } from 'react-router-dom';
import { FinalizeForm } from './types';
import { CreateModelPayload } from '../../types';
import { createNewModel } from '@/services/models';
import FormFooter from '@/components/FormFooter';
import { CustomToastStatus } from '@/components/Toast/index';
import useCustomToast from '@/hooks/useCustomToast';
import ContentContainer from '@/components/ContentContainer';

type ModelConfig = {
  id: number;
  query: string;
  query_type: string;
  columns: ColumnMapType[];
};

type StepData = {
  step: number;
  data: { [key: string]: ModelConfig };
  stepKey: string;
};

const FinalizeModel = (): JSX.Element => {
  const { state } = useContext(SteppedFormContext);
  const defineModelData: StepData = extractDataByKey<StepData>(state.forms, 'defineModel');

  const navigate = useNavigate();
  const queryClient = useQueryClient();
  const showToast = useCustomToast();
  const [isLoading, setIsLoading] = useState(false);

  const validationSchema = Yup.object().shape({
    modelName: Yup.string().required('Model name is required'),
    description: Yup.string(),
    primaryKey: Yup.string().required('Primary Key is required'),
  });

  async function handleModelSubmit(values: FinalizeForm) {
    try {
      const payload: CreateModelPayload = {
        model: {
          connector_id: defineModelData?.data.defineModel.id,
          name: values.modelName,
          description: values.description,
          query: defineModelData?.data.defineModel.query,
          query_type: defineModelData?.data.defineModel.query_type,
          primary_key: values.primaryKey,
        },
      };

      setIsLoading(true);

      const createConnectorResponse = await createNewModel(payload);
      if (createConnectorResponse?.data) {
        queryClient.removeQueries({
          queryKey: ['Create Model'],
        });
        showToast({
          status: CustomToastStatus.Success,
          title: 'Success!!',
          description: 'Model created successfully!',
          position: 'bottom-right',
        });
        navigate('/define/models');
      } else {
        throw createConnectorResponse?.errors || new Error('Failed to create model');
      }
    } catch (error) {
      let errorMessage = 'Something went wrong while creating Model.';

      // Simple error handling for API errors
      if (error && typeof error === 'object') {
        const errorObj = error as Record<string, any>;
        if (errorObj.model && typeof errorObj.model === 'object') {
          // Handle specific case where error is { model: {...} }
          const modelErrors = [];
          const modelObj = errorObj.model as Record<string, any>;
          for (const key in modelObj) {
            modelErrors.push(`${key}: ${modelObj[key]}`);
          }
          errorMessage = modelErrors.join(', ');
        } else {
          // Try to create a readable message from the error object
          const errorParts = [];
          for (const key in errorObj) {
            errorParts.push(`${key}: ${JSON.stringify(errorObj[key])}`);
          }
          if (errorParts.length > 0) {
            errorMessage = errorParts.join(', ');
          }
        }
      }

      showToast({
        status: CustomToastStatus.Error,
        title: 'An error occurred.',
        description: errorMessage,
        position: 'bottom-right',
        isClosable: true,
      });
    } finally {
      setIsLoading(false);
    }
  }

  return (
    <Box display='flex' width='100%' justifyContent='center'>
      <ContentContainer>
        <Box bgColor='gray.200' px={6} py={4} marginTop={6} borderRadius='8px'>
          <Text mb={6} fontWeight='semibold' size='md'>
            Finalize settings for this Model
          </Text>
          <Formik
            initialValues={{
              modelName: '',
              description: '',
              primaryKey: '',
            }}
            validationSchema={validationSchema}
            onSubmit={(values) => {
              handleModelSubmit(values);
            }}
          >
            <Form>
              <VStack spacing={5}>
                <FormControl>
                  <FormLabel htmlFor='modelName' fontSize='sm' fontWeight='semibold'>
                    Model Name
                  </FormLabel>
                  <Field
                    as={Input}
                    id='modelName'
                    name='modelName'
                    placeholder='Enter a name'
                    bgColor='white'
                    borderWidth='1'
                    borderStyle='solid'
                    borderColor='gray.400'
                    fontSize='sm'
                  />
                  <Text color='red.500' fontSize='sm'>
                    <ErrorMessage name='modelName' />
                  </Text>
                </FormControl>
                <FormControl>
                  <FormLabel htmlFor='description' fontWeight='semibold'>
                    <Flex alignItems='center' fontSize='sm'>
                      Description{' '}
                      <Text ml={2} size='xs' color='gray.600' fontWeight={400}>
                        {' '}
                        (optional)
                      </Text>
                    </Flex>
                  </FormLabel>
                  <Field
                    as={Textarea}
                    id='description'
                    name='description'
                    placeholder='Enter a description'
                    bgColor='white'
                    borderWidth='1'
                    borderStyle='solid'
                    borderColor='gray.400'
                    fontSize='sm'
                  />
                </FormControl>
                <FormControl>
                  <FormLabel htmlFor='primaryKey' fontSize='sm' fontWeight='semibold'>
                    Primary Key
                  </FormLabel>
                  <Field
                    as={Select}
                    placeholder='Select Primary Key'
                    name='primaryKey'
                    bgColor='white'
                    w='lg'
                    borderWidth='1'
                    borderStyle='solid'
                    borderColor='gray.400'
                    fontSize='sm'
                  >
                    {(defineModelData.data.defineModel.columns ?? []).map(
                      ({ key, name }: ColumnMapType, index: number) => (
                        <option key={index} value={key}>
                          {name}
                        </option>
                      ),
                    )}
                  </Field>
                  <Text color='red.500' fontSize='sm'>
                    <ErrorMessage name='primaryKey' />
                  </Text>
                </FormControl>
              </VStack>
              <FormFooter
                isCtaLoading={isLoading}
                ctaType='submit'
                ctaName='Finish'
                isBackRequired
                isContinueCtaRequired
              />
            </Form>
          </Formik>
        </Box>
      </ContentContainer>
    </Box>
  );
};

export default FinalizeModel;
