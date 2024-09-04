import { testSync } from '@/services/syncs';
import useApiMutation from '../useAPIMutation';
import { MessageResponse } from '@/services/authentication';

const useTestSync = (syncId: string) => {
  const { isSubmitting, triggerMutation: triggerTestSync } = useApiMutation<
    MessageResponse,
    string
  >({
    mutationFn: (id: string) => testSync(id),
    successMessage: 'Test sync triggered successfully!',
    errorMessage: 'Failed to trigger test sync',
  });

  const runTestSync = async () => {
    if (syncId) {
      await triggerTestSync(syncId);
    }
  };

  return { isSubmitting, runTestSync };
};

export default useTestSync;
