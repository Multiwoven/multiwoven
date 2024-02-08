import { Box, Text, Select } from "@chakra-ui/react";
import { Stream } from "../../types";
import { ModelEntity } from "@/views/Models/types";

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
      backgroundColor="gray.300"
      padding="20px"
      borderRadius="8px"
      marginBottom="20px"
    >
      <Text fontWeight="600" marginBottom="30px">
        Configure sync to {model?.connector?.connector_name}
      </Text>
      <Text fontWeight="600">Stream Name</Text>
      <Text fontSize="sm" marginBottom="10px">
        Select the API from the destination that you wish to map.
      </Text>
      <Select
        placeholder="Select option"
        backgroundColor="#fff"
        maxWidth="500px"
        onChange={(e) => handleOnStreamChange(e.target.value)}
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
