import { FormContextType, RJSFSchema, StrictRJSFSchema, TitleFieldProps } from '@rjsf/utils';
import { Box, Divider, Heading } from '@chakra-ui/react';

export default function MWTitleField<T = any, S extends StrictRJSFSchema = RJSFSchema, F extends FormContextType = any>({
  id,
  title,
}: TitleFieldProps<T, S, F>) {
  return (
    <Box id={id} mt={1} mb={4}>
      <Heading as='h5' fontSize="md">{title}</Heading>
      <Divider />
    </Box>
  );
}
