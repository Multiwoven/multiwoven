import { getUserProfile, logout, ProfileAPIResponse } from '@/services/user';
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
} from '@chakra-ui/react';
import { CustomToastStatus } from '@/components/Toast/index';
import useCustomToast from '@/hooks/useCustomToast';
import { FiLogOut, FiMoreVertical } from 'react-icons/fi';
import useQueryWrapper from '@/hooks/useQueryWrapper';
import Cookies from 'js-cookie';
import { useStore } from '@/stores';

const Profile = () => {
  const { data } = useQueryWrapper<ProfileAPIResponse, Error>(
    ['users', 'profile', 'me'],
    () => getUserProfile(),
    {
      refetchOnMount: true,
      refetchOnWindowFocus: false,
    },
  );

  const showToast = useCustomToast();

  const handleLogout = async () => {
    const logoutResponse = await logout();

    if (logoutResponse.data) {
      window.location.href = '/sign-in';
      Cookies.remove('authToken');
      useStore.getState().clearState();
      showToast({
        title: 'Signed out successfully',
        isClosable: true,
        duration: 5000,
        status: CustomToastStatus.Success,
        position: 'bottom-right',
      });
    }
  };

  return (
    <>
      <Popover closeOnEsc>
        <PopoverTrigger>
          <Box cursor='pointer'>
            <Box bgColor='gray.200' px={2} py={2} rounded='lg' _hover={{ bgColor: 'gray.300' }}>
              <HStack spacing={0}>
                <Avatar
                  name={data?.data?.attributes?.name}
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
                      {data?.data?.attributes?.name}
                    </Text>
                    <Text color='black.200' size='xs' noOfLines={1}>
                      {data?.data?.attributes?.email}
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
        <PopoverContent w='182px' border='1px' borderColor='gray.400'>
          <PopoverBody margin={0} p={0}>
            <Button
              _hover={{ bgColor: 'gray.200' }}
              w='100%'
              py={3}
              px={2}
              display='flex'
              flexDir='row'
              alignItems='center'
              color='error.400'
              rounded='lg'
              onClick={handleLogout}
              as='button'
              justifyContent='start'
              border={0}
              variant='shell'
            >
              <FiLogOut />
              <Text size='sm' fontWeight={400} ml={3} color='error.500'>
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
