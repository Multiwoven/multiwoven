import { Box, Text, Select, Tooltip, Input } from '@chakra-ui/react';
import { DiscoverResponse, Stream } from '@/views/Activate/Syncs/types';
import { ModelEntity } from '@/views/Models/types';
import { useQuery } from '@tanstack/react-query';
import { getCatalog } from '@/services/syncs';
import { ConnectorItem } from '@/views/Connectors/types';
import { getModelPreviewById } from '@/services/models';
import { useEffect, SetStateAction, Dispatch } from 'react';
import { FiInfo } from 'react-icons/fi';
import { useStore } from '@/stores';

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
  setCursorField?: Dispatch<SetStateAction<string>>;
  selectedCursorField?: string;
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
  selectedCursorField,
  setCursorField,
}: SelectStreamsProps): JSX.Element | null => {
  const activeWorkspaceId = useStore((state) => state.workspaceId);

  const { data: catalogData } = useQuery({
    queryKey: ['syncs', 'catalog', destination.id, activeWorkspaceId],
    queryFn: () => getCatalog(destination.id),
    enabled: !!destination.id && activeWorkspaceId > 0,
    refetchOnMount: false,
    refetchOnWindowFocus: false,
  });

  const { data: modelDiscoverData } = useQuery({
    queryKey: ['syncs', 'catalog', model.id, activeWorkspaceId],
    queryFn: () => getCatalog(model.id),
    enabled: !!model.id && activeWorkspaceId > 0,
    refetchOnMount: false,
    refetchOnWindowFocus: false,
  });

  const { data: previewModelData } = useQuery({
    queryKey: ['syncs', 'preview-model', model?.connector?.id, activeWorkspaceId],
    queryFn: () => getModelPreviewById(model?.query, String(model?.connector?.id)),
    enabled: !!model?.connector?.id && activeWorkspaceId > 0,
    refetchOnMount: true,
    refetchOnWindowFocus: false,
  });

  const firstRow = Array.isArray(previewModelData) && previewModelData[0];

  const modelColumns = Object.keys(firstRow ?? {});

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

  const sourceDefinedCursor = modelDiscoverData?.data?.attributes?.catalog?.source_defined_cursor;

  return (
    <Box
      backgroundColor={isEdit ? 'gray.100' : 'gray.200'}
      padding='24px'
      borderRadius='8px'
      marginBottom='20px'
    >
      <Text fontWeight='600' mb={6} color='black.500' size='md'>
        Configure sync to {destination.attributes.connector_name}.
      </Text>
      <Box display='flex' alignItems='flex-end' gap='36px'>
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
            isRequired
          >
            {refreshOptions?.map((refreshMode) => (
              <option value={refreshMode.value} key={refreshMode.value}>
                {refreshMode.label}
              </option>
            ))}
          </Select>
        </Box>
        {!sourceDefinedCursor && selectedSyncMode === 'incremental' && (
          <Box width='100%'>
            <Box display='flex' alignItems='center'>
              <Text fontWeight='semibold' size='sm'>
                Cursor Field
              </Text>
              <Tooltip
                hasArrow
                label='Cursor-based incremental refresh is utilized by sources to track new or updated records since the last sync, using the cursor field.'
                fontSize='xs'
                placement='top'
                backgroundColor='black.500'
                color='gray.100'
                borderRadius='6px'
                padding='8px'
                width='auto'
                marginLeft='8px'
              >
                <Text color='gray.600' marginLeft='8px'>
                  <FiInfo />
                </Text>
              </Tooltip>
            </Box>
            <Text size='xs' marginBottom='12px' color='black.200'>
              Select cursor field. Ignore if you are unsure about which field to select
            </Text>
            {isEdit ? (
              <Input
                backgroundColor={'gray.100'}
                maxWidth='500px'
                value={selectedCursorField}
                borderStyle='solid'
                borderWidth='1px'
                borderColor='gray.400'
                fontSize='14px'
                disabled
              />
            ) : (
              <Select
                placeholder={'Select cursor field'}
                backgroundColor={'gray.100'}
                maxWidth='500px'
                onChange={({ target: { value } }) => setCursorField?.(value)}
                value={selectedCursorField}
                borderStyle='solid'
                borderWidth='1px'
                borderColor='gray.400'
                fontSize='14px'
              >
                {modelColumns?.map((modelColumn) => (
                  <option value={modelColumn} key={modelColumn}>
                    {modelColumn}
                  </option>
                ))}
              </Select>
            )}
          </Box>
        )}
      </Box>
    </Box>
  );
};

export default SelectStreams;
