import { FormContextType, RJSFSchema, StrictRJSFSchema, TitleFieldProps } from '@rjsf/utils';
import { Box, Text } from '@chakra-ui/react';

export default function TitleFieldTemplate<
  T = unknown,
  S extends StrictRJSFSchema = RJSFSchema,
  F extends FormContextType = any,
>({ id, title }: TitleFieldProps<T, S, F>) {
  return (
    <Box id={id} mb={6}>
      <Text size='md' fontWeight='semibold'>
        {title}
      </Text>
    </Box>
  );
}
