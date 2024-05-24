import { FocusEvent } from 'react';
import {
  ADDITIONAL_PROPERTY_FLAG,
  FormContextType,
  RJSFSchema,
  StrictRJSFSchema,
  TranslatableString,
  WrapIfAdditionalTemplateProps,
} from '@rjsf/utils';
import { Box, CloseButton, FormControl, FormLabel, Input, Text } from '@chakra-ui/react';
import { ArrowRightIcon } from '@heroicons/react/24/outline';

export default function WrapIfAdditionalTemplate<
  T = any,
  S extends StrictRJSFSchema = RJSFSchema,
  F extends FormContextType = any,
>(props: WrapIfAdditionalTemplateProps<T, S, F>) {
  const {
    children,
    classNames,
    style,
    disabled,
    id,
    label,
    onDropPropertyClick,
    onKeyChange,
    readonly,
    registry,
    required,
    schema,
  } = props;

  const { translateString } = registry;

  const keyLabel = translateString(TranslatableString.KeyLabel, [label]);

  if (!(ADDITIONAL_PROPERTY_FLAG in schema)) {
    return (
      <div className={classNames} style={style}>
        {children}
      </div>
    );
  }

  const handleBlur = ({ target }: FocusEvent<HTMLInputElement>) => onKeyChange(target.value);

  return (
    <>
      <Box key={`${id}-key`} display='flex' gap={3}>
        <FormControl isRequired={required}>
          <FormLabel htmlFor={`${id}-key`} id={`${id}-key-label`}>
            <Text size='sm' fontWeight='semibold'>
              {keyLabel}
            </Text>
          </FormLabel>
          <Input
            defaultValue={label}
            disabled={disabled || readonly}
            id={`${id}-key`}
            name={`${id}-key`}
            onBlur={!readonly ? handleBlur : undefined}
            type='text'
            mb={1}
          />
        </FormControl>
        <Box width='80px' padding='20px' position='relative' mt='auto' top='4px' color='gray.600'>
          <ArrowRightIcon />
        </Box>
        {children}
        <Box mt='auto' mb={1}>
          <Box py='20px' position='relative' top='12px' color='gray.600'>
            <CloseButton
              size='sm'
              _hover={{ backgroundColor: 'none' }}
              disabled={disabled || readonly}
              onClick={onDropPropertyClick(label)}
            />
          </Box>
        </Box>
      </Box>
    </>
  );
}
