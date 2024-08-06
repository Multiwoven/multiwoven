import ContentContainer from '@/components/ContentContainer';
import { SteppedFormContext } from '@/components/SteppedForm/SteppedForm';
import { ModelEntity } from '@/views/Models/types';
import { Box } from '@chakra-ui/react';
import { FormEvent, useContext, Dispatch, SetStateAction, useState, useEffect } from 'react';
import SelectStreams from './SelectStreams';
import { Stream, FieldMap as FieldMapType } from '@/views/Activate/Syncs/types';
import MapFields from './MapFields';
import { ConnectorItem } from '@/views/Connectors/types';
import FormFooter from '@/components/FormFooter';
import MapCustomFields from './MapCustomFields';
import { useQuery } from '@tanstack/react-query';
import { getCatalog } from '@/services/syncs';
import { SchemaMode } from '@/views/Activate/Syncs/types';
import Loader from '@/components/Loader';
import { useStore } from '@/stores';

type ConfigureSyncsProps = {
  selectedStream: Stream | null;
  configuration: FieldMapType[] | null;
  schemaMode: SchemaMode | null;
  selectedSyncMode: string;
  cursorField: string;
  setSelectedStream: Dispatch<SetStateAction<Stream | null>>;
  setConfiguration: Dispatch<SetStateAction<FieldMapType[] | null>>;
  setSchemaMode: Dispatch<SetStateAction<SchemaMode | null>>;
  setSelectedSyncMode: Dispatch<SetStateAction<string>>;
  setCursorField: Dispatch<SetStateAction<string>>;
};

const ConfigureSyncs = ({
  selectedStream,
  configuration,
  selectedSyncMode,
  cursorField,
  setSelectedStream,
  setConfiguration,
  setSchemaMode,
  setSelectedSyncMode,
  setCursorField,
}: ConfigureSyncsProps): JSX.Element | null => {
  const { state, stepInfo, handleMoveForward } = useContext(SteppedFormContext);
  const [refresh, setRefresh] = useState(false);

  const { forms } = state;

  const modelInfo = forms.find((form) => form.stepKey === 'selectModel');
  const selectedModel = modelInfo?.data?.selectModel as ModelEntity;

  const destinationInfo = forms.find((form) => form.stepKey === 'selectDestination');
  const selectedDestination = destinationInfo?.data?.selectDestination as ConnectorItem;

  const activeWorkspaceId = useStore((state) => state.workspaceId);

  const handleOnStreamChange = (stream: Stream) => {
    setSelectedStream(stream);
  };

  const handleOnConfigChange = (config: FieldMapType[]) => {
    setConfiguration(config);
  };

  const handleOnSubmit = (e: FormEvent) => {
    e.preventDefault();
    const payload = {
      source_id: selectedModel?.connector?.id,
      destination_id: selectedDestination.id,
      model_id: selectedModel.id,
      stream_name: selectedStream?.name,
      configuration,
      sync_mode: selectedSyncMode,
      cursor_field: cursorField,
    };

    handleMoveForward(stepInfo?.formKey as string, payload);
  };

  const { data: catalogData, refetch } = useQuery({
    queryKey: ['syncs', 'catalog', selectedDestination?.id, activeWorkspaceId],
    queryFn: () => getCatalog(selectedDestination?.id, refresh),
    enabled: !!selectedDestination?.id && activeWorkspaceId > 0,
    refetchOnMount: false,
    refetchOnWindowFocus: false,
  });

  const handleRefreshCatalog = () => {
    setRefresh(true);
  };

  useEffect(() => {
    if (refresh) {
      refetch();
      setRefresh(false);
    }
  }, [refresh]);

  if (!catalogData?.data?.attributes?.catalog?.schema_mode) {
    return <Loader />;
  }

  if (catalogData?.data?.attributes?.catalog?.schema_mode === SchemaMode.schemaless) {
    setSchemaMode(SchemaMode.schemaless);
  }

  const streams = catalogData?.data?.attributes?.catalog?.streams || [];

  return (
    <Box width='100%' display='flex' justifyContent='center'>
      <ContentContainer>
        <form onSubmit={handleOnSubmit}>
          <SelectStreams
            model={selectedModel}
            onChange={handleOnStreamChange}
            destination={selectedDestination}
            selectedStream={selectedStream}
            setSelectedSyncMode={setSelectedSyncMode}
            selectedSyncMode={selectedSyncMode}
            selectedCursorField={cursorField}
            setCursorField={setCursorField}
            streams={streams}
          />
          {catalogData?.data?.attributes?.catalog?.schema_mode === SchemaMode.schemaless ? (
            <MapCustomFields
              model={selectedModel}
              destination={selectedDestination}
              handleOnConfigChange={handleOnConfigChange}
              configuration={configuration}
              stream={selectedStream}
            />
          ) : (
            <MapFields
              model={selectedModel}
              destination={selectedDestination}
              stream={selectedStream}
              handleOnConfigChange={handleOnConfigChange}
              configuration={configuration}
              handleRefreshCatalog={handleRefreshCatalog}
            />
          )}

          <FormFooter
            ctaName='Continue'
            ctaType='submit'
            isCtaDisabled={!selectedStream || !SchemaMode.schemaless}
            isBackRequired
            isContinueCtaRequired
            isDocumentsSectionRequired
          />
        </form>
      </ContentContainer>
    </Box>
  );
};

export default ConfigureSyncs;
