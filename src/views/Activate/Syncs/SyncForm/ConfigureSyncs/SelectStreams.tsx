import { Box, Text, Select } from '@chakra-ui/react';
import { Stream } from '../../types';
import { ModelEntity } from '@/views/Models/types';

type SelectStreamsProps = {
  model: ModelEntity;
  streams: Stream[];
  onChange: (stream: Stream) => void;
};

const SelectStreams = ({
  model,
  streams,
  onChange,
}: SelectStreamsProps): JSX.Element => {
  const handleOnStreamChange = (streamNumber: string) => {
    if (!streamNumber) return;

    const selectedStream = streams[parseInt(streamNumber)];
    onChange?.(selectedStream);
  };
  return (
    <Box
      backgroundColor='gray.300'
      padding='20px'
      borderRadius='8px'
      marginBottom='20px'
    >
      <Text
        fontWeight='600'
        mb={6}
        color='black.500'
        size='md'
      >
        Configure sync to {model?.connector?.connector_name}
      </Text>
      <Text
        fontWeight='600'
        color='black.500'
        size='sm'
      >
        Stream Name
      </Text>
      <Text size='xs' mb='3' color='black.200' fontWeight={400}>
        Select the API from the Destination that you wish to map.
      </Text>
      <Select
        placeholder='Select stream name'
        backgroundColor='#fff'
        maxWidth='500px'
        onChange={(e) => handleOnStreamChange(e.target.value)}
        borderWidth='1px'
        borderStyle='solid'
        borderColor='gray.400'
        color="gray.600"
      >
        {streams.map((stream, index) => (
          <option key={stream.name} value={index}>
            {stream.name}
          </option>
        ))}
      </Select>
    </Box>
  );
};

export default SelectStreams;
