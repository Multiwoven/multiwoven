import { putModelById } from '@/services/models';
import {
  Box,
  Button,
  Flex,
  FormControl,
  FormLabel,
  Modal,
  ModalBody,
  ModalCloseButton,
  ModalContent,
  ModalHeader,
  ModalOverlay,
  Text,
  VStack,
  useDisclosure,
  Input,
  Textarea,
} from '@chakra-ui/react';
import { FiEdit3 } from 'react-icons/fi';
import { useParams } from 'react-router-dom';
import { ErrorMessage, Field, Form, Formik } from 'formik';
import * as Yup from 'yup';
import { PrefillValue } from '../../ModelsForm/DefineModel/DefineSQL/types';
import { CustomToastStatus } from '@/components/Toast/index';
import useCustomToast from '@/hooks/useCustomToast';
import { ModelSubmitFormValues, UpdateModelPayload } from '../types';
import { useState } from 'react';

const EditModelModal = (prefillValues: PrefillValue): JSX.Element => {
  const { isOpen, onOpen, onClose } = useDisclosure();
  const [loading, setLoading] = useState(false);

  const params = useParams();
  const showToast = useCustomToast();

  const model_id = params.id || '';

  async function handleModelUpdate(values: ModelSubmitFormValues) {
    const updatePayload: UpdateModelPayload = {
      model: {
        name: values.modelName,
        description: values.description,
        primary_key: prefillValues.primary_key,
        connector_id: prefillValues.connector_id || '',
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
      setLoading(false);
      onClose();
    }
    setLoading(false);
  }

  const validationSchema = Yup.object().shape({
    modelName: Yup.string().required('Model name is required'),
    description: Yup.string(),
  });

  return (
    <>
      <Button
        _hover={{ bgColor: 'gray.200' }}
        w='100%'
        py={3}
        px={2}
        display='flex'
        flexDir='row'
        alignItems='center'
        color={'red.600'}
        rounded='lg'
        onClick={onOpen}
        as='button'
        justifyContent='start'
        border={0}
        variant='shell'
      >
        <FiEdit3 color='#98A2B3' />
        <Text size='sm' fontWeight='medium' ml={3} color='black.500'>
          Edit details
        </Text>
      </Button>

      <Modal isOpen={isOpen} onClose={onClose} isCentered size='2xl'>
        <ModalOverlay bg='blackAlpha.400' />
        <ModalContent>
          <ModalCloseButton color='gray.600' />
          <ModalHeader>
            <Text size='xl' fontWeight='bold'>
              Edit Details
            </Text>
            <Text size='sm' color='black.200' fontWeight={400}>
              Edit the settings for this Model
            </Text>
          </ModalHeader>
          <ModalBody>
            <Formik
              initialValues={{
                modelName: prefillValues.model_name,
                description: prefillValues.model_description,
              }}
              validationSchema={validationSchema}
              onSubmit={(values) => {
                handleModelUpdate(values);
                setLoading(true);
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
                      variant='outline'
                      placeholder='Enter a name'
                      bgColor='white'
                      borderStyle='solid'
                      borderWidth='1'
                      borderColor='gray.400'
                    />
                    <Text color='red.500' fontSize='sm'>
                      <ErrorMessage name='modelName' />
                    </Text>
                  </FormControl>
                  <FormControl>
                    <FormLabel htmlFor='description' fontWeight='bold'>
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
                      borderStyle='solid'
                      borderWidth='1'
                      borderColor='gray.400'
                    />
                  </FormControl>
                </VStack>
                <Box w='full' pt={8} paddingBottom={5}>
                  <Flex flexDir='row' justifyContent='end'>
                    <Button
                      bgColor='gray.300'
                      variant='ghost'
                      color='black'
                      mr={3}
                      onClick={onClose}
                      paddingX={4}
                      minWidth='0'
                      width='auto'
                    >
                      Cancel
                    </Button>
                    <Button
                      type='submit'
                      isLoading={loading}
                      paddingX={4}
                      minWidth='0'
                      width='auto'
                    >
                      Save Changes
                    </Button>
                  </Flex>
                </Box>
              </Form>
            </Formik>
          </ModalBody>
        </ModalContent>
      </Modal>
    </>
  );
};

export default EditModelModal;
