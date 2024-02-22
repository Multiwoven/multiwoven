import {
  Box,
  Button,
  Popover,
  PopoverBody,
  PopoverContent,
  PopoverTrigger,
  Text,
  useToast,
} from '@chakra-ui/react';
import { FiMoreHorizontal, FiTrash2 } from 'react-icons/fi';
import { useNavigate, useParams } from 'react-router-dom';
import { deleteSync } from '@/services/syncs';

const SyncActions = () => {
  const toast = useToast();
  const navigate = useNavigate();
  const { syncId } = useParams();

  const handleDeleteSync = async () => {
    try {
      await deleteSync(syncId as string);
      toast({
        title: 'Sync deleted successfully',
        isClosable: true,
        duration: 5000,
        status: 'success',
        position: 'bottom-right',
      });
      navigate('/activate/syncs');
      return;
    } catch {
      toast({
        status: 'error',
        title: 'Error!!',
        description: 'Something went wrong while deleting the sync',
        position: 'bottom-right',
        isClosable: true,
      });
    }
  };

  return (
    <>
      <Popover closeOnEsc>
        <PopoverTrigger>
          <Box>
            <Box
              cursor='pointer'
              bgColor='gray.300'
              px={3}
              ml={6}
              _hover={{ bgColor: 'gray.400' }}
              border='1px'
              borderColor='gray.500'
              borderStyle='solid'
              borderRadius='6px'
              height='32px'
              width='32px'
              display='flex'
              justifyContent='center'
              alignItems='center'
            >
              <Box>
                <FiMoreHorizontal />
              </Box>
            </Box>
          </Box>
        </PopoverTrigger>
        <PopoverContent
          w='182px'
          border='1px'
          borderColor='gray.400'
          borderStyle='solid'
          mr={8}
        >
          <PopoverBody margin={0} p={0}>
            <Button
              _hover={{ bgColor: 'gray.200' }}
              w='100%'
              py={3}
              px={2}
              display='flex'
              flexDir='row'
              alignItems='center'
              color={'red.600'}
              rounded='lg'
              onClick={handleDeleteSync}
              as='button'
              justifyContent='start'
              border={0}
              variant='shell'
            >
              <FiTrash2 color='#F45757' />
              <Text size='sm' fontWeight='medium' ml={3} color='#C82727'>
                Delete
              </Text>
            </Button>
          </PopoverBody>
        </PopoverContent>
      </Popover>
    </>
  );
};

export default SyncActions;
