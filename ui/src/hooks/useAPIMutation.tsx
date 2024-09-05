import { useState } from 'react';
import { useMutation } from '@tanstack/react-query';
import { ApiResponse } from '@/services/common';
import useCustomToast from '@/hooks/useCustomToast';
import { CustomToastStatus } from '@/components/Toast/index';
import { useAPIErrorsToast, useErrorToast } from './useErrorToast';

type UseApiMutationOptions<TData, TVariables> = {
  mutationFn: (variables: TVariables) => Promise<ApiResponse<TData>>;
  successMessage: string;
  errorMessage: string;
  onSuccessCallback?: (result: ApiResponse<TData>) => void;
};

const useApiMutation = <TData, TVariables>({
  mutationFn,
  successMessage,
  errorMessage,
  onSuccessCallback,
}: UseApiMutationOptions<TData, TVariables>) => {
  const [isSubmitting, setIsSubmitting] = useState<boolean>(false);
  const showToast = useCustomToast();
  const apiErrorToast = useAPIErrorsToast();
  const errorToast = useErrorToast();

  const mutation = useMutation<ApiResponse<TData>, Error, TVariables>({
    mutationFn,
    onSuccess: (result) => {
      if (result?.errors && result?.errors.length > 0) {
        apiErrorToast(result.errors);
      } else {
        showToast({
          status: CustomToastStatus.Success,
          title: successMessage,
          position: 'bottom-right',
          isClosable: true,
        });
        onSuccessCallback?.(result);
      }
      setIsSubmitting(false);
    },
    onError: () => {
      errorToast(errorMessage, true, null, true);
      setIsSubmitting(false);
    },
  });

  const triggerMutation = async (variables: TVariables) => {
    setIsSubmitting(true);
    await mutation.mutateAsync(variables);
  };

  return { isSubmitting, triggerMutation };
};

export default useApiMutation;
