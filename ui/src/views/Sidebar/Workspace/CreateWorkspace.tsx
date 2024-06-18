import {
  Box,
  Text,
  ModalBody,
  ModalCloseButton,
  ModalContent,
  ModalFooter,
  ModalHeader,
  Flex,
  Button,
  Input,
  Textarea,
} from '@chakra-ui/react';
import { FormikProps, useFormik } from 'formik';

import useCustomToast from '@/hooks/useCustomToast';
import { CustomToastStatus } from '@/components/Toast/index';
import { useState } from 'react';
import { CreateWorkspaceResponse, createWorkspace } from '@/services/settings';

const CreateWorkspace = ({
  organizationName,
  organizationId,
  handleWorkspaceCreate,
  handleCancelClick,
}: {
  organizationName: string;
  organizationId: number;
  handleWorkspaceCreate: () => void;
  handleCancelClick: () => void;
}) => {
  const [isEditLoading, setIsEditLoading] = useState<boolean>(false);

  const showToast = useCustomToast();

  const formik: FormikProps<{
    name: string;
    region: string;
    description: string;
    organization_name: string;
  }> = useFormik({
    initialValues: {
      name: '',
      region: 'United States (aws-us-east-1)',
      description: '',
      organization_name: organizationName,
    },
    onSubmit: async (data) => {
      setIsEditLoading(true);
      try {
        const payload: CreateWorkspaceResponse = {
          name: data.name,
          description: data.description,
          organization_id: organizationId,
          region: data.region,
        };

        const createWorkspaceResponse = await createWorkspace(payload);
        if (createWorkspaceResponse.data.attributes) {
          showToast({
            title: 'Workspace created successfully',
            status: CustomToastStatus.Success,
            duration: 3000,
            isClosable: true,
            position: 'bottom-right',
          });
          handleWorkspaceCreate?.();
        }
      } catch {
        showToast({
          status: CustomToastStatus.Error,
          title: 'Error!!',
          description: 'Something went wrong while creating the workspace',
          position: 'bottom-right',
          isClosable: true,
        });
      } finally {
        setIsEditLoading(false);
      }
    },
  });

  return (
    <form onSubmit={formik.handleSubmit}>
      <ModalContent>
        <ModalHeader paddingX='24px' paddingY='20px'>
          <Text fontWeight={700} size='xl' color='black.500' letterSpacing='-0.2px'>
            Create a new workspace
          </Text>
          <ModalCloseButton color='gray.600' />
        </ModalHeader>

        <ModalBody marginX='24px' marginY='8px' padding={0}>
          <Flex direction='column' gap='24px'>
            <Box display='flex' flexDirection='column' gap='8px'>
              <Text size='md' fontWeight='semibold'>
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
                placeholder='Enter workspace name'
                autoComplete='off'
              />
            </Box>
            <Box display='flex' flexDirection='column' gap='8px'>
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
            <Box display='flex' flexDirection='column' gap='8px'>
              <Text size='md' fontWeight='semibold'>
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
            <Box display='flex' flexDirection='column' gap='8px'>
              <Text size='md' fontWeight='semibold'>
                Organization
              </Text>
              <Input
                name='organization_name'
                value={organizationName}
                backgroundColor='gray.300'
                onChange={formik.handleChange}
                borderStyle='solid'
                borderWidth='1px'
                borderColor='gray.400'
                fontSize='14px'
                borderRadius='6px'
                _focusVisible={{ border: 'gray.400' }}
                _hover={{ border: 'gray.400' }}
                disabled
                color='black.100'
              />
            </Box>
          </Flex>
        </ModalBody>

        <ModalFooter paddingX='24px' paddingY='20px'>
          <Box w='full'>
            <Flex flexDir='row' justifyContent='end'>
              <Button
                variant='ghost'
                mr={3}
                onClick={handleCancelClick}
                size='md'
                color='black.500'
                minWidth={0}
                width='auto'
              >
                Cancel
              </Button>
              <Button
                variant='solid'
                color='white'
                rounded='lg'
                type='submit'
                isLoading={isEditLoading}
                minWidth={0}
                width='auto'
                isDisabled={!formik.values.name}
              >
                Create Workspace
              </Button>
            </Flex>
          </Box>
        </ModalFooter>
      </ModalContent>
    </form>
  );
};

export default CreateWorkspace;
