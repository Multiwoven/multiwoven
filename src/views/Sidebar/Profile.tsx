import { getUserProfile, logout } from '@/services/user';
import {
  Avatar,
  Box,
  Button,
  HStack,
  Popover,
  PopoverBody,
  PopoverContent,
  PopoverTrigger,
  Text,
  VStack,
  useToast,
} from '@chakra-ui/react';
import { useQuery } from '@tanstack/react-query';
import { FiEdit3, FiLogOut, FiMoreVertical } from 'react-icons/fi';
import { useNavigate } from 'react-router-dom';

const Profile = () => {
  const { data } = useQuery({
    queryKey: ['users', 'profile', 'me'],
    queryFn: () => getUserProfile(),
    refetchOnMount: true,
    refetchOnWindowFocus: false,
  });

  const toast = useToast();
  const navigate = useNavigate();

  const handleLogout = async () => {
    const logoutResponse = await logout();
    if (logoutResponse.data) {
      toast({
        title: 'Signed out successfully',
        isClosable: true,
        duration: 5000,
        status: 'success',
        position: 'bottom-right',
      });
      navigate('/sign-in');
    }
  };

  return (
    <>
      <Popover closeOnEsc>
        <PopoverTrigger>
          <Box>
            <Box
              bgColor='gray.200'
              px={2}
              py={2}
              rounded='lg'
              _hover={{ bgColor: 'gray.400' }}
            >
              <HStack spacing={0}>
                <Avatar
                  name={data?.data?.attributes.name}
                  mr={1}
                  bgColor='brand.400'
                  marginRight={2}
                  color='gray.100'
                  size='sm'
                  fontWeight='extrabold'
                />
                <VStack spacing={0} align='start'>
                  <Box w='128px' maxW='128px'>
                    <Text size='sm' fontWeight='semibold' noOfLines={1}>
                      {data?.data?.attributes.name}
                    </Text>
                    <Text color='black.200' size='xs' noOfLines={1}>
                      {data?.data?.attributes.email}
                    </Text>
                  </Box>
                </VStack>
                <Box color='gray.600'>
                  <FiMoreVertical />
                </Box>
              </HStack>
            </Box>
          </Box>
        </PopoverTrigger>
        <PopoverContent w='182px' border='1px' borderColor='gray.500'>
          <PopoverBody margin={0} p={0}>
            <Button
              w='100%'
              py={3}
              px={2}
              display='flex'
              flexDir='row'
              alignItems='center'
              justifyContent='start'
              border={0}
              rounded='lg'
              as='button'
              variant='shell'
              isDisabled={true}
            >
              <Box color='gray.600'>
                <FiEdit3 />
              </Box>
              <Text size='sm' fontWeight='semibold' ml={3}>
                Edit Profile
              </Text>
            </Button>
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
              onClick={handleLogout}
              as='button'
              justifyContent='start'
              border={0}
              variant='shell'
            >
              <FiLogOut />
              <Text size='sm' fontWeight='semibold' ml={3}>
                Sign Out
              </Text>
            </Button>
          </PopoverBody>
        </PopoverContent>
      </Popover>
    </>
  );
};

export default Profile;
