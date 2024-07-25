import { Box } from '@chakra-ui/react';
import { SYNCS_LIST_QUERY_KEY } from '@/views/Activate/Syncs/constants';
import { useNavigate, useParams } from 'react-router-dom';
import { useQuery, useQueryClient } from '@tanstack/react-query';
import { editSync, getCatalog, getSyncById } from '@/services/syncs';
import Loader from '@/components/Loader';
import React, { useEffect, useState } from 'react';
import SelectStreams from '@/views/Activate/Syncs/SyncForm/ConfigureSyncs/SelectStreams';
import MapFields from '../SyncForm/ConfigureSyncs/MapFields';
import { getConnectorInfo } from '@/services/connectors';
import { CustomToastStatus } from '@/components/Toast/index';
import useCustomToast from '@/hooks/useCustomToast';

import {
  CreateSyncPayload,
  DiscoverResponse,
  FinalizeSyncFormFields,
  SchemaMode,
  Stream,
} from '@/views/Activate/Syncs/types';
import ScheduleForm from './ScheduleForm';
import { FormikProps, useFormik } from 'formik';
import SourceFormFooter from '@/views/Connectors/Sources/SourcesForm/SourceFormFooter';
import { FieldMap as FieldMapType } from '@/views/Activate/Syncs/types';
import MapCustomFields from '../SyncForm/ConfigureSyncs/MapCustomFields';
import { useStore } from '@/stores';
import titleCase from '@/utils/TitleCase';

