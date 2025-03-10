import { Box, Text, Textarea, Input, Divider } from '@chakra-ui/react';
import { useStore } from '@/stores';
import { useQuery } from '@tanstack/react-query';
import { getWorkspaces, CreateWorkspaceResponse, updateWorkspace } from '@/services/settings';
import FormFooter from '@/components/FormFooter';
import { FormikProps, useFormik } from 'formik';
import useCustomToast from '@/hooks/useCustomToast';
import { CustomToastStatus } from '@/components/Toast/index';
import { useState, useEffect } from 'react';

const Workspace = () => {
  const [isEditLoading, setIsEditLoading] = useState<boolean>(false);
  const activeWorkspaceId = useStore((state) => state.workspaceId);
  const showToast = useCustomToast();

  const { data, refetch } = useQuery({
    queryKey: ['workspace'],
    queryFn: () => getWorkspaces(),
    refetchOnMount: true,
    refetchOnWindowFocus: true,
  });

  const workspaceData = data?.data;
  const activeWorkspaceDetails = workspaceData?.find?.(
    (workspace) => workspace?.id === activeWorkspaceId,
  );

  const formik: FormikProps<{
    name: string;
    slug: string;
    description: string;
    organization_name: string;
  }> = useFormik({
    initialValues: {
      name: activeWorkspaceDetails?.attributes.name || '',
      slug: activeWorkspaceDetails?.attributes?.slug || '',
      description: activeWorkspaceDetails?.attributes?.description || '',
      organization_name: activeWorkspaceDetails?.attributes?.organization_name || '',
    },
    onSubmit: async (data) => {
      setIsEditLoading(true);
      try {
        const payload: CreateWorkspaceResponse = {
          name: data.name,
          description: data.description,
          organization_id: activeWorkspaceDetails?.attributes?.organization_id as number,
        };

        const updateResponse = await updateWorkspace(payload, activeWorkspaceId);
        if (updateResponse.data.attributes) {
          showToast({
            title: 'Workspace updated successfully',
            status: CustomToastStatus.Success,
            duration: 3000,
            isClosable: true,
            position: 'bottom-right',
          });
          refetch();
        }
      } catch {
        showToast({
          status: CustomToastStatus.Error,
          title: 'Error!!',
          description: 'Something went wrong while updating the workspace',
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
      name: activeWorkspaceDetails?.attributes.name || '',
      slug: activeWorkspaceDetails?.attributes?.slug || '',
      description: activeWorkspaceDetails?.attributes?.description || '',
      organization_name: activeWorkspaceDetails?.attributes?.organization_name || '',
    });
  }, [activeWorkspaceDetails]);

  // console.log(formik.values.name);

  return (
    <form onSubmit={formik.handleSubmit} key={workspaceData?.[0]?.attributes?.name}>
      <Box
        backgroundColor='gray.100'
        padding='24px'
        borderRadius='8px'
        marginBottom='20px'
        display='flex'
        flexDirection='column'
        gap='24px'
        border={'1px solid'}
        borderColor={'gray.400'}
      >
        <Text size='md' fontWeight='semibold'>
          Edit your workspace details
        </Text>
        <Box display='flex' alignItems='flex-end' gap='24px'>
          <Box width='100%' display='flex' flexDirection='column' gap='8px'>
            <Text fontWeight='semibold' size='sm'>
              Workspace Name
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
              Workspace Slug
            </Text>

            <Box
              border='thin'
              display='flex'
              backgroundColor='gray.100'
              borderRadius='6px'
              alignItems='center'
              borderWidth='1px'
              borderStyle='solid'
              borderColor='gray.400'
              height='40px'
              gap='12px'
              paddingX='12px'
            >
              <Box>
                <Text size='sm' fontWeight={500}>
                  app.squared.ai/
                </Text>
              </Box>
              <Divider orientation='vertical' height='24px' color='gray.400' />
              <Box width='100%'>
                <Input
                  backgroundColor='gray.100'
                  onChange={formik.handleChange}
                  value={formik.values.slug}
                  borderStyle='solid'
                  borderWidth='1px'
                  borderColor='gray.400'
                  borderLeft='none'
                  borderRight='none'
                  fontSize='14px'
                  borderRadius='6px'
                  _focusVisible={{ border: 'gray.400' }}
                  _hover={{ border: 'gray.400' }}
                  name='slug'
                  disabled
                />
              </Box>
            </Box>
          </Box>
        </Box>
        <Box gap='8px' display='flex' flexDirection='column'>
          <Box display='flex' alignItems='flex-end'>
            <Text size='sm' fontWeight='semibold'>
              Workspace Description
            </Text>
            <Text size='xs' color='gray.600' ml={1} fontWeight={400}>
              (optional)
            </Text>
          </Box>

          <Textarea
            name='description'
            value={formik.values.description}
            placeholder='Enter a description'
            background='gray.100'
            resize='none'
            onChange={formik.handleChange}
            borderWidth='1px'
            borderStyle='solid'
            borderColor='gray.400'
            _focusVisible={{ border: 'gray.400' }}
            _hover={{ border: 'gray.400' }}
          />
        </Box>
        <Box display='flex' alignItems='flex-end' gap='24px'>
          <Box width='100%' display='flex' flexDirection='column' gap='8px'>
            <Text fontWeight='semibold' size='sm'>
              Organization Name
            </Text>

            <Input
              name='organization_name'
              backgroundColor='gray.300'
              onChange={formik.handleChange}
              value={formik.values.organization_name}
              borderStyle='solid'
              borderWidth='1px'
              borderColor='gray.400'
              fontSize='14px'
              borderRadius='6px'
              _focusVisible={{ border: 'gray.400' }}
              _hover={{ border: 'gray.400' }}
              disabled
            />
          </Box>
          <Box width='100%' display='flex' flexDirection='column' gap='8px'>
            <Text fontWeight='semibold' size='sm'>
              Workspace Region
            </Text>

            <Input
              backgroundColor='gray.300'
              value='United States (aws-us-east-1)'
              borderStyle='solid'
              borderWidth='1px'
              borderColor='gray.400'
              fontSize='14px'
              borderRadius='6px'
              disabled
              fontWeight={400}
              color='black.100'
            />
          </Box>
        </Box>
        <FormFooter
          ctaName='Save Changes'
          isContinueCtaRequired
          ctaType='submit'
          isAlignToContentContainer
          isCtaLoading={isEditLoading}
          isCtaDisabled={!formik.values.name}
        />
      </Box>
    </form>
  );
};

export default Workspace;
