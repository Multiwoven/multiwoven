import ContentContainer from '@/components/ContentContainer';
import { SteppedFormContext } from '@/components/SteppedForm/SteppedForm';
import { ModelEntity } from '@/views/Models/types';
import { Box } from '@chakra-ui/react';
import { FormEvent, useContext, Dispatch, SetStateAction } from 'react';
import SelectStreams from './SelectStreams';
import { Stream, FieldMap as FieldMapType } from '@/views/Activate/Syncs/types';
import MapFields from './MapFields';
import { ConnectorItem } from '@/views/Connectors/types';
import SourceFormFooter from '@/views/Connectors/Sources/SourcesForm/SourceFormFooter';

type ConfigureSyncsProps = {
  selectedStream: Stream | null;
  configuration: FieldMapType[] | null;
  setSelectedStream: Dispatch<SetStateAction<Stream | null>>;
  setConfiguration: Dispatch<SetStateAction<FieldMapType[] | null>>;
};

const ConfigureSyncs = ({
  selectedStream,
  configuration,
  setSelectedStream,
  setConfiguration,
}: ConfigureSyncsProps): JSX.Element | null => {
  const { state, stepInfo, handleMoveForward } = useContext(SteppedFormContext);
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
    };

    handleMoveForward(stepInfo?.formKey as string, payload);
  };

  return (
    <Box width='100%' display='flex' justifyContent='center'>
      <ContentContainer>
        <form onSubmit={handleOnSubmit}>
          <SelectStreams
            model={selectedModel}
            onChange={handleOnStreamChange}
            destination={selectedDestination}
            selectedStream={selectedStream}
          />
          <MapFields
            model={selectedModel}
            destination={selectedDestination}
            stream={selectedStream}
            handleOnConfigChange={handleOnConfigChange}
            configuration={configuration}
          />
          <SourceFormFooter
            ctaName='Continue'
            ctaType='submit'
            isCtaDisabled={!selectedStream}
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
