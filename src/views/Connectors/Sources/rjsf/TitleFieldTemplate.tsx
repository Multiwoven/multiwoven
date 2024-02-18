import { FormContextType, RJSFSchema, StrictRJSFSchema, TitleFieldProps } from '@rjsf/utils';
import { Box, Heading } from '@chakra-ui/react';

export default function TitleFieldTemplate<T = unknown, S extends StrictRJSFSchema = RJSFSchema, F extends FormContextType = any>({
  id,
  title,
}: TitleFieldProps<T, S, F>) {
  return (
    <Box id={id} mb={6}>
      <Heading as="h5" fontSize="b3" lineHeight="b3" letterSpacing="b3" fontWeight="semiBold">{title}</Heading>
    </Box>
  );
}
