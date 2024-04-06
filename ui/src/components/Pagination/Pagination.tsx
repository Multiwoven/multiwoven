import { Stack, Box, Text, Button } from '@chakra-ui/react';

import { MdKeyboardArrowRight, MdKeyboardArrowLeft } from 'react-icons/md';

enum PAGE_CHANGE_BUTTON_TYPE {
  PREVIOUS = 'previous',
  NEXT = 'next',
}

const PageChangeButton = ({
  type,
  handlePageChange,
  isEnabled,
}: {
  type: PAGE_CHANGE_BUTTON_TYPE;
  handlePageChange: () => void;
  isEnabled: boolean;
}) => (
  <Button
    height='24px'
    width='24px'
    borderRadius='6px'
    borderStyle='solid'
    borderWidth='1px'
    borderColor='gray.300'
    display='flex'
    justifyContent='center'
    alignItems='center'
    backgroundColor='gray.300'
    onClick={handlePageChange}
    minWidth='0'
    padding={0}
    _hover={{ backgroundColor: 'gray.300' }}
    isDisabled={isEnabled ? false : true}
  >
    {type === PAGE_CHANGE_BUTTON_TYPE.PREVIOUS ? (
      <MdKeyboardArrowLeft color='#98A2B3' />
    ) : (
      <MdKeyboardArrowRight color='#98A2B3' />
    )}
  </Button>
);

type PaginationProps = {
  currentPage: number;
  isPrevPageEnabled: boolean;
  isNextPageEnabled: boolean;
  handlePrevPage: () => void;
  handleNextPage: () => void;
};

const Pagination = ({
  currentPage,
  isPrevPageEnabled,
  isNextPageEnabled,
  handlePrevPage,
  handleNextPage,
}: PaginationProps) => (
  <Box width='352px'>
    <Stack direction='row' justify='end' spacing={4} alignItems='center' gap='6px'>
      <PageChangeButton
        isEnabled={isPrevPageEnabled}
        type={PAGE_CHANGE_BUTTON_TYPE.PREVIOUS}
        handlePageChange={handlePrevPage}
      />
      <Box
        height='24px'
        width='24px'
        borderRadius='6px'
        borderStyle='solid'
        borderWidth='1px'
        borderColor='gray.400'
        display='flex'
        justifyContent='center'
        alignItems='center'
        color='black.200'
      >
        <Text size='xs' fontWeight='semibold'>
          {currentPage}
        </Text>
      </Box>
      <PageChangeButton
        isEnabled={isNextPageEnabled}
        type={PAGE_CHANGE_BUTTON_TYPE.NEXT}
        handlePageChange={handleNextPage}
      />
    </Stack>
  </Box>
);

export default Pagination;
