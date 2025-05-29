import ContentContainer from '@/components/ContentContainer';
import ModelTable from '@/components/ModelTable';
import { SteppedFormContext } from '@/components/SteppedForm/SteppedForm';
import { getAllModels, AllDataModels } from '@/services/models';
import { Box } from '@chakra-ui/react';
import { useContext } from 'react';
import useFilters from '@/hooks/useFilters';
import Pagination from '@/components/EnhancedPagination';
import useQueryWrapper from '@/hooks/useQueryWrapper';
import Loader from '@/components/Loader';
import NoModels from '@/views/Models/NoModels';

const SelectModel = (): JSX.Element => {
  const { stepInfo, handleMoveForward } = useContext(SteppedFormContext);
  const { filters, updateFilters } = useFilters({ page: '1' });

  const { data, isLoading } = useQueryWrapper(
    ['models', 'list', filters.page],
    () => getAllModels({ type: AllDataModels, page: filters.page as string, perPage: '10' }),
    {
      refetchOnMount: true,
      refetchOnWindowFocus: false,
    },
  );

  const handleOnRowClick = (data: unknown) => {
    handleMoveForward(stepInfo?.formKey as string, data);
  };

  if (isLoading && !data) return <Loader />;
  
  if (!isLoading && (!data?.data || data.data.length === 0)) return <NoModels />;

  return (
    <Box width='100%' display='flex' justifyContent='center'>
      <ContentContainer>
        <ModelTable handleOnRowClick={handleOnRowClick} models={data?.data} />
        {data?.links && data.data && data.data.length > 0 && (
          <Box display='flex' justifyContent='center' mt='20px'>
            <Pagination
              links={data.links}
              currentPage={filters.page ? Number(filters.page) : 1}
              handlePageChange={(page) => updateFilters({ ...filters, page: page.toString() })}
            />
          </Box>
        )}
      </ContentContainer>
    </Box>
  );
};

export default SelectModel;
