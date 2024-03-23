import { useToast, type UseToastOptions } from '@chakra-ui/react';
import Toast, { CustomToastStatus } from '../components/Toast/index';

interface showToastProps {
  title: string;
  status?: CustomToastStatus;
}

export default function useCustomToast() {
  const toast = useToast();

  const showToast = ({
    title,
    status = CustomToastStatus.Default,
    ...toastOptions
  }: Omit<UseToastOptions, 'status'> & showToastProps) => {
    return toast({
      ...toastOptions,
      render: ({ onClose }) => <Toast title={title} status={status} onClose={onClose} />,
    });
  };

  return showToast;
}
