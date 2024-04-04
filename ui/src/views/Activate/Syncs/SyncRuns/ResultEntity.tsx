import { Box, Text } from '@chakra-ui/react';

type ResultEntityProps = {
  total_value: number;
  current_value: number;
  result_text: string;
  current_text_color: string;
};

export const ResultEntity = ({
  total_value,
  current_value,
  result_text,
  current_text_color,
}: ResultEntityProps): JSX.Element => (
  <Box display='flex' flexDir='column'>
    <Box display='flex' flexDir='row'>
      <Text color={current_text_color} fontSize='sm'>
        {current_value}
      </Text>
      <Text fontSize={'xs'} mt={'1px'}>
        /{total_value}
      </Text>
    </Box>
    <Text>{result_text}</Text>
  </Box>
);
