import { FormControl, Input, InputGroup, InputRightElement, Text, Tooltip } from '@chakra-ui/react';
import HiddenInput from '../HiddenInput';
import { ErrorMessage, FieldInputProps, FormikErrors, FormikTouched } from 'formik';
import { FiInfo } from 'react-icons/fi';

type FormFieldProps = {
  name: string;
  type: string;
  placeholder?: string;
  tooltipText?: string;
  hasTooltip?: boolean;
  id?: string;
  getFieldProps: (
    nameOrOptions:
      | string
      | {
          name: string;
          value?: any;
          onChange?: (e: any) => void;
          onBlur?: (e: any) => void;
        },
  ) => FieldInputProps<any>;
  touched: FormikTouched<any>;
  errors: FormikErrors<any>;
  helperText?: string;
};

export const FormField = ({
  name,
  type,
  getFieldProps,
  touched,
  errors,
  placeholder,
  tooltipText,
  hasTooltip,
}: FormFieldProps) => (
  <FormControl isInvalid={!!(touched[name] && errors[name])}>
    <InputGroup>
      {hasTooltip ? (
        <InputRightElement>
          <Tooltip
            hasArrow
            label={tooltipText}
            fontSize='xs'
            placement='top'
            backgroundColor='black.500'
            color='gray.100'
            borderRadius='6px'
            padding='8px'
            width='auto'
            marginLeft='8px'
          >
            <Text color='gray.600' marginLeft='8px'>
              <FiInfo />
            </Text>
          </Tooltip>
        </InputRightElement>
      ) : (
        <></>
      )}
      <Input
        variant='outline'
        placeholder={placeholder}
        _placeholder={{ color: 'black.100' }}
        type={type}
        {...getFieldProps(name)}
        fontSize='sm'
        color='black.500'
        focusBorderColor='brand.400'
      />
    </InputGroup>
    <Text size='xs' color='red.500' mt={2}>
      <ErrorMessage name={name} />
    </Text>
  </FormControl>
);

export const PasswordField = ({
  name,
  type,
  getFieldProps,
  touched,
  errors,
  placeholder,
  helperText,
  id,
}: FormFieldProps) => (
  <FormControl isInvalid={!!(touched[name] && errors[name])}>
    <HiddenInput
      variant='outline'
      placeholder={placeholder}
      _placeholder={{ color: 'black.100' }}
      type={type}
      {...getFieldProps(name)}
      fontSize='sm'
      color='black.500'
      focusBorderColor='brand.400'
      id={id}
    />
    <Text color='gray.600' ml={1} mt={2} fontWeight={400} size='xs'>
      {helperText}
    </Text>
    <Text size='xs' color='red.500' mt={2}>
      <ErrorMessage name={name} />
    </Text>
  </FormControl>
);
