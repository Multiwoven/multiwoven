import ContentContainer from "@/components/ContentContainer";
import { SteppedFormContext } from "@/components/SteppedForm/SteppedForm";
import { getCatalog } from "@/services/syncs";
import { ModelEntity } from "@/views/Models/types";
import { Box } from "@chakra-ui/react";
import { useQuery } from "@tanstack/react-query";
import { useContext, useState } from "react";
import SelectStreams from "./SelectStreams";
import { Stream } from "../../types";
import MapFields from "./MapFields";
import { ConnectorItem } from "@/views/Connectors/types";

const ConfigureSyncs = (): JSX.Element | null => {
  const [selectedStream, setSelectedStream] = useState<Stream | null>(null);
  const { state } = useContext(SteppedFormContext);
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

  return (
    <Box width="100%" display="flex" justifyContent="center">
      <ContentContainer>
        <SelectStreams
          model={selectedModel}
          onChange={handleOnStreamChange}
          streams={catalogData?.data?.attributes?.catalog?.streams}
        />
        <MapFields
          model={selectedModel}
          destination={selectedDestination}
          stream={selectedStream}
        />
      </ContentContainer>
    </Box>
  );
};

export default ConfigureSyncs;
