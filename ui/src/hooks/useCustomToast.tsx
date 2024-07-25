import { useToast, type UseToastOptions } from '@chakra-ui/react';
import Toast, { CustomToastStatus } from '../components/Toast/index';

type showToastProps = {
  title: string;
  description?: string;
  status?: CustomToastStatus;
};

export default function useCustomToast() {
  const toast = useToast();

  const showToast = ({
    title,
    description,
    status = CustomToastStatus.Default,
    ...toastOptions
  }: Omit<UseToastOptions, 'status'> & showToastProps) => {
    return toast({
      ...toastOptions,
      render: ({ onClose }) => (
        <Toast title={title} description={description} status={status} onClose={onClose} />
      ),
    });
  };

  return showToast;
}
