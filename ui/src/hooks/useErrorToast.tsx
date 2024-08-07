import { useCallback } from 'react';
import useCustomToast from '@/hooks/useCustomToast';
import { CustomToastStatus } from '@/components/Toast';
import { ErrorResponse } from '@/services/common';

export const useErrorToast = () => {
  const showToast = useCustomToast();

  const showErrorToast = useCallback(
    (message: string, isError: boolean, data: any, isFetched: boolean) => {
      if (isError || (!data && isFetched)) {
        showToast({
          status: CustomToastStatus.Warning,
          title: message,
          position: 'bottom-right',
          isClosable: true,
        });
      }
    },
    [showToast],
  );

  return showErrorToast;
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
