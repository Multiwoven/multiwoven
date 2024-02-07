import ContentContainer from "@/components/ContentContainer";
import { SteppedFormContext } from "@/components/SteppedForm/SteppedForm";
import { getCatalog } from "@/services/syncs";
import { ModelEntity } from "@/views/Models/types";
import { Box } from "@chakra-ui/react";
import { useQuery } from "@tanstack/react-query";
import { FormEvent, useContext, useState } from "react";
import SelectStreams from "./SelectStreams";
import { Stream } from "@/views/Activate/Syncs/types";
import MapFields from "./MapFields";
import { ConnectorItem } from "@/views/Connectors/types";
import SourceFormFooter from "@/views/Connectors/Sources/SourcesForm/SourceFormFooter";

const ConfigureSyncs = (): JSX.Element | null => {
  const [selectedStream, setSelectedStream] = useState<Stream | null>(null);
  const [configuration, setConfiguration] = useState<Record<
    string,
    string
  > | null>(null);
  const { state, stepInfo, handleMoveForward } = useContext(SteppedFormContext);
  const { forms } = state;

  const modelInfo = forms.find((form) => form.stepKey === "selectModel");
  const selectedModel = modelInfo?.data?.selectModel as ModelEntity;

  const destinationInfo = forms.find(
    (form) => form.stepKey === "selectDestination"
  );
  const selectedDestination = destinationInfo?.data
    ?.selectDestination as ConnectorItem;
  const destinationId = selectedDestination?.id;

  const { data: catalogData } = useQuery({
    queryKey: ["syncs", "catalog", destinationId],
    queryFn: () => getCatalog(destinationId),
    enabled: !!destinationId,
    refetchOnMount: false,
    refetchOnWindowFocus: false,
  });

  if (!catalogData) return null;

  const handleOnStreamChange = (stream: Stream) => {
    setSelectedStream(stream);
  };

  const handleOnConfigChange = (config: Record<string, string>) => {
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
    <Box width="100%" display="flex" justifyContent="center">
      <ContentContainer>
        <form onSubmit={handleOnSubmit}>
          <SelectStreams
            model={selectedModel}
            onChange={handleOnStreamChange}
            streams={catalogData?.data?.attributes?.catalog?.streams}
          />
          <MapFields
            model={selectedModel}
            destination={selectedDestination}
            stream={selectedStream}
            handleOnConfigChange={handleOnConfigChange}
          />
          <SourceFormFooter
            ctaName="Continue"
            ctaType="submit"
            isCtaDisabled={!selectedStream}
          />
        </form>
      </ContentContainer>
    </Box>
  );
};

export default ConfigureSyncs;
