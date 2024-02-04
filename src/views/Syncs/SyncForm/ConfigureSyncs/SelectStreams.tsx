import { Box, Text, Select } from "@chakra-ui/react";
import { Stream } from "../../types";

type SelectStreamsProps = {
  streams: Stream[];
  onChange: (stream: Stream) => void;
};

const SelectStreams = ({
  streams,
  onChange,
}: SelectStreamsProps): JSX.Element => {
  const handleOnStreamChange = (streamNumber: string) => {
    if (!streamNumber) return;

    const selectedStream = streams[parseInt(streamNumber)];
    onChange?.(selectedStream);
  };
  return (
    <Box backgroundColor="gray.200" padding="20px" borderRadius="8px">
      <Text fontWeight="600" marginBottom="30px">
        Configure sync to Klaviyo
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
