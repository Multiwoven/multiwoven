import ContentContainer from '@/components/ContentContainer';
import { SteppedFormContext } from '@/components/SteppedForm/SteppedForm';
import { ModelEntity } from '@/views/Models/types';
import { Box } from '@chakra-ui/react';
import { FormEvent, useContext, Dispatch, SetStateAction, useState } from 'react';
import SelectStreams from './SelectStreams';
import { Stream, FieldMap as FieldMapType } from '@/views/Activate/Syncs/types';
import MapFields from './MapFields';
import { ConnectorItem } from '@/views/Connectors/types';
import SourceFormFooter from '@/views/Connectors/Sources/SourcesForm/SourceFormFooter';
import MapCustomFields from './MapCustomFields';
import { useQuery } from '@tanstack/react-query';
import { getCatalog } from '@/services/syncs';
import { SchemaMode } from '@/views/Activate/Syncs/types';
import Loader from '@/components/Loader';

type ConfigureSyncsProps = {
  selectedStream: Stream | null;
  configuration: FieldMapType[] | null;
  schemaMode: SchemaMode | null;
  setSelectedStream: Dispatch<SetStateAction<Stream | null>>;
  setConfiguration: Dispatch<SetStateAction<FieldMapType[] | null>>;
  setSchemaMode: Dispatch<SetStateAction<SchemaMode | null>>;
};

const ConfigureSyncs = ({
  selectedStream,
  configuration,
  setSelectedStream,
  setConfiguration,
  setSchemaMode,
}: ConfigureSyncsProps): JSX.Element | null => {
  const { state, stepInfo, handleMoveForward } = useContext(SteppedFormContext);
  const [selectedSyncMode, setSelectedSyncMode] = useState('');
  const { forms } = state;

  const modelInfo = forms.find((form) => form.stepKey === 'selectModel');
  const selectedModel = modelInfo?.data?.selectModel as ModelEntity;

  const destinationInfo = forms.find((form) => form.stepKey === 'selectDestination');
  const selectedDestination = destinationInfo?.data?.selectDestination as ConnectorItem;

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
    };

    handleMoveForward(stepInfo?.formKey as string, payload);
  };

  const { data: catalogData } = useQuery({
    queryKey: ['syncs', 'catalog', selectedDestination.id],
    queryFn: () => getCatalog(selectedDestination.id),
    enabled: !!selectedDestination.id,
    refetchOnMount: false,
    refetchOnWindowFocus: false,
  });

  if (!catalogData?.data?.attributes?.catalog?.schema_mode) {
    return <Loader />;
  }

  if (catalogData?.data?.attributes?.catalog?.schema_mode === SchemaMode.schemaless) {
    setSchemaMode(SchemaMode.schemaless);
  }

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
          />
          {catalogData?.data?.attributes?.catalog?.schema_mode === SchemaMode.schemaless ? (
            <MapCustomFields
              model={selectedModel}
              destination={selectedDestination}
              handleOnConfigChange={handleOnConfigChange}
              configuration={configuration}
            />
          ) : (
            <MapFields
              model={selectedModel}
              destination={selectedDestination}
              stream={selectedStream}
              handleOnConfigChange={handleOnConfigChange}
              configuration={configuration}
            />
          )}

          <SourceFormFooter
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
