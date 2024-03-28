import { Box, Text, Select } from '@chakra-ui/react';
import { DiscoverResponse, Stream } from '@/views/Activate/Syncs/types';
import { ModelEntity } from '@/views/Models/types';
import { useQuery } from '@tanstack/react-query';
import { getCatalog } from '@/services/syncs';
import { ConnectorItem } from '@/views/Connectors/types';
import { useEffect, SetStateAction, Dispatch } from 'react';

type SelectStreamsProps = {
  model: ModelEntity;
  destination: ConnectorItem;
  selectedStreamName?: string;
  selectedSyncMode?: string;
  isEdit?: boolean;
  placeholder?: string;
  onChange?: (stream: Stream) => void;
  onStreamsLoad?: (catalog: DiscoverResponse) => void;
  selectedStream?: Stream | null;
  setSelectedSyncMode?: Dispatch<SetStateAction<string>>;
};

const SelectStreams = ({
  model,
  destination,
  selectedSyncMode,
  selectedStreamName,
  isEdit,
  placeholder,
  onChange,
  onStreamsLoad,
  selectedStream,
  setSelectedSyncMode,
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
  let selectedStreamIndex = -1;

  const handleOnStreamChange = (streamNumber: string) => {
    if (!streamNumber) return;

    if (streams) {
      const selectedStream = streams[parseInt(streamNumber)];
      onChange?.(selectedStream);
    }
  };

  if (isEdit) {
    selectedStreamIndex = streams?.findIndex(
      (stream) => stream.name === selectedStreamName,
    ) as number;
  } else {
    selectedStreamIndex = streams?.findIndex(
      (stream) => stream.name === selectedStream?.name,
    ) as number;
  }

  const refreshOptions =
    selectedStreamIndex !== -1
      ? streams?.[selectedStreamIndex]?.supported_sync_modes?.map((syncMode: string) => {
          return { value: syncMode, label: syncMode };
        })
      : [];

  return (
    <Box
      backgroundColor={isEdit ? 'gray.100' : 'gray.200'}
      padding='24px'
      borderRadius='8px'
      marginBottom='20px'
    >
      <Text fontWeight='600' mb={6} color='black.500' size='md'>
        Configure sync to {model?.connector?.connector_name}
      </Text>
      <Box display='flex' alignItems='flex-end' gap='12px'>
        <Box width='100%'>
          <Text fontWeight='semibold' size='sm'>
            Stream Name
          </Text>
          <Text size='xs' marginBottom='12px' color='black.200'>
            {isEdit
              ? 'You cannot change the API once the mapping is done.'
              : 'Select the API from the destination that you wish to map.'}
          </Text>
          <Select
            placeholder={isEdit ? placeholder : 'Select option'}
            backgroundColor={isEdit ? 'gray.300' : 'gray.100'}
            maxWidth='500px'
            onChange={(e) => handleOnStreamChange(e.target.value)}
            isDisabled={isEdit}
            value={selectedStreamIndex}
            borderStyle='solid'
            borderWidth='1px'
            borderColor='gray.400'
            fontSize='14px'
          >
            {streams?.map((stream, index) => (
              <option key={stream.name} value={index}>
                {stream.name}
              </option>
            ))}
          </Select>
        </Box>
        <Box width='80px' padding='20px' position='relative' top='8px' color='gray.600'></Box>
        <Box width='100%'>
          <Text fontWeight='semibold' size='sm'>
            Sync Mode
          </Text>
          <Text size='xs' marginBottom='12px' color='black.200'>
            Select a desired synchronisation mode based on your requirement.
          </Text>
          <Select
            placeholder={isEdit ? placeholder : 'Select sync mode'}
            backgroundColor={'gray.100'}
            maxWidth='500px'
            onChange={({ target: { value } }) => setSelectedSyncMode?.(value)}
            value={selectedSyncMode}
            borderStyle='solid'
            borderWidth='1px'
            borderColor='gray.400'
            fontSize='14px'
          >
            {refreshOptions?.map((refreshMode) => (
              <option value={refreshMode.value} key={refreshMode.value}>
                {refreshMode.label}
              </option>
            ))}
          </Select>
        </Box>
      </Box>
    </Box>
  );
};

export default SelectStreams;
