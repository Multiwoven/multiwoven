import { LinksType } from '@/services/common';
import { Stack, Box } from '@chakra-ui/react';
import PageNumberItem from './PageNumberItem';
import PageChangeButton, { PAGE_CHANGE_BUTTON_TYPE } from './PageChangeButton';

const getPage = (url: string): number => {
  const parser = new URLSearchParams(new URL(url).search);
  return parseInt(parser.get('page') || '0');
};

export type PaginationProps = {
  links: LinksType;
  currentPage: number;
  handlePageChange: (pageNumber: number) => void;
};

const Pagination = ({ links, currentPage, handlePageChange }: PaginationProps) => {
  const firstPage = getPage(links.first);
  const lastPage = getPage(links.last);

  const renderPageNumbers = () => {
    if (currentPage === firstPage) {
      return (
        <>
          <PageNumberItem
            isActive
            value={currentPage}
            onClick={() => handlePageChange(currentPage)}
          />
          {lastPage > firstPage + 1 && <PageNumberItem isEllipsis />}
          {lastPage !== firstPage && (
            <PageNumberItem value={lastPage} onClick={() => handlePageChange(lastPage)} />
          )}
        </>
      );
    } else if (currentPage === lastPage) {
      return (
        <>
          <PageNumberItem value={firstPage} onClick={() => handlePageChange(firstPage)} />
          {lastPage > firstPage + 1 && <PageNumberItem isEllipsis />}
          <PageNumberItem
            isActive
            value={currentPage}
            onClick={() => handlePageChange(currentPage)}
          />
        </>
      );
    } else {
      return (
        <>
          <PageNumberItem value={firstPage} onClick={() => handlePageChange(firstPage)} />
          {currentPage > firstPage + 1 && <PageNumberItem isEllipsis />}
          <PageNumberItem
            isActive
            value={currentPage}
            onClick={() => handlePageChange(currentPage)}
          />
          {currentPage < lastPage - 1 && <PageNumberItem isEllipsis />}
          <PageNumberItem value={lastPage} onClick={() => handlePageChange(lastPage)} />
        </>
      );
    }
  };

  return (
    <Box
      width='fit-content'
      backgroundColor='gray.300'
      borderColor='gray.400'
      borderRadius='8px'
      borderWidth='1px'
      padding='4px'
    >
      <Stack direction='row' justify='end' spacing={4} alignItems='center' gap='6px'>
        <PageChangeButton
          isEnabled={currentPage !== firstPage}
          type={PAGE_CHANGE_BUTTON_TYPE.FIRST}
          onClick={() => handlePageChange(firstPage)}
        />
        <PageChangeButton
          isEnabled={currentPage !== firstPage}
          type={PAGE_CHANGE_BUTTON_TYPE.PREVIOUS}
          onClick={() => handlePageChange(currentPage - 1)}
        />
        {renderPageNumbers()}
        <PageChangeButton
          isEnabled={currentPage !== lastPage}
          type={PAGE_CHANGE_BUTTON_TYPE.NEXT}
          onClick={() => handlePageChange(currentPage + 1)}
        />
        <PageChangeButton
          isEnabled={currentPage !== lastPage}
          type={PAGE_CHANGE_BUTTON_TYPE.LAST}
          onClick={() => handlePageChange(lastPage)}
        />
      </Stack>
    </Box>
  );
};

export default Pagination;
