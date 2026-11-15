import {
  getConnectionStatus,
  getConnectorDefinition,
  getConnectorInfo,
  updateConnector,
} from '@/services/connectors';
import { useMutation, useQuery } from '@tanstack/react-query';
import { useNavigate, useParams } from 'react-router-dom';

import { Box, Button, Divider, Text } from '@chakra-ui/react';
import TopBar from '@/components/TopBar';
import ContentContainer from '@/components/ContentContainer';
import { useEffect, useState } from 'react';
import { CreateConnectorPayload, TestConnectionPayload } from '../../types';
import { RJSFSchema } from '@rjsf/utils';
import Loader from '@/components/Loader';
import { Step } from '@/components/Breadcrumbs/types';
import EntityItem from '@/components/EntityItem';
import moment from 'moment';

import { CustomToastStatus } from '@/components/Toast/index';
import useCustomToast from '@/hooks/useCustomToast';
import JSONSchemaForm from '../../../../components/JSONSchemaForm';
import { generateUiSchema } from '@/utils/generateUiSchema';
import { useStore } from '@/stores';
import FormFooter from '@/components/FormFooter';
<<<<<<< HEAD
=======
import { getCatalog } from '@/services/syncs';
import { SourceTypes } from '../../types';
import { ConnectorSpec, SchemaFieldOptions } from '@/enterprise/views/AIMLSources/types/types';
import { useAPIErrorsToast, useErrorToast } from '@/hooks/useErrorToast';
import SchemaForm from '@/enterprise/views/AIMLSources/Schema/SchemaForm';
import ConnectorActions from '@/views/Connectors/ConnectorActions';
>>>>>>> 11791c77 (feat(CE): added Edit Details Modal (#791))

const EditSource = (): JSX.Element => {
  const activeWorkspaceId = useStore((state) => state.workspaceId);

  const { sourceId } = useParams();
  const showToast = useCustomToast();
  const navigate = useNavigate();
  const [formData, setFormData] = useState<unknown>(null);

  const [isTestRunning, setIsTestRunning] = useState<boolean>(false);
  const [testedFormData, setTestedFormData] = useState<unknown>(null);

<<<<<<< HEAD
=======
  const [inputSchemaFields, setInputSchemaFields] = useState<SchemaFieldOptions[]>([
    { name: '', type: '', value: '', value_type: 'dynamic' },
  ]);
  const [outputSchemaFields, setOutputSchemaFields] = useState<SchemaFieldOptions[]>([
    { name: '', type: '' },
  ]);
  const [isUpdatingConnector, setIsUpdatingConnector] = useState<boolean>(false);

  const apiError = useAPIErrorsToast();
  const errorToast = useErrorToast();

>>>>>>> 11791c77 (feat(CE): added Edit Details Modal (#791))
  const { data: connectorInfoResponse, isLoading: isConnectorInfoLoading } = useQuery({
    queryKey: ['connectorInfo', sourceId, activeWorkspaceId],
    queryFn: () => getConnectorInfo(sourceId as string),
    refetchOnMount: true,
    refetchOnWindowFocus: true,
    enabled: !!sourceId && activeWorkspaceId > 0,
  });

  const connectorInfo = connectorInfoResponse?.data;
  const connectorName = connectorInfo?.attributes?.connector_name;

  const { data: connectorDefinitionResponse, isLoading: isConnectorDefinitionLoading } = useQuery({
    queryKey: ['connector_definition', connectorName, activeWorkspaceId],
    queryFn: () => getConnectorDefinition('source', connectorName as string),
    refetchOnMount: false,
    refetchOnWindowFocus: false,
    enabled: !!connectorName && activeWorkspaceId > 0,
  });

  const connectorSchema = connectorDefinitionResponse?.data?.connector_spec;

  useEffect(() => {
    setFormData(connectorInfo?.attributes?.configuration);
  }, [connectorDefinitionResponse, connectorInfoResponse]);

  const handleOnSaveChanges = async () => {
    if (!connectorInfo?.attributes) return;
    const payload: CreateConnectorPayload = {
      connector: {
        configuration: testedFormData,
        name: connectorInfo?.attributes?.name,
        connector_type: 'source',
        connector_name: connectorInfo?.attributes?.connector_name,
        description: connectorInfo?.attributes?.description ?? '',
      },
    };
    return updateConnector(payload, sourceId as string);
  };

<<<<<<< HEAD
  const { isPending: isEditLoading, mutate } = useMutation({
    mutationFn: handleOnSaveChanges,
    onSettled: () => {
=======
    setIsUpdatingConnector(true);
    try {
      const updateConnectorPayload: CreateConnectorPayload = {
        connector: {
          configuration: testedFormData,
          name: connectorInfo?.attributes?.name,
          connector_type: 'source',
          connector_name: connectorInfo?.attributes?.connector_name,
          description: connectorInfo?.attributes?.description ?? '',
        },
      };

      const updateConnectorResponse = await updateConnector(updateConnectorPayload, sourceId);

      if (updateConnectorResponse?.data) {
        queryClient.invalidateQueries({
          queryKey: ['connectorInfo', sourceId, activeWorkspaceId],
        });
        if (sourceType === SourceTypes.AI_ML) {
          queryClient.invalidateQueries({
            queryKey: ['connector_definition', connectorName, activeWorkspaceId],
          });
          const catalogUpdatePayload: CreateCatalogPayload = {
            connector_id: +sourceId,
            catalog: {
              json_schema: {
                input: inputSchemaFields,
                output: outputSchemaFields,
              },
            },
          };

          const updateCatalogResponse = await updateCatalog(
            catalogData?.data?.id as string,
            catalogUpdatePayload,
          );

          if (updateCatalogResponse?.data) {
            showToast({
              status: CustomToastStatus.Success,
              title: 'Success!!',
              description: `Source updated successfully!`,
              position: 'bottom-right',
            });

            navigate('/setup/sources');
          } else {
            if (updateCatalogResponse.errors) {
              apiError(updateCatalogResponse.errors);
            }
          }
        } else {
          navigate('/setup/sources');
        }
      } else {
        if (updateConnectorResponse.errors) {
          apiError(updateConnectorResponse.errors);
        }
      }
    } catch {
>>>>>>> 11791c77 (feat(CE): added Edit Details Modal (#791))
      showToast({
        status: CustomToastStatus.Success,
        title: 'Success!!',
        description: 'Connector Updated',
        position: 'bottom-right',
        isClosable: true,
      });
      navigate('/setup/sources');
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
        type: 'source',
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

<<<<<<< HEAD
=======
  const handleUpdate = async (values: { name: string; description: string }) => {
    if (!connectorInfo?.attributes || !sourceId) {
      errorToast(`Something went wrong while updating the source.`, true, null, true);
      return;
    }

    try {
      const updateConnectorPayload: CreateConnectorPayload = {
        connector: {
          configuration: formData,
          name: values.name ?? connectorInfo?.attributes?.name,
          connector_type: 'source',
          connector_name: connectorInfo?.attributes?.connector_name,
          description: values.description ?? connectorInfo?.attributes?.description ?? '',
        },
      };

      const updateConnectorResponse = await updateConnector(updateConnectorPayload, sourceId);

      if (updateConnectorResponse?.data) {
        queryClient.invalidateQueries({
          queryKey: ['connectorInfo', sourceId, activeWorkspaceId],
        });

        showToast({
          status: CustomToastStatus.Success,
          title: 'Success!',
          description: 'Source details updated successfully!',
          position: 'bottom-right',
          isClosable: true,
        });
      } else {
        if (updateConnectorResponse.errors) {
          apiError(updateConnectorResponse.errors);
        }
      }
    } catch (error) {
      errorToast(`Something went wrong while updating the source.`, true, error, true);
    }
  };

  useEffect(() => {
    if (catalogData?.data) {
      if (catalogData?.data?.attributes?.catalog?.streams[0]?.json_schema?.input) {
        setInputSchemaFields(
          catalogData?.data?.attributes?.catalog?.streams[0]?.json_schema?.input,
        );
      }

      if (catalogData?.data?.attributes?.catalog?.streams[0]?.json_schema?.output) {
        setOutputSchemaFields(
          catalogData?.data?.attributes?.catalog?.streams[0]?.json_schema?.output,
        );
      }
    }
  }, [catalogData]);

>>>>>>> 11791c77 (feat(CE): added Edit Details Modal (#791))
  if (isConnectorInfoLoading || isConnectorDefinitionLoading) return <Loader />;

  const EDIT_SOURCE_STEPS: Step[] = [
    {
      name: 'Sources',
      url: '/setup/sources',
    },
    {
      name: connectorInfoResponse?.data?.attributes?.name || '',
      url: '',
    },
  ];

  const generatedSchema = generateUiSchema(connectorSchema?.connection_specification as RJSFSchema);

  return (
    <Box width='100%' display='flex' justifyContent='center'>
      <ContentContainer>
        <TopBar
          name={connectorInfoResponse?.data?.attributes?.name || ''}
          breadcrumbSteps={EDIT_SOURCE_STEPS}
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
<<<<<<< HEAD
              <SourceActions connectorType='sources' />
=======
              <RoleAccess location='connector' type='item' action={UserActions.Delete}>
                <ConnectorActions
                  connectorType='source'
                  initialValues={{
                    name: connectorInfo?.attributes.name ?? '',
                    description: connectorInfo?.attributes.description ?? '',
                  }}
                  onSave={(values) => handleUpdate(values)}
                />
              </RoleAccess>
>>>>>>> 11791c77 (feat(CE): added Edit Details Modal (#791))
            </Box>
          }
        />

        <Box
          backgroundColor='gray.100'
          padding='24px'
          borderWidth='thin'
          borderRadius='8px'
          marginBottom='100px'
          border='1px'
          borderColor='gray.400'
        >
          <JSONSchemaForm
            schema={connectorSchema?.connection_specification as RJSFSchema}
            uiSchema={generatedSchema}
            formData={formData}
            onSubmit={(formData: FormData) => handleOnTestClick(formData)}
            onChange={(formData: FormData) => setFormData(formData)}
          >
            <FormFooter
              ctaName='Save Changes'
              ctaType='button'
              isCtaDisabled={!testedFormData}
              onCtaClick={mutate}
              isCtaLoading={isEditLoading}
              isAlignToContentContainer
              isDocumentsSectionRequired
              isContinueCtaRequired
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
          </JSONSchemaForm>
        </Box>
      </ContentContainer>
    </Box>
  );
};

export default EditSource;
