import { Box } from '@chakra-ui/react';
import { ConnectorListResponse } from '../types';
import Pagination from '@/components/EnhancedPagination';

type ConnectorListPaginationProps = {
  data: ConnectorListResponse | undefined;
  onPageSelect: (page: number) => void;
  filters: {
    page: string;
  };
};

const ConnectorListPagination = ({ data, onPageSelect, filters }: ConnectorListPaginationProps) => {
  if (data?.links && (data.links.prev || data.links.next)) {
    return (
      <Box display='flex' justifyContent='center'>
        <Pagination
          links={data?.links}
          currentPage={filters.page ? Number(filters.page) : 1}
          handlePageChange={onPageSelect}
        />
      </Box>
    );
  }
  return null;
};

export default ConnectorListPagination;
