import { Box, Button, Flex, FormControl, FormLabel, Text, Textarea } from '@chakra-ui/react';
import { FieldInputProps, FormikProvider, useFormik } from 'formik';
import { ChangeEvent, FocusEvent } from 'react';
import * as Yup from 'yup';
import { FormField, PasswordField } from '@/components/Fields';
import { SecretSectionView } from './SecretsSection';

export type CreateOrEditSecretValues = {
  name: string;
  value: string;
  description: string;
};

type CreateOrEditSecretProps = {
  mode: Exclude<SecretSectionView, 'list'>;
  handleClose: () => void;
  onSubmit: (values: CreateOrEditSecretValues) => void | Promise<void>;
  initialValues?: CreateOrEditSecretValues;
  isLoading?: boolean;
};

// Normalize secret-name input as the user types:
// - Strip leading whitespace so the value never starts with a space (which
//   would otherwise become a leading underscore).
// - Collapse any run of interior whitespace into a single underscore.
// - Force uppercase.
// Trailing whitespace can't be trimmed here (it would prevent typing a
// space-then-letter sequence); trailing underscores are trimmed on blur
// in getNameFieldProps below.
const normalizeSecretNameInput = (raw: string): string =>
  raw.replace(/^\s+/, '').replace(/\s+/g, '_').toUpperCase();

const RESERVED_SECRET_NAMES = [
  'DATABASE_URL',
  'S3_ACCESS_KEY',
  'S3_SECRET_KEY',
  'S3_BUCKET',
  'S3_PREFIX',
  'S3_REGION',
  'AWS_SESSION_TOKEN',
  'AWS_ACCESS_KEY_ID',
  'AWS_SECRET_ACCESS_KEY',
  'ANTHROPIC_API_KEY',
  'OPENCODE_SERVER_PASSWORD',
  'MCP_SERVER_URL',
  'MCP_AUTH_TOKEN',
  'WORKSPACE_ID',
  'APPGEN_APP_ID',
  'AIS_API_BASE_URL',
  'AIS_AUTH_ENABLED',
  'VITE_API_BASE_URL',
  'VITE_APP_ID',
];

const createOrEditSecretSchema = Yup.object().shape({
  // The on-input transform above guarantees uppercase + no spaces, but we
  // keep the schema-level transforms as a defensive net for any non-input
  // value paths (e.g. programmatic setValues, edit-mode initialValues from
  // an older record).
  name: Yup.string()
    .transform((value: string) => value?.replace(/\s+/g, '_').toUpperCase())
    .matches(/^\S+$/, 'Secret name cannot contain spaces')
    .notOneOf(RESERVED_SECRET_NAMES, 'This secret name is reserved')
    .min(1)
    .required('Secret name is required'),
  value: Yup.string().min(1).required('Secret value is required'),
  description: Yup.string().optional(),
});

const EMPTY_VALUES: CreateOrEditSecretValues = {
  name: '',
  value: '',
  description: '',
};

const FieldLabel = ({
  htmlFor,
  children,
  optional,
}: {
  htmlFor: string;
  children: React.ReactNode;
  optional?: boolean;
}) => (
  <Flex as='label' htmlFor={htmlFor} alignItems='center' gap='4px' mb='8px'>
    <Text fontWeight='semibold' color='black.500' fontSize='sm'>
      {children}
    </Text>
    {optional && (
      <Text fontWeight='normal' color='black.100' fontSize='xs'>
        (optional)
      </Text>
    )}
  </Flex>
);