const EditSync = (): JSX.Element | null => {
  const [selectedStream, setSelectedStream] = useState<Stream | null>(null);
  const [isEditLoading, setIsEditLoading] = useState<boolean>(false);
  const [configuration, setConfiguration] = useState<FieldMapType[] | null>(null);
  const [selectedSyncMode, setSelectedSyncMode] = useState('');
  const [cursorField, setCursorField] = useState('');
  const activeWorkspaceId = useStore((state) => state.workspaceId);
  const [refresh, setRefresh] = useState(false);

  const { syncId } = useParams();
  const showToast = useCustomToast();
  const navigate = useNavigate();
  const queryClient = useQueryClient();

  const {
    data: syncFetchResponse,
    isLoading,
    isError,
  } = useQuery({
    queryKey: ['sync', syncId, activeWorkspaceId],
    queryFn: () => getSyncById(syncId as string),
    refetchOnMount: true,
    refetchOnWindowFocus: false,
    enabled: !!syncId && activeWorkspaceId > 0,
  });

  const syncData = syncFetchResponse?.data?.attributes;

  const { data: destinationFetchResponse, isLoading: isConnectorInfoLoading } = useQuery({
    queryKey: ['sync', 'destination', syncData?.destination.id, activeWorkspaceId],
    queryFn: () => getConnectorInfo(syncData?.destination.id as string),
    refetchOnMount: true,
    refetchOnWindowFocus: false,
    enabled: !!syncData?.destination.id && activeWorkspaceId > 0,
  });

  const { data: catalogData, refetch } = useQuery({
    queryKey: ['syncs', 'catalog', syncData?.destination.id, activeWorkspaceId],
    queryFn: () => getCatalog(syncData?.destination?.id as string, refresh),
    enabled: !!syncData?.destination.id && activeWorkspaceId > 0,
    refetchOnMount: false,
    refetchOnWindowFocus: false,
  });

  const formik: FormikProps<FinalizeSyncFormFields> = useFormik({
    initialValues: {
      sync_mode: 'full_refresh',
      sync_interval: 0,
      sync_interval_unit: 'minutes',
      schedule_type: 'interval',
      cron_expression: '',
    },
    onSubmit: async (data) => {
      setIsEditLoading(true);
      try {
        if (
          destinationFetchResponse?.data.id &&
          syncData?.model.id &&
          syncData?.source.id &&
          configuration
        ) {
          const payload: CreateSyncPayload = {
            sync: {
              configuration,
              destination_id: destinationFetchResponse?.data.id,
              model_id: syncData?.model.id,
              schedule_type: data.schedule_type,
              source_id: syncData?.source.id,
              stream_name: syncData?.stream_name,
              sync_interval: data.sync_interval,
              sync_interval_unit: data.sync_interval_unit,
              sync_mode: selectedSyncMode,
              cursor_field: cursorField,
              cron_expression: data?.cron_expression,
            },
          };

          const editSyncResponse = await editSync(payload, syncId as string);
          if (editSyncResponse?.data?.attributes) {
            showToast({
              title: 'Sync updated successfully',
              status: CustomToastStatus.Success,
              duration: 3000,
              isClosable: true,
              position: 'bottom-right',
            });

            queryClient.removeQueries({
              queryKey: SYNCS_LIST_QUERY_KEY,
            });

            navigate('/activate/syncs');
            return;
          } else {
            editSyncResponse.errors?.forEach((error) => {
              showToast({
                duration: 5000,
                isClosable: true,
                position: 'bottom-right',
                colorScheme: 'red',
                status: CustomToastStatus.Warning,
                title: titleCase(error.detail),
              });
            });
          }
        }
      } catch {
        showToast({
          status: CustomToastStatus.Error,
          title: 'Error!!',
          description: 'Something went wrong while editing the sync',
          position: 'bottom-right',
          isClosable: true,
        });
      } finally {
        setIsEditLoading(false);
      }
    },
  });

  const handleRefreshCatalog = () => {
    setRefresh(true);
  };

  useEffect(() => {
    if (refresh) {
      refetch();
      setRefresh(false);
    }
  }, [refresh]);

  useEffect(() => {
    if (isError) {
      showToast({
        status: CustomToastStatus.Error,
        title: 'Error!!',
        description: 'Something went wrong',
        position: 'bottom-right',
        isClosable: true,
      });
    }
  }, [isError]);

  useEffect(() => {
    if (syncFetchResponse) {
      formik.setValues({
        sync_interval: syncData?.sync_interval ?? 0,
        sync_interval_unit: syncData?.sync_interval_unit ?? 'minutes',
        sync_mode: syncData?.sync_mode ?? 'full_refresh',
        schedule_type: syncData?.schedule_type ?? 'interval',
        cron_expression: syncData?.cron_expression ?? '',
      });

      if (Array.isArray(syncFetchResponse?.data?.attributes?.configuration)) {
        setConfiguration(syncFetchResponse.data.attributes.configuration);
      } else {
        const transformedConfigs = Object.entries(
          syncFetchResponse?.data?.attributes?.configuration || {},
        ).map(([model, destination]) => {
          return {
            from: model,
            to: destination,
            mapping_type: 'standard',
          };
        });
        setConfiguration(transformedConfigs);
      }
      setSelectedSyncMode(syncData?.sync_mode ?? 'full_refresh');
      setCursorField(syncData?.cursor_field || '');
    }
  }, [syncFetchResponse]);

  const handleOnStreamsLoad = (catalog: DiscoverResponse) => {
    const { streams } = catalog.data.attributes.catalog;
    const selectedStream = streams.find(({ name }) => name === syncData?.stream_name);
    if (selectedStream) {
      setSelectedStream(selectedStream);
    }
  };

  const handleOnConfigChange = (config: FieldMapType[]) => {
    setConfiguration(config);
  };

  useEffect(() => {
    if (catalogData) {
      handleOnStreamsLoad(catalogData);
    }
  }, [catalogData]);

  const streams = catalogData?.data?.attributes?.catalog?.streams || [];

  return (
    <form onSubmit={formik.handleSubmit} style={{ backgroundColor: 'gray.200' }}>
      <Box width='100%' pt='20px'>
        {isLoading || isConnectorInfoLoading || !syncData ? <Loader /> : null}
        {syncData && destinationFetchResponse?.data ? (
          <React.Fragment>
            {/* will be changed to get schema mode in the sync data in the future */}
            <>
              <SelectStreams
                model={syncData?.model}
                destination={destinationFetchResponse?.data}
                isEdit
                setSelectedSyncMode={setSelectedSyncMode}
                selectedSyncMode={selectedSyncMode}
                selectedStreamName={syncData?.stream_name}
                selectedCursorField={cursorField}
                setCursorField={setCursorField}
                streams={streams}
              />
              {catalogData?.data.attributes.catalog.schema_mode === SchemaMode.schemaless ? (
                <MapCustomFields
                  model={syncData?.model}
                  destination={destinationFetchResponse?.data}
                  handleOnConfigChange={handleOnConfigChange}
                  data={configuration}
                  isEdit
                  configuration={configuration}
                  stream={selectedStream}
                />
              ) : (
                <MapFields
                  model={syncData?.model}
                  destination={destinationFetchResponse?.data}
                  stream={selectedStream}
                  handleOnConfigChange={handleOnConfigChange}
                  data={configuration}
                  isEdit
                  configuration={configuration}
                  handleRefreshCatalog={handleRefreshCatalog}
                />
              )}
            </>

            <ScheduleForm formik={formik} isEdit />
          </React.Fragment>
        ) : null}
        <SourceFormFooter
          ctaName='Save Changes'
          ctaType='submit'
          isCtaLoading={isEditLoading}
          isAlignToContentContainer
          isDocumentsSectionRequired
          isContinueCtaRequired
          isBackRequired
          navigateToListScreen
          listScreenUrl='/activate/syncs'
        />
      </Box>
    </form>
  );
};

export default EditSync;
