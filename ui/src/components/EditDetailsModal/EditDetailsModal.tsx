import BaseModal from '@/components/BaseModal';
import titleCase from '@/utils/TitleCase';
import {
  Box,
  Button,
  Input,
  Text,
  Textarea,
  FormControl,
  FormLabel,
  Flex,
  VStack,
} from '@chakra-ui/react';
import { useFormik } from 'formik';
import * as yup from 'yup';

type EditDetailsModalProps = {
  openModal: boolean;
  setModalOpen: (open: boolean) => void;
  resourceName: string;
  onSave: (values: { name: string; description: string }) => void;
  initialValues?: { name: string; description: string };
};

const EditDetailsModal = ({
  openModal,
  setModalOpen,
  resourceName,
  onSave,
  initialValues = { name: '', description: '' },
}: EditDetailsModalProps) => {
  const formik = useFormik({
    initialValues,
    validationSchema: yup.object({
      name: yup.string().min(1, 'Name is required').required('Name is required'),
      description: yup.string().optional(),
    }),
    onSubmit: onSave,
  });

  return (
    <BaseModal
      title='Edit Details'
      description={`Edit the settings for this ${resourceName || 'resource'}`}
      footer={
        <Box display='flex' gap='12px'>
          <Button
            variant='ghost'
            w='fit-content'
            onClick={() => {
              setModalOpen(false);
              formik.resetForm();
            }}
            data-testid='cancel-button'
          >
            Cancel
          </Button>
          <Button
            data-testid='save-changes-button'
            onClick={async () => {
              await formik.validateForm();
              if (formik.isValid) {
                onSave(formik.values);
              }
            }}
          >
            Save Changes
          </Button>
        </Box>
      }
      openModal={openModal}
      setModalOpen={setModalOpen}
    >
      <VStack spacing='24px'>
        <FormControl>
          <FormLabel htmlFor='name' fontSize='sm' fontWeight='bold'>
            {titleCase(resourceName)} Name
          </FormLabel>
          <Input
            id='name'
            name='name'
            variant='outline'
            placeholder='Enter a name'
            fontSize='sm'
            value={formik.values.name}
            onChange={formik.handleChange}
            onBlur={formik.handleBlur}
            isInvalid={formik.touched.name && !!formik.errors.name}
            data-testid='name-input'
          />
          {formik.touched.name && formik.errors.name && (
            <Text color='red.500' fontSize='sm'>
              {formik.errors.name}
            </Text>
          )}
        </FormControl>

        <FormControl>
          <FormLabel htmlFor='description' fontWeight='bold'>
            <Flex alignItems='center' fontSize='sm'>
              Description
              <Text ml='2px' size='xs' color='gray.600' fontWeight='normal'>
                (optional)
              </Text>
            </Flex>
          </FormLabel>
          <Textarea
            id='description'
            name='description'
            variant='outline'
            placeholder='Enter a description'
            fontSize='sm'
            height='145px'
            borderColor='gray.400'
            value={formik.values.description}
            onChange={formik.handleChange}
            onBlur={formik.handleBlur}
            isInvalid={formik.touched.description && !!formik.errors.description}
          />
          {formik.touched.description && formik.errors.description && (
            <Text color='red.500' fontSize='sm'>
              {formik.errors.description}
            </Text>
          )}
        </FormControl>
      </VStack>
    </BaseModal>
  );
};

export default EditDetailsModal;
