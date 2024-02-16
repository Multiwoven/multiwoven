import { Box, Text, Select } from '@chakra-ui/react';
import { DiscoverResponse, Stream } from '@/views/Activate/Syncs/types';
import { ModelEntity } from '@/views/Models/types';
import { useQuery } from '@tanstack/react-query';
import { getCatalog } from '@/services/syncs';
import { ConnectorItem } from '@/views/Connectors/types';
import { useEffect } from 'react';

type SelectStreamsProps = {
  model: ModelEntity;
  destination: ConnectorItem;
  isEdit?: boolean;
  placeholder?: string;
  onChange?: (stream: Stream) => void;
  onStreamsLoad?: (catalog: DiscoverResponse) => void;
  selectedStream?: Stream | null;
};

const SelectStreams = ({
  model,
  destination,
  isEdit,
  placeholder,
  onChange,
  onStreamsLoad,
  selectedStream,
}: SelectStreamsProps): JSX.Element | null => {
  const { data: catalogData } = useQuery({
    queryKey: ['syncs', 'catalog', destination.id],
    queryFn: () => getCatalog(destination.id),
    enabled: !!destination.id,
    refetchOnMount: false,
    refetchOnWindowFocus: false,
  });

  useEffect(() => {
    if (catalogData) {
      onStreamsLoad?.(catalogData);
    }
  }, [catalogData]);

  const streams = catalogData?.data?.attributes?.catalog?.streams;

  const handleOnStreamChange = (streamNumber: string) => {
    if (!streamNumber) return;

    if (streams) {
      const selectedStream = streams[parseInt(streamNumber)];
      onChange?.(selectedStream);
    }
  };

  const selectedStreamIndex = streams?.findIndex(
    (stream) => stream.name === selectedStream?.name
  );

  return (
    <Box
      backgroundColor='gray.300'
      padding='20px'
      borderRadius='8px'
      marginBottom='20px'
    >
      <Text fontWeight='600' mb={6} color='black.500' size='md'>
        Configure sync to {model?.connector?.connector_name}
      </Text>
      <Text fontWeight='600'>Stream Name</Text>
      <Text fontSize='sm' marginBottom='10px'>
        {isEdit
          ? 'You cannot change the API once the mapping is done.'
          : 'Select the API from the destination that you wish to map.'}
      </Text>
      <Select
        placeholder={isEdit ? placeholder : 'Select option'}
        backgroundColor='#fff'
        maxWidth='500px'
        onChange={(e) => handleOnStreamChange(e.target.value)}
        isDisabled={isEdit}
        value={selectedStreamIndex}
      >
        {streams?.map((stream, index) => (
          <option key={stream.name} value={index}>
            {stream.name}
          </option>
        ))}
      </Select>
    </Box>
  );
};

export default SelectStreams;
