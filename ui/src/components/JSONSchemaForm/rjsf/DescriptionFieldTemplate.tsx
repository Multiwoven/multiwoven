import { DescriptionFieldProps, FormContextType, RJSFSchema, StrictRJSFSchema } from '@rjsf/utils';
import { Text } from '@chakra-ui/react';

export default function DescriptionFieldTemplate<
  T = unknown,
  S extends StrictRJSFSchema = RJSFSchema,
  F extends FormContextType = any,
>({ description, id }: DescriptionFieldProps<T, S, F>) {
  if (!description) {
    return null;
  }

  if (typeof description === 'string') {
    return (
      <Text
        id={id}
        mt={2}
        mb={1}
        color='black.200'
        fontSize='b5'
        letterSpacing='b5'
        lineHeight='b5'
        maxWidth='700px'
      >
        {description}
      </Text>
    );
  }

  return <>{description}</>;
}
