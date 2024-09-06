import { useState } from 'react';
import { triggerManualSync, cancelManualSyncSchedule } from '@/services/syncs';
import { TriggerManualSyncPayload, CreateSyncResponse } from '@/views/Activate/Syncs/types';
import { APIRequestMethod } from '@/services/common';
import useApiMutation from '../useAPIMutation';

type TriggerSyncVariables = {
  payload: TriggerManualSyncPayload;
  method: APIRequestMethod;
};

const useManualSync = (syncId: string) => {
  const [showCancelSync, setShowCancelSync] = useState(false);

  const { isSubmitting, triggerMutation: triggerSync } = useApiMutation<
    CreateSyncResponse,
    TriggerSyncVariables
  >({
    mutationFn: ({ payload, method }: TriggerSyncVariables) => triggerManualSync(payload, method),
    successMessage: 'Sync started successfully!',
    errorMessage: 'Failed to start sync',
    onSuccessCallback: () => {
      setShowCancelSync(true); // Update the state to show the cancel option
    },
  });

  const { triggerMutation: cancelSync } = useApiMutation<CreateSyncResponse, string>({
    mutationFn: (id) => cancelManualSyncSchedule(id),
    successMessage: 'Sync run cancelled successfully!',
    errorMessage: 'Failed to cancel sync run',
    onSuccessCallback: () => {
      setShowCancelSync(false); // Update the state to hide the cancel option
    },
  });

  const runSyncNow = async (method: APIRequestMethod) => {
    if (syncId) {
      const payload: TriggerManualSyncPayload = {
        schedule_sync: {
          sync_id: parseInt(syncId, 10),
        },
      };

      if (method === 'post') {
        await triggerSync({ payload, method });
      } else {
        await cancelSync(syncId);
      }
    }
  };

  return { isSubmitting, runSyncNow, showCancelSync, setShowCancelSync };
};

export default useManualSync;
