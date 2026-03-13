import { Step } from '@/components/Breadcrumbs/types';
import ContentContainer from '@/components/ContentContainer';
import EntityItem from '@/components/EntityItem';
import Loader from '@/components/Loader';
import TopBar from '@/components/TopBar';
import RoleAccess from '@/enterprise/components/RoleAccess';
import useProtectedNavigate from '@/enterprise/hooks/useProtectedNavigate';
import { UserActions } from '@/enterprise/types';
import useCustomToast from '@/hooks/useCustomToast';
import { useStore } from '@/stores';
import PageNotFound from '@/views/PageNotFound';

import { Box, Text, Divider } from '@chakra-ui/react';
import dayjs from 'dayjs';
import { useParams } from 'react-router-dom';

import MapHarvest from '../AIModelsForm/DefineHarvest/MapHarvest';
import FormFooter from '@/components/FormFooter';
import { HarvestFieldMap } from '../types';
import { FormEvent, useEffect, useState } from 'react';
import { CustomToastStatus } from '@/components/Toast';
import { putModelById } from '@/services/models';

import AIModelActions from './AIModelActions';
import { getAICatalog } from '@/services/syncs';
import { useQuery } from '@tanstack/react-query';
import { useAPIErrorsToast } from '@/hooks/useErrorToast';
import { UpdateModelPayload } from '@/views/Models/ViewModel/types';
import useHarvestFieldMap from '@/enterprise/hooks/useHarvestFieldMap.tsx';
import useModelData from '@/hooks/models/useModelData';

const ViewAIModel = () => {
  const [loading, setIsLoading] = useState(false);

  const params = useParams();
  const showToast = useCustomToast();
  const apiError = useAPIErrorsToast();
  const navigate = useProtectedNavigate();

  const { harvestFieldMap, setHarvestFieldMap, appendField, removeField, updateField } =
    useHarvestFieldMap();

  const activeWorkspaceId = useStore((state) => state.workspaceId);

  const aiModelId = params.id || '';

  const { data: aiModelData, isLoading, invalidateQuery } = useModelData(aiModelId);

  const connector_id = aiModelData?.data?.attributes.connector.id;

  const { data: aiSourceCatalog, isLoading: aiSourceCatalogIsLoading } = useQuery({
    queryKey: ['modelByID', activeWorkspaceId, connector_id],
    queryFn: () => getAICatalog(connector_id || ''),
    refetchOnMount: true,
    refetchOnWindowFocus: true,
    retryOnMount: true,
    refetchOnReconnect: true,

    enabled: connector_id !== undefined,
  });

  if (aiSourceCatalog?.errors) {
    apiError(aiSourceCatalog.errors);
  }

  const EDIT_AI_MODEL_FORM_STEPS: Step[] = [
    {
      name: 'Models',
      url: '/define/models',
    },
    {
      name: aiModelData?.data?.attributes.name || 'AI/ML Model',
      url: '',
    },
  ];

  const handleOnUpdate = async (
    e?: FormEvent,
    values?: { name: string; description: string },
    preventNavigate?: boolean,
  ) => {
    e?.preventDefault();
    try {
      setIsLoading(true);
      const harvesters: HarvestFieldMap[] = harvestFieldMap.map((field) => ({
        selector: field.selector,
        value: field.value,
        preprocess: field.preprocess,
        method: field.method,
      }));

      const payload: UpdateModelPayload = {
        model: {
          name: values ? values.name : aiModelData?.data?.attributes.name || '',
          description: values
            ? values.description
            : aiModelData?.data?.attributes.description || '',
          connector_id: connector_id || '',
          query_type: 'ai_ml',
          primary_key: 'unknown',
          configuration: { harvesters },
        },
      };

      const data = await putModelById(aiModelId, payload);

      if (data.data) {
        showToast({
          title: 'Success!',
          description: 'AI/ML model has been updated successfully',
          status: CustomToastStatus.Success,
          isClosable: true,
          duration: 5000,
          position: 'bottom-right',
        });

        invalidateQuery();

        if (!preventNavigate) {
          navigate({ to: '/define/models', location: 'model', action: UserActions.Read });
        }
      }
      if (data.errors) {
        apiError(data.errors);
      }
    } catch {
      showToast({
        status: CustomToastStatus.Error,
        title: 'An error occurred.',
        description: 'Something went wrong while creating the AI/ML Model.',
        position: 'bottom-right',
        isClosable: true,
      });
    } finally {
      setIsLoading(false);
    }
  };

  const harvesters = aiModelData?.data?.attributes.configuration?.harvesters;

  useEffect(() => {
    setHarvestFieldMap(harvesters || []);
  }, [harvesters]);

  if (isLoading || !aiModelData || aiSourceCatalogIsLoading || !aiSourceCatalog) {
    return <Loader />;
  }

  if (!aiModelData.data || !aiSourceCatalog.data) return <PageNotFound />;

  return (
    <Box width='100%' display='flex' justifyContent='center'>
      <ContentContainer>
        <TopBar
          name={aiModelData.data.attributes.name}
          breadcrumbSteps={EDIT_AI_MODEL_FORM_STEPS}
          extra={
            <Box display='flex' alignItems='center'>
              <Box display='flex' alignItems='center' gap='12px'>
                <EntityItem
                  name={aiModelData.data.attributes.connector.name || ''}
                  icon={aiModelData.data.attributes.connector.icon || ''}
                  isAI
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
                {dayjs(aiModelData.data.attributes.updated_at).format('D MMM YYYY')}
              </Text>
              <RoleAccess
                location='model'
                type='item'
                action={UserActions.Update}
                orAction={UserActions.Delete}
              >
                <AIModelActions
                  values={{
                    name: aiModelData.data.attributes.name,
                    description: aiModelData.data.attributes.description,
                  }}
                  onSave={(values, preventNavigate) =>
                    handleOnUpdate(undefined, values, preventNavigate)
                  }
                />
              </RoleAccess>
            </Box>
          }
        />
        <Box
          bgColor='gray.100'
          px={6}
          py={4}
          marginTop={6}
          borderRadius='8px'
          borderColor='gray.400'
          borderWidth='1px'
          display='flex'
          flexDir='column'
          gap='20px'
          mb='60px'
        >
          <Text fontWeight='semibold' size='md'>
            Harvest your data and define how to preprocess
          </Text>
          <Box>
            <form onSubmit={handleOnUpdate}>
              <MapHarvest
                handleAppendField={appendField}
                handleRemoveField={removeField}
                handleFieldChange={updateField}
                fieldMap={harvestFieldMap}
                inputSchema={aiSourceCatalog.data.attributes.catalog.streams[0].json_schema.input}
                isViewModel
              />
              <FormFooter
                isCtaLoading={loading}
                ctaType='submit'
                ctaName='Save Changes'
                isAlignToContentContainer
                isDocumentsSectionRequired
                isContinueCtaRequired
              />
            </form>
          </Box>
        </Box>
      </ContentContainer>
    </Box>
  );
};

export default ViewAIModel;
