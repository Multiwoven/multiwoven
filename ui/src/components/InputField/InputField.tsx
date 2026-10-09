import { Box, Text, Input, Tooltip as ChakraTooltip } from '@chakra-ui/react';
import { FiInfo } from 'react-icons/fi';

type InputFieldProps = {
  label: string;
  name: string;
  value: string;
  onChange: React.ChangeEventHandler<HTMLInputElement> | undefined;
  id?: string;
  type?: 'text' | 'password' | 'number';
  placeholder?: string;
  helperText?: string;
  isTooltip?: boolean;
  tooltipLabel?: string;
  disabled?: boolean;
  isRequired?: boolean;
  testId?: string;
};

const InputField = ({
  label,
  name,
  onChange,
  value,
  id,
  type = 'text',
  placeholder = '',
  helperText,
  isTooltip = false,
  tooltipLabel,
  disabled = false,
  isRequired = false,
  testId,
}: InputFieldProps) => (
  <Box width='100%' display='flex' flexDirection='column' gap='8px'>
    <Box display='flex' alignItems='center' gap='4px'>
      <Text fontWeight='semibold' size='sm'>
        {label}
      </Text>
      {isRequired && (
        <Text size='sm' color='error.400'>
          *
        </Text>
      )}
      {isTooltip && (
        <ChakraTooltip
          hasArrow
          label={tooltipLabel}
          fontSize='xs'
          placement='top-start'
          backgroundColor='black.500'
          color='gray.100'
          borderRadius='6px'
          padding='8px'
        >
          <Text color='gray.600' data-testid='tooltip-trigger'>
            <FiInfo />
          </Text>
        </ChakraTooltip>
      )}
    </Box>
    <Input
      id={id}
      placeholder={placeholder}
      backgroundColor='gray.100'
      onChange={onChange}
      value={value}
      borderStyle='solid'
      borderWidth='1px'
      borderColor='gray.400'
      fontSize='14px'
      borderRadius='6px'
      _placeholder={{ color: 'gray.600' }}
      _focusVisible={{ borderColor: 'gray.400' }}
      _hover={{ borderColor: 'gray.400' }}
      name={name}
      type={type}
      required
      data-testid={testId ?? 'input-field'}
      disabled={disabled}
    />
    {helperText && (
      <Text fontWeight={500} size='xs' color='gray.600'>
        {helperText}
      </Text>
    )}
  </Box>
);

export default InputField;