const CreateOrEditSecret = ({
  mode,
  handleClose,
  onSubmit,
  initialValues,
  isLoading,
}: CreateOrEditSecretProps) => {
  const formik = useFormik<CreateOrEditSecretValues>({
    initialValues: initialValues ?? EMPTY_VALUES,
    enableReinitialize: true,
    validationSchema: createOrEditSecretSchema,
    onSubmit: (values) => onSubmit(values),
  });

  // Wraps formik.getFieldProps for the `name` field so any user input is
  // normalized (uppercase, spaces → underscores, no leading whitespace) on
  // the fly. The onChange writes the transformed value back through
  // setFieldValue, and onBlur trims any trailing underscores that may have
  // accumulated from trailing spaces typed before defocus.
  const getNameFieldProps: typeof formik.getFieldProps = (nameOrOptions) => {
    const props = formik.getFieldProps(nameOrOptions);
    return {
      ...props,
      onChange: (event: ChangeEvent<HTMLInputElement>) => {
        formik.setFieldValue('name', normalizeSecretNameInput(event.target.value));
      },
      onBlur: (event: FocusEvent<HTMLInputElement>) => {
        const trimmed = formik.values.name.replace(/_+$/, '');
        if (trimmed !== formik.values.name) {
          formik.setFieldValue('name', trimmed);
        }
        props.onBlur(event);
      },
    } as FieldInputProps<string>;
  };

  const submitLabel = mode === 'edit' ? 'Save Changes' : 'Save';

  return (
    <FormikProvider value={formik}>
      <Flex flex={1} minW={0} w='100%' direction='column' justify='space-between'>
        <Flex direction='column' gap='24px' w='100%' maxW='480px' pl='24px'>
          <Box>
            <FieldLabel htmlFor='name'>Secret Name</FieldLabel>
            <FormField
              id='name'
              placeholder='Enter a secret name (e.g., MY_UNIQUE_KEY)'
              name='name'
              type='text'
              getFieldProps={getNameFieldProps}
              touched={formik.touched}
              errors={formik.errors}
              data-testid='create-or-edit-secret-name-input'
            />
          </Box>

          <Box>
            <FieldLabel htmlFor='value'>Value</FieldLabel>
            <PasswordField
              id='value'
              placeholder='Enter the value of the secret'
              name='value'
              type='password'
              getFieldProps={formik.getFieldProps}
              touched={formik.touched}
              errors={formik.errors}
              data-testid='create-or-edit-secret-value-input'
            />
          </Box>

          <FormControl isInvalid={formik.touched.description && !!formik.errors.description}>
            <FormLabel htmlFor='description' mb='8px'>
              <Flex alignItems='center' gap='4px'>
                <Text fontWeight='semibold' color='black.500' fontSize='sm'>
                  Description
                </Text>
                <Text fontWeight='normal' color='black.100' fontSize='xs'>
                  (optional)
                </Text>
              </Flex>
            </FormLabel>
            <Textarea
              id='description'
              name='description'
              variant='outline'
              placeholder='Enter a short description for this secret'
              fontSize='sm'
              height='145px'
              borderColor='gray.400'
              resize='none'
              value={formik.values.description}
              onChange={formik.handleChange}
              onBlur={formik.handleBlur}
              data-testid='create-or-edit-secret-description-input'
            />
            {formik.touched.description && formik.errors.description && (
              <Text
                color='red.500'
                fontSize='xs'
                mt='4px'
                data-testid='create-or-edit-secret-description-error'
              >
                {formik.errors.description}
              </Text>
            )}
          </FormControl>
        </Flex>

        <Box
          borderTopWidth='1px'
          borderColor='gray.400'
          alignItems='center'
          justifyContent='end'
          display='flex'
          pt='20px'
          gap='12px'
          pr='24px'
        >
          <Button
            variant='ghost'
            w='fit-content'
            onClick={handleClose}
            isDisabled={isLoading}
            data-testid='create-or-edit-secret-cancel-button'
          >
            Cancel
          </Button>
          <Button
            w='fit-content'
            isLoading={isLoading}
            loadingText='Saving...'
            onClick={async () => {
              const errors = await formik.validateForm();
              if (Object.keys(errors).length === 0) {
                formik.handleSubmit();
              }
            }}
            data-testid='create-or-edit-secret-submit-button'
          >
            {submitLabel}
          </Button>
        </Box>
      </Flex>
    </FormikProvider>
  );
};

export default CreateOrEditSecret;
