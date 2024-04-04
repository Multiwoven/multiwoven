import ContentContainer from '@/components/ContentContainer';
import TopBar from '@/components/TopBar';
import { Box } from '@chakra-ui/react';
import { FiPlus } from 'react-icons/fi';
import { Outlet, useNavigate } from 'react-router-dom';
import { useQuery } from '@tanstack/react-query';
import { getAllModels } from '@/services/models';
import Loader from '@/components/Loader';
import ModelTable from './ModelTable';
import NoModels from '../NoModels';

const ModelsList = (): JSX.Element | null => {
  const navigate = useNavigate();

  const handleOnRowClick = (row: any) => {
    navigate(row?.id);
  };

  const { data, isLoading } = useQuery({
    queryKey: ['models'],
    queryFn: () => getAllModels(),
    refetchOnMount: true,
    refetchOnWindowFocus: false,
  });

  if (isLoading && !data) return <Loader />;
  if (data?.data?.length === 0) return <NoModels />;

  return (
    <Box width='100%' display='flex' flexDirection='column' alignItems='center'>
      <ContentContainer>
        <TopBar
          name={'Models'}
          ctaName='Add Model'
          ctaIcon={<FiPlus color='gray.100' />}
          ctaButtonVariant='solid'
          onCtaClicked={() => navigate('new')}
          isCtaVisible
        />
        <Box>
          {isLoading || !data ? (
            <Loader />
          ) : (
            <ModelTable
              handleOnRowClick={handleOnRowClick}
              modelData={data}
              isLoading={isLoading}
            />
          )}
        </Box>
        <Outlet />
      </ContentContainer>
    </Box>
  );
};

export default ModelsList;
