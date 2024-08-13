import { Box } from '@chakra-ui/react';
import { FiPlus } from 'react-icons/fi';
import TopBar from '@/components/TopBar';
import { useNavigate } from 'react-router-dom';

import ContentContainer from '@/components/ContentContainer';
import { useQuery } from '@tanstack/react-query';
import { DESTINATIONS_LIST_QUERY_KEY } from '../../constant';
import { getUserConnectors } from '@/services/connectors';
import NoConnectors from '../../NoConnectors';
import Loader from '@/components/Loader';
<<<<<<< HEAD
=======
import { useStore } from '@/stores';
import useCustomToast from '@/hooks/useCustomToast';
import { CustomToastStatus } from '@/components/Toast/index';
import titleCase from '@/utils/TitleCase';
import { useRoleDataStore } from '@/enterprise/store/useRoleDataStore';
import { UserActions } from '@/enterprise/types';
import { hasActionPermission } from '@/enterprise/utils/accessControlPermission';
import useProtectedNavigate from '@/enterprise/hooks/useProtectedNavigate';
import DataTable from '@/components/DataTable';
import { ConnectorsListColumns } from '@/views/Connectors/ConnectorsListColumns/ConnectorsListColumns';
>>>>>>> a6ab37fc (refactor(CE): created common connector lists component)

const DestinationsList = (): JSX.Element | null => {
  const navigate = useNavigate();

  const { data, isLoading } = useQuery({
    queryKey: DESTINATIONS_LIST_QUERY_KEY,
    queryFn: () => getUserConnectors('destination'),
    refetchOnMount: true,
    refetchOnWindowFocus: false,
  });

  if (isLoading && !data) return <Loader />;

  if (data?.data.length === 0) return <NoConnectors connectorType='destination' />;

  return (
    <Box width='100%' display='flex' flexDirection='column' alignItems='center'>
      <ContentContainer>
        <TopBar
          name='Destinations'
          ctaName='Add Destination'
          ctaIcon={<FiPlus color='gray.100' />}
          onCtaClicked={() => navigate('new')}
          ctaButtonVariant='solid'
          ctaButtonWidth='fit'
          ctaButtonHeight='40px'
<<<<<<< HEAD
          isCtaVisible
=======
          isCtaVisible={hasPermission}
        />
        <DataTable
          data={data?.data}
          columns={ConnectorsListColumns}
          onRowClick={(row) =>
            navigate({
              to: `/setup/destinations/${row?.original?.id}`,
              location: 'connector',
              action: UserActions.Update,
            })
          }
>>>>>>> a6ab37fc (refactor(CE): created common connector lists component)
        />
        {isLoading || !data ? (
          <Loader />
        ) : (
          <DestinationsTable
            handleOnRowClick={(row) => navigate(`/setup/destinations/${row?.id}`)}
            destinationData={data}
            isLoading={isLoading}
          />
        )}
      </ContentContainer>
    </Box>
  );
};

export default DestinationsList;
