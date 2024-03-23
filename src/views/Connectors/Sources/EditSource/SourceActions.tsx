import {
  Box,
  Button,
  Popover,
  PopoverBody,
  PopoverContent,
  PopoverTrigger,
  Text,
} from '@chakra-ui/react';
import { FiMoreHorizontal, FiTrash2 } from 'react-icons/fi';
import { useNavigate, useParams } from 'react-router-dom';
import { deleteConnector } from '@/services/connectors';
import { CustomToastStatus } from '@/components/Toast/index';
import useCustomToast from '@/hooks/useCustomToast';
const SourceActions = ({ connectorType }: { connectorType: string }) => {
  const showToast = useCustomToast();
  const navigate = useNavigate();
  const { sourceId, destinationId } = useParams();

  const handleDeleteConnector = async () => {
    try {
      const connectorId = connectorType === 'sources' ? sourceId : destinationId;
      await deleteConnector(connectorId as string);
      showToast({
        title: 'Connector deleted successfully',
        isClosable: true,
        duration: 5000,
        status: CustomToastStatus.Success,
        position: 'bottom-right',
      });
      navigate(`/setup/${connectorType}`);
      return;
    } catch {
      showToast({
        status: CustomToastStatus.Error,
        title: 'Error!!',
        description: 'Something went wrong while deleting the connector',
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
        <PopoverContent w='182px' border='1px' borderColor='gray.400' borderStyle='solid' mr={8}>
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
              onClick={handleDeleteConnector}
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

export default SourceActions;
