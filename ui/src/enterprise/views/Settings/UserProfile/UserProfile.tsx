import { Box, Text, Input, Avatar } from '@chakra-ui/react';
import FormFooter from '@/components/FormFooter';

import { FormikProps, useFormik } from 'formik';
import useCustomToast from '@/hooks/useCustomToast';
import { CustomToastStatus } from '@/components/Toast/index';
import { useState, useEffect } from 'react';
import { UpdateUserProfilePayload } from '@/enterprise/services/types';
import { updateUserProfile } from '@/enterprise/services/settings';
import useQueryWrapper from '@/hooks/useQueryWrapper';
import { getUserProfile, ProfileAPIResponse } from '@/services/user';
import titleCase from '@/utils/TitleCase';
import { useRoleDataStore } from '@/enterprise/store/useRoleDataStore';
import { hasActionPermission } from '@/enterprise/utils/accessControlPermission';
import { UserActions } from '@/enterprise/types';

const UserProfile = () => {
  const [isEditLoading, setIsEditLoading] = useState<boolean>(false);
  const activeRole = useRoleDataStore((state) => state.activeRole);

  let hasPermission = false;

  if (activeRole) {
    hasPermission = hasActionPermission(activeRole, 'model', UserActions.Update);
  }

  const showToast = useCustomToast();

  const { data, refetch } = useQueryWrapper<ProfileAPIResponse, Error>(
    ['users', 'profile', 'me'],
    () => getUserProfile(),
    {
      refetchOnMount: true,
      refetchOnWindowFocus: false,
    },
  );

  const formik: FormikProps<{
    name: string;
    email: string;
    old_password: string;
    new_password: string;
  }> = useFormik({
    initialValues: {
      name: data?.data?.attributes?.name || '',
      email: data?.data?.attributes?.email || '',
      old_password: '',
      new_password: '',
    },
    onSubmit: async (data) => {
      setIsEditLoading(true);
      try {
        const payload: UpdateUserProfilePayload = {
          user: {
            name: data.name,
            old_password: data.old_password,
            new_password: data.new_password,
          },
        };

        const updateResponse = await updateUserProfile(payload);
        if (updateResponse?.data?.attributes) {
          showToast({
            title: 'Profile updated successfully',
            status: CustomToastStatus.Success,
            duration: 3000,
            isClosable: true,
            position: 'bottom-right',
          });
          refetch();
        } else {
          updateResponse.errors?.forEach((error) => {
            showToast({
              duration: 5000,
              isClosable: true,
              position: 'bottom-right',
              colorScheme: 'red',
              status: CustomToastStatus.Warning,
              title: titleCase(error.detail),
            });
          });
        }
      } catch {
        showToast({
          status: CustomToastStatus.Error,
          title: 'Something went wrong while updating the profile',
          position: 'bottom-right',
          isClosable: true,
        });
      } finally {
        setIsEditLoading(false);
      }
    },
  });

  useEffect(() => {
    formik.setValues({
      name: data?.data?.attributes?.name || '',
      email: data?.data?.attributes?.email || '',
      old_password: '',
      new_password: '',
    });
  }, [data]);

  return (
    <>
      <form onSubmit={formik.handleSubmit}>
        <Box
          backgroundColor='gray.100'
          padding='24px'
          borderRadius='8px'
          marginBottom='20px'
          display='flex'
          flexDirection='column'
          gap='24px'
        >
          <Text size='md' fontWeight='semibold'>
            Edit your profile details
          </Text>
          <Avatar
            name={data?.data?.attributes?.name}
            mr={1}
            bgColor='brand.400'
            marginRight={2}
            color='gray.100'
            size='lg'
            fontWeight='extrabold'
          />
          <Box display='flex' alignItems='flex-end' gap='24px'>
            <Box width='100%' display='flex' flexDirection='column' gap='8px'>
              <Text fontWeight='semibold' size='sm'>
                Name
              </Text>

              <Input
                backgroundColor='gray.100'
                onChange={formik.handleChange}
                value={formik.values.name}
                borderStyle='solid'
                borderWidth='1px'
                borderColor='gray.400'
                fontSize='14px'
                borderRadius='6px'
                _focusVisible={{ border: 'gray.400' }}
                _hover={{ border: 'gray.400' }}
                name='name'
              />
            </Box>
            <Box width='100%' display='flex' flexDirection='column' gap='8px'>
              <Text fontWeight='semibold' size='sm'>
                Email
              </Text>

              <Input
                backgroundColor='gray.300'
                value={formik.values.email}
                borderStyle='solid'
                borderWidth='1px'
                borderColor='gray.400'
                fontSize='14px'
                borderRadius='6px'
                _focusVisible={{ border: 'gray.400' }}
                _hover={{ border: 'gray.400' }}
                name='email'
                isDisabled
              />
            </Box>
          </Box>
          <Box display='flex' alignItems='flex-end' gap='24px'>
            <Box width='100%' display='flex' flexDirection='column' gap='8px'>
              <Text fontWeight='semibold' size='sm'>
                Old Password
              </Text>

              <Input
                backgroundColor='gray.100'
                onChange={formik.handleChange}
                value={formik.values.old_password}
                borderStyle='solid'
                borderWidth='1px'
                borderColor='gray.400'
                fontSize='14px'
                borderRadius='6px'
                _focusVisible={{ border: 'gray.400' }}
                _hover={{ border: 'gray.400' }}
                name='old_password'
                type='password'
              />
            </Box>
            <Box width='100%' display='flex' flexDirection='column' gap='8px'>
              <Text fontWeight='semibold' size='sm'>
                New Password
              </Text>

              <Input
                backgroundColor='gray.100'
                onChange={formik.handleChange}
                value={formik.values.new_password}
                borderStyle='solid'
                borderWidth='1px'
                borderColor='gray.400'
                fontSize='14px'
                borderRadius='6px'
                _focusVisible={{ border: 'gray.400' }}
                _hover={{ border: 'gray.400' }}
                name='new_password'
                type='password'
              />
            </Box>
          </Box>
          {hasPermission && (
            <FormFooter
              ctaName='Save Changes'
              isContinueCtaRequired
              ctaType='submit'
              isAlignToContentContainer
              isCtaLoading={isEditLoading}
              isCtaDisabled={!formik.values.name}
            />
          )}
        </Box>
      </form>
    </>
  );
};

export default UserProfile;
