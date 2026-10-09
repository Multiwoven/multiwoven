import EmptyVectorTables from '@/assets/images/empty-vector-tables.svg';
import { Box, Image, Text, Button } from '@chakra-ui/react';
import { FiPlus } from 'react-icons/fi';

const RowsNotFound = ({
  onOpen,
  showActionButton = true,
}: {
  onOpen: () => void;
  showActionButton?: boolean;
}) => (
  <Box
    display='flex'
    w='fit-content'
    mx='auto'
    flexDirection='column'
    alignItems='center'
    padding='20px'
  >
    <Image src={EmptyVectorTables} alt='empty-table' w='320px' h='160px' />
    <Text fontSize='xl' mx='auto' fontWeight='semibold'>
      No tables created
    </Text>
    <Text size='sm' color='black.100' fontWeight={400} marginTop='4px'>
      Define and create a new vector store table
    </Text>
    {showActionButton && (
      <Button
        data-testid='data-store-create-table-button'
        variant='solid'
        leftIcon={<FiPlus />}
        onClick={onOpen}
        fontSize='16px'
        paddingX='16px'
        marginTop='16px'
        minWidth={0}
        width='auto'
      >
        <Text size='sm'>Create Table</Text>
      </Button>
    )}
  </Box>
);

export default RowsNotFound;
