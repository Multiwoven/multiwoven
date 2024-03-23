import {
  getConnectionStatus,
  getConnectorDefinition,
  getConnectorInfo,
  updateConnector,
} from '@/services/connectors';
import { useMutation, useQuery, useQueryClient } from '@tanstack/react-query';
import { useNavigate, useParams } from 'react-router-dom';

import validator from '@rjsf/validator-ajv8';
import { Form } from '@rjsf/chakra-ui';
import { Box, Button, Divider, Text } from '@chakra-ui/react';
import TopBar from '@/components/TopBar';
import ContentContainer from '@/components/ContentContainer';
import { useEffect, useState } from 'react';
import { CreateConnectorPayload, TestConnectionPayload } from '../../types';
import { RJSFSchema } from '@rjsf/utils';
import SourceFormFooter from '../../Sources/SourcesForm/SourceFormFooter';
import Loader from '@/components/Loader';
import ObjectFieldTemplate from '@/views/Connectors/Sources/rjsf/ObjectFieldTemplate';
import TitleFieldTemplate from '@/views/Connectors/Sources/rjsf/TitleFieldTemplate';
import FieldTemplate from '@/views/Connectors/Sources/rjsf/FieldTemplate';
import { FormProps } from '@rjsf/core';
import BaseInputTemplate from '@/views/Connectors/Sources/rjsf/BaseInputTemplate';
import DescriptionFieldTemplate from '@/views/Connectors/Sources/rjsf/DescriptionFieldTemplate';
import { uiSchemas } from '../../Sources/SourcesForm/SourceConfigForm/SourceConfigForm';
import { Step } from '@/components/Breadcrumbs/types';
import EntityItem from '@/components/EntityItem';
import moment from 'moment';
import SourceActions from '../../Sources/EditSource/SourceActions';
import { CustomToastStatus } from '@/components/Toast/index';
import useCustomToast from '@/hooks/useCustomToast';

