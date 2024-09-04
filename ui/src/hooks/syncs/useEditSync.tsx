import { useState } from 'react';
import { useNavigate } from 'react-router-dom';
import { useQueryClient } from '@tanstack/react-query';
import { editSync } from '@/services/syncs';
import { CreateSyncPayload, CreateSyncResponse } from '@/views/Activate/Syncs/types';
import { CustomToastStatus } from '@/components/Toast/index';
import useCustomToast from '@/hooks/useCustomToast';
import titleCase from '@/utils/TitleCase';
import { SYNCS_LIST_QUERY_KEY } from '@/views/Activate/Syncs/constants';
import { FinalizeSyncFormFields, FieldMap as FieldMapType } from '@/views/Activate/Syncs/types';

const useEditSync = (
  configuration: FieldMapType[] | null,
  setIsEditLoading: (isLoading: boolean) => void,
  syncData?: CreateSyncResponse['attributes'],
  destinationId?: string,
  modelId?: string,
  sourceId?: string,
) => {
  const navigate = useNavigate();
  const queryClient = useQueryClient();
  const showToast = useCustomToast();
  const [selectedSyncMode, setSelectedSyncMode] = useState('');
  const [cursorField, setCursorField] = useState('');

  const handleSubmit = async (data: FinalizeSyncFormFields, syncId: string) => {
    setIsEditLoading(true);
    try {
      if (destinationId && modelId && sourceId && configuration) {
        const payload: CreateSyncPayload = {
          sync: {
            configuration,
            destination_id: destinationId,
            model_id: modelId,
            schedule_type: data.schedule_type,
            source_id: sourceId,
            stream_name: syncData?.stream_name as string,
            sync_interval: data.sync_interval,
            sync_interval_unit: data.sync_interval_unit,
            sync_mode: selectedSyncMode,
            cursor_field: cursorField,
            cron_expression: data?.cron_expression,
          },
        };

        const editSyncResponse = await editSync(payload, syncId);
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
  };

  return {
    handleSubmit,
    selectedSyncMode,
    setSelectedSyncMode,
    cursorField,
    setCursorField,
  };
};

export default useEditSync;
