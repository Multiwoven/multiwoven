import ToolTip from '@/components/ToolTip';
import {
  Text,
  Flex,
  Box,
  Input,
  Textarea,
  useDisclosure,
  InputGroup,
  InputRightElement,
  IconButton,
} from '@chakra-ui/react';
import { WidgetProps } from '@rjsf/utils';
import { FiInfo } from 'react-icons/fi';
import { FiEye, FiEyeOff } from 'react-icons/fi';

function getByPath(obj: any, path?: string) {
  if (!obj || !path) return undefined;
  return path.split('.').reduce((acc, key) => (acc == null ? acc : acc[key]), obj);
}

const TextInput = ({
  id,
  value,
  defaultValue,
  required,
  disabled,
  onChange,
  label,
  options,
  formContext,
}: WidgetProps) => {
  const { isOpen, onToggle } = useDisclosure();

  const onClickReveal = () => {
    onToggle();
  };

  const watchPath = (options as any)?.watch as string | undefined;
  const expected = (options as any)?.watchValue as any;
  const current = getByPath(formContext.configuration, watchPath);

  if (watchPath != null) {
    if (Array.isArray(expected) && !expected.includes(current)) return null;
    if (!Array.isArray(expected) && current !== expected) return null;
  }

  return (
    <Flex gap='10px' flexDir='column'>
      <Flex gap='8px' alignItems={'center'}>
        <Flex gap='4px'>
          {label && (
            <Text size={'sm'} fontWeight={600}>
              {label}
            </Text>
          )}
          {required && <Box color='error.400'>*</Box>}
        </Flex>
        {options?.tooltip && (
          <ToolTip label={options.tooltip as string}>
            <Box color='gray.600'>
              <FiInfo width='14px' height='14px' />
            </Box>
          </ToolTip>
        )}
      </Flex>
      {options?.isTextarea ? (
        <Box>
          <Textarea
            id={id}
            data-testid={id ? `workflow-config-field-${id}` : 'workflow-config-textarea'}
            value={value ?? defaultValue}
            onChange={(e) => {
              onChange(e.target.value);
            }}
            isDisabled={disabled}
            isRequired={required}
            placeholder={options?.input_placeholder as string}
            border={'1px solid'}
            borderColor={'gray.400'}
            maxLength={options?.maxLength ? Number(options.maxLength) : undefined}
          />
          {options?.maxLength && (
            <Text fontSize='sm' color='gray.600' textAlign='right'>
              {(value ?? defaultValue ?? '').length}/{options?.maxLength}
            </Text>
          )}
        </Box>
      ) : (
        <Box>
          <InputGroup>
            <Input
              id={id}
              data-testid={id ? `workflow-config-field-${id}` : 'workflow-config-input'}
              value={value ?? defaultValue}
              onChange={(e) => onChange(e.target.value)}
              isDisabled={disabled}
              isRequired={required}
              type={options?.protected && !isOpen ? 'password' : 'text'}
              placeholder={options?.input_placeholder as string}
              maxLength={options?.maxLength ? Number(options.maxLength) : undefined}
            />
            {options?.protected && (
              <InputRightElement>
                <IconButton
                  variant='text'
                  color='gray.600'
                  aria-label={isOpen ? 'Mask password' : 'Reveal password'}
                  icon={isOpen ? <FiEyeOff /> : <FiEye />}
                  onClick={onClickReveal}
                />
              </InputRightElement>
            )}
          </InputGroup>
          {options?.maxLength && (
            <Text fontSize='sm' color='gray.600' textAlign='right'>
              {(value ?? defaultValue ?? '').length}/{Number(options.maxLength)}
            </Text>
          )}
        </Box>
      )}
    </Flex>
  );
};

export default TextInput;
