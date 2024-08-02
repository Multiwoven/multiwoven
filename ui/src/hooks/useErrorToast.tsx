import { useCallback, useEffect } from 'react';
import useCustomToast from '@/hooks/useCustomToast';
import { CustomToastStatus } from '@/components/Toast';
import { ErrorResponse } from '@/services/common';

export const useErrorToast = (isError: boolean, data: any, isFetched: boolean, message: string) => {
  const showToast = useCustomToast();

  useEffect(() => {
    if (isError || (!data && isFetched)) {
      showToast({
        title: `Error: ${message}`,
        description: message,
        status: CustomToastStatus.Error,
        position: 'bottom-right',
      });
    }
  }, [isError, data, isFetched, showToast, message]);
};

export const useAPIErrorsToast = () => {
  const showToast = useCustomToast();

  const showAPIErrorsToast = useCallback(
    (errors: ErrorResponse[]) => {
      errors.forEach((error) => {
        showToast({
          status: CustomToastStatus.Warning,
          title: error.detail,
          position: 'bottom-right',
          isClosable: true,
        });
      });
    },
    [showToast],
  );

  return showAPIErrorsToast;
};
