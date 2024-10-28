import { CustomToastStatus } from '@/components/Toast';
import useCustomToast from '@/hooks/useCustomToast';
import { useAPIErrorsToast, useErrorToast } from '@/hooks/useErrorToast';
import { getCatalog } from '@/services/syncs';
import { Button, Tooltip } from '@chakra-ui/react';
import { useState } from 'react';
import { FiLoader, FiRefreshCw } from 'react-icons/fi';

type RefreshModelCatalogProps = {
  source_id: string;
};

const RefreshModelCatalog = ({ source_id }: RefreshModelCatalogProps) => {
  const [isRefreshing, setIsRefreshing] = useState(false);

  const toast = useCustomToast();
  const errorToast = useErrorToast();
  const apiErrorsToast = useAPIErrorsToast();

  const tooltipLabel = isRefreshing
    ? 'Source schema is refreshing...'
    : 'Refresh the source schema if any tables are missing.';

  const handleRefresh = async () => {
    setIsRefreshing(true);
    try {
      const data = await getCatalog(source_id, true);
      if (data?.errors) {
        apiErrorsToast(data.errors);
      }
      if (data?.data) {
        toast({
          title: 'Success!',
          description: 'Source schema refreshed successfully',
          status: CustomToastStatus.Success,
          isClosable: true,
          position: 'bottom-right',
        });
      }
    } catch (error) {
      errorToast('An error occurred while refreshing the source catalog.', true, null, true);
    } finally {
      setIsRefreshing(false);
    }
  };

  return (
    <Tooltip
      hasArrow
      label={tooltipLabel}
      fontSize='xs'
      placement='top'
      backgroundColor='black.500'
      color='gray.100'
      borderRadius='6px'
      padding='8px'
    >
      <Button
        variant='shell'
        minWidth='0'
        width='auto'
        fontSize='12px'
        height='32px'
        paddingX={3}
        borderWidth={1}
        borderStyle='solid'
        borderColor='gray.500'
        onClick={handleRefresh}
        isDisabled={isRefreshing}
      >
        {isRefreshing ? (
          <FiLoader height='14px' width='14px' />
        ) : (
          <FiRefreshCw height='14px' width='14px' />
        )}
      </Button>
    </Tooltip>
  );
};

export default RefreshModelCatalog;
