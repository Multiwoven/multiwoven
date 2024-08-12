import { Box, Input, Text, Textarea } from '@chakra-ui/react';
import { useFormik } from 'formik';
import { useContext, useState } from 'react';
import { SteppedFormContext } from '@/components/SteppedForm/SteppedForm';
import {
  CreateConnectorPayload,
  TestConnectionPayload,
  ConnectorTypes,
} from '@/views/Connectors/types';
import { useNavigate } from 'react-router-dom';
import { createNewConnector } from '@/services/connectors';
import { useQueryClient } from '@tanstack/react-query';
import { useUiConfig } from '@/utils/hooks';
import FormFooter from '@/components/FormFooter';
import ContentContainer from '@/components/ContentContainer';
import { CustomToastStatus } from '@/components/Toast/index';
import useCustomToast from '@/hooks/useCustomToast';

const finalDestinationConfigFormKey = 'testDestination';
const finalDataSourceFormKey = 'testSource';

const ConnectorFinaliseForm = ({
  connectorType,
}: {
  connectorType: ConnectorTypes;
}): JSX.Element | null => {
  const [isLoading, setIsLoading] = useState<boolean>(false);
  const { maxContentWidth } = useUiConfig();
  const { state } = useContext(SteppedFormContext);
  const { forms } = state;
  const showToast = useCustomToast();
  const navigate = useNavigate();
  const queryClient = useQueryClient();

  const CONNECTOR_TYPE_TITLE = connectorType === 'source' ? 'Source' : 'Destination';

  const configKey =
    connectorType === 'source' ? finalDataSourceFormKey : finalDestinationConfigFormKey;

  const finalConnectorConfigForm = forms.find(({ stepKey }) => stepKey === configKey)?.data?.[
    configKey
  ] as TestConnectionPayload | undefined;

  if (!finalConnectorConfigForm) return null;

  const formik = useFormik({
    initialValues: {
      connector_name: finalConnectorConfigForm.name,
      description: '',
    },
    onSubmit: async (formData) => {
      setIsLoading(true);
      try {
        const payload: CreateConnectorPayload = {
          connector: {
            configuration: finalConnectorConfigForm.connection_spec,
            name: formData.connector_name,
            connector_type: connectorType,
            connector_name: finalConnectorConfigForm.name,
            description: formData.description,
          },
        };

        const createConnectorResponse = await createNewConnector(payload);
        if (createConnectorResponse?.data) {
          queryClient.removeQueries({
            queryKey: ['connectors', connectorType],
          });

          showToast({
            status: CustomToastStatus.Success,
            title: 'Success!!',
            description: `${CONNECTOR_TYPE_TITLE} created successfully!`,
            position: 'bottom-right',
          });
          if (connectorType === 'source') {
            navigate('/setup/sources');
          } else {
            navigate('/setup/destinations');
          }
        } else {
          throw new Error();
        }
      } catch {
        showToast({
          status: CustomToastStatus.Error,
          title: 'An error occurred.',
          description: `Something went wrong while creating the ${CONNECTOR_TYPE_TITLE}.`,
          position: 'bottom-right',
          isClosable: true,
        });
      } finally {
        setIsLoading(false);
      }
    },
  });

  return (
    <Box width='100%' display='flex' justifyContent='center'>
      <ContentContainer>
        <Box maxWidth={maxContentWidth} width='100%'>
          <form onSubmit={formik.handleSubmit}>
            <Box padding='24px' backgroundColor='gray.300' borderRadius='8px' marginBottom='16px'>
              <Text size='md' fontWeight='semibold' marginBottom='24px'>
                {`Finalize settings for this ${CONNECTOR_TYPE_TITLE}`}
              </Text>
              <Box>
                <Text marginBottom='8px' fontWeight='semibold' size='sm'>
                  {`${CONNECTOR_TYPE_TITLE} Name`}
                </Text>
                <Input
                  name='connector_name'
                  type='text'
                  placeholder={`Enter ${CONNECTOR_TYPE_TITLE} name`}
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
            <FormFooter
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

export default ConnectorFinaliseForm;
