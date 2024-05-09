import { Box, Input, Text, Textarea } from '@chakra-ui/react';
import SourceFormFooter from '../SourceFormFooter';
import { useFormik } from 'formik';
import { useContext, useState } from 'react';
import { SteppedFormContext } from '@/components/SteppedForm/SteppedForm';
import { CreateConnectorPayload, TestConnectionPayload } from '@/views/Connectors/types';
import { useNavigate } from 'react-router-dom';
import { createNewConnector } from '@/services/connectors';
import { useQueryClient } from '@tanstack/react-query';
import { SOURCES_LIST_QUERY_KEY } from '@/views/Connectors/constant';
import ContentContainer from '@/components/ContentContainer';
import { CustomToastStatus } from '@/components/Toast/index';
import useCustomToast from '@/hooks/useCustomToast';

const finalDataSourceFormKey = 'testSource';

const SourceFinalizeForm = (): JSX.Element | null => {
  const [isLoading, setIsLoading] = useState<boolean>(false);
  const { state } = useContext(SteppedFormContext);
  const { forms } = state;
  const showToast = useCustomToast();
  const navigate = useNavigate();
  const queryClient = useQueryClient();
  const finalDataSourceForm = forms.find(({ stepKey }) => stepKey === finalDataSourceFormKey)
    ?.data?.[finalDataSourceFormKey] as TestConnectionPayload | undefined;

  if (!finalDataSourceForm) return null;

  const formik = useFormik({
    initialValues: {
      connector_name: finalDataSourceForm.name,
      description: '',
    },
    onSubmit: async (formData) => {
      setIsLoading(true);
      try {
        const payload: CreateConnectorPayload = {
          connector: {
            configuration: finalDataSourceForm.connection_spec,
            name: formData.connector_name,
            connector_type: 'source',
            connector_name: finalDataSourceForm.name,
            description: formData.description,
          },
        };

        const createConnectorResponse = await createNewConnector(payload);
        if (createConnectorResponse?.data) {
          queryClient.removeQueries({
            queryKey: SOURCES_LIST_QUERY_KEY,
          });

          showToast({
            status: CustomToastStatus.Success,
            title: 'Success!!',
            description: 'Source created successfully!',
            position: 'bottom-right',
          });
          navigate('/setup/sources');
        } else {
          throw new Error();
        }
      } catch {
        showToast({
          status: CustomToastStatus.Error,
          title: 'An error occurred.',
          description: 'Something went wrong while creating your Source.',
          position: 'bottom-right',
          isClosable: true,
        });
      } finally {
        setIsLoading(false);
      }
    },
  });

  return (
    <Box display='flex' justifyContent='center'>
      <ContentContainer>
        <Box width='100%'>
          <form onSubmit={formik.handleSubmit}>
            <Box padding='24px' backgroundColor='gray.300' borderRadius='8px' marginBottom='16px'>
              <Text size='md' fontWeight='semibold' marginBottom='24px'>
                Finalize settings for this Source
              </Text>
              <Box>
                <Text marginBottom='8px' fontWeight='semibold' size='sm'>
                  Source Name
                </Text>
                <Input
                  name='connector_name'
                  type='text'
                  placeholder='Enter Source name'
                  background='gray.100'
                  marginBottom='24px'
                  onChange={formik.handleChange}
                  value={formik.values.connector_name}
                  required
                  borderStyle='solid'
                  borderWidth='1px'
                  borderColor='gray.400'
                  fontSize='14px'
                />
                <Box display='flex' alignItems='center' marginBottom='8px'>
                  <Text size='sm' fontWeight='semibold'>
                    Description
                  </Text>
                  <Text size='xs' color='gray.600' ml={1} fontWeight={400}>
                    (Optional)
                  </Text>
                </Box>
                <Textarea
                  name='description'
                  placeholder='Enter a description'
                  background='gray.100'
                  resize='none'
                  onChange={formik.handleChange}
                  value={formik.values.description}
                  borderStyle='solid'
                  borderWidth='1px'
                  borderColor='gray.400'
                  fontSize='14px'
                />
              </Box>
            </Box>
            <SourceFormFooter
              ctaName='Finish'
              ctaType='submit'
              isCtaLoading={isLoading}
              isContinueCtaRequired
              isBackRequired
              isDocumentsSectionRequired
            />
          </form>
        </Box>
      </ContentContainer>
    </Box>
  );
};

export default SourceFinalizeForm;