const EditDestination = (): JSX.Element => {
  const { destinationId } = useParams();
  const CONNECTOR_INFO_KEY = ['connectorInfo', 'destination', destinationId];
  const queryClient = useQueryClient();

  const showToast = useCustomToast();
  const navigate = useNavigate();
  const [formData, setFormData] = useState<unknown>(null);

  const [isTestRunning, setIsTestRunning] = useState<boolean>(false);
  const [testedFormData, setTestedFormData] = useState<unknown>(null);

  const { data: connectorInfoResponse, isLoading: isConnectorInfoLoading } = useQuery({
    queryKey: CONNECTOR_INFO_KEY,
    queryFn: () => getConnectorInfo(destinationId as string),
    refetchOnMount: true,
    refetchOnWindowFocus: false,
    enabled: !!destinationId,
  });

  const connectorInfo = connectorInfoResponse?.data;
  const connectorName = connectorInfo?.attributes?.connector_name;

  const { data: connectorDefinitionResponse, isLoading: isConnectorDefinitionLoading } = useQuery({
    queryKey: ['connector_definition', connectorName],
    queryFn: () => getConnectorDefinition('destination', connectorName as string),
    refetchOnMount: false,
    refetchOnWindowFocus: false,
    enabled: !!connectorName,
  });

  const connectorSchema = connectorDefinitionResponse?.data?.connector_spec;

  useEffect(() => {
    setFormData(connectorInfo?.attributes?.configuration);
  }, [connectorDefinitionResponse]);

  const handleOnSaveChanges = async () => {
    if (!connectorInfo?.attributes) return;
    const payload: CreateConnectorPayload = {
      connector: {
        configuration: testedFormData,
        name: connectorInfo?.attributes?.name,
        connector_type: 'destination',
        connector_name: connectorInfo?.attributes?.connector_name,
        description: connectorInfo?.attributes?.description ?? '',
      },
    };
    return updateConnector(payload, destinationId as string);
  };

  const { isPending: isEditLoading, mutate } = useMutation({
    mutationFn: handleOnSaveChanges,
    onSettled: () => {
      showToast({
        status: CustomToastStatus.Success,
        title: 'Success!!',
        description: 'Connector Updated',
        position: 'bottom-right',
        isClosable: true,
      });

      queryClient.removeQueries({
        queryKey: CONNECTOR_INFO_KEY,
      });

      navigate('/setup/destinations');
    },
    onError: () => {
      showToast({
        status: CustomToastStatus.Error,
        title: 'Error!!',
        description: 'Something went wrong',
        position: 'bottom-right',
        isClosable: true,
      });
    },
  });

  const handleOnTestClick = async (formData: unknown) => {
    setIsTestRunning(true);

    if (!connectorInfo?.attributes) return;

    try {
      const payload: TestConnectionPayload = {
        connection_spec: formData,
        name: connectorInfo?.attributes?.connector_name,
        type: 'destination',
      };

      const testingConnectionResponse = await getConnectionStatus(payload);
      const isConnectionSucceeded =
        testingConnectionResponse?.connection_status?.status === 'succeeded';

      if (isConnectionSucceeded) {
        showToast({
          status: CustomToastStatus.Success,
          title: 'Connection successful',
          position: 'bottom-right',
          isClosable: true,
        });
        return;
      }

      showToast({
        status: CustomToastStatus.Error,
        title: 'Connection failed',
        description: testingConnectionResponse?.connection_status?.message,
        position: 'bottom-right',
        isClosable: true,
      });
    } catch (e) {
      showToast({
        status: CustomToastStatus.Error,
        title: 'Connection failed',
        description: 'Something went wrong!',
        position: 'bottom-right',
        isClosable: true,
      });
    } finally {
      setIsTestRunning(false);
      setTestedFormData(formData);
    }
  };

  const templateOverrides: FormProps<any, RJSFSchema, any>['templates'] = {
    ObjectFieldTemplate: ObjectFieldTemplate,
    TitleFieldTemplate: TitleFieldTemplate,
    FieldTemplate: FieldTemplate,
    BaseInputTemplate: BaseInputTemplate,
    DescriptionFieldTemplate: DescriptionFieldTemplate,
  };

  const EDIT_DESTINATION_STEP: Step[] = [
    {
      name: 'Destinations',
      url: '/setup/destinations',
    },
    {
      name: connectorName || '',
      url: '',
    },
  ];

  if (isConnectorInfoLoading || isConnectorDefinitionLoading) return <Loader />;

  return (
    <Box width='100%' display='flex' justifyContent='center'>
      <ContentContainer>
        <TopBar
          name={connectorName || ''}
          breadcrumbSteps={EDIT_DESTINATION_STEP}
          extra={
            <Box display='flex' alignItems='center'>
              <Box display='flex' alignItems='center'>
                <EntityItem
                  name={connectorInfo?.attributes?.connector_name || ''}
                  icon={connectorInfo?.attributes?.icon || ''}
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
                {moment(connectorInfo?.attributes?.updated_at).format('DD/MM/YYYY')}
              </Text>
              <SourceActions connectorType='destinations' />
            </Box>
          }
        />

        <Box
          backgroundColor='gray.100'
          padding='24px'
          borderWidth='thin'
          borderRadius='8px'
          marginBottom='100px'
        >
          <Form
            uiSchema={
              connectorSchema?.connection_specification?.title
                ? uiSchemas[connectorSchema?.connection_specification?.title.toLowerCase()]
                : undefined
            }
            schema={connectorSchema?.connection_specification as RJSFSchema}
            validator={validator}
            formData={formData}
            onSubmit={({ formData }) => handleOnTestClick(formData)}
            onChange={({ formData }) => setFormData(formData)}
            templates={templateOverrides}
          >
            <SourceFormFooter
              ctaName='Save Changes'
              ctaType='button'
              isCtaDisabled={!testedFormData}
              onCtaClick={mutate}
              isCtaLoading={isEditLoading}
              isAlignToContentContainer
              isContinueCtaRequired
              isDocumentsSectionRequired
              extra={
                <Button
                  marginRight='10px'
                  type='submit'
                  variant='ghost'
                  isLoading={isTestRunning}
                  minWidth={0}
                  width='auto'
                  backgroundColor='gray.300'
                >
                  Test Connection
                </Button>
              }
            />
          </Form>
        </Box>
      </ContentContainer>
    </Box>
  );
};

export default EditDestination;
