import ContentContainer from "@/components/ContentContainer";
import { SteppedFormContext } from "@/components/SteppedForm/SteppedForm";
import { getModelPreview } from "@/services/models";
import { getCatalog } from "@/services/syncs";
import { ModelEntity } from "@/views/Models/types";
import { Box } from "@chakra-ui/react";
import { useQuery } from "@tanstack/react-query";
import { useContext, useState } from "react";
import SelectStreams from "./SelectStreams";
import { Stream } from "../../types";

const ConfigureSyncs = (): JSX.Element | null => {
  const [selectedStream, setSelectedStream] = useState<Stream | null>(null);
  const { state } = useContext(SteppedFormContext);
  const { forms } = state;

  const modelInfo = forms.find((form) => form.stepKey === "selectModel");
  const selectedModel = modelInfo?.data?.selectModel as ModelEntity;
  const sourceId = selectedModel?.connector?.id;

  const destinationInfo = forms.find(
    (form) => form.stepKey === "selectDestination"
  );
  const selectedDestination = destinationInfo?.data
    ?.selectDestination as ModelEntity;
  const destinationId = selectedDestination?.id;

  const { data: previewModelData } = useQuery({
    queryKey: ["syncs", "preview-model", selectedModel?.id],
    queryFn: () => getModelPreview(selectedModel?.query, selectedModel?.id),
    enabled: !!selectedModel?.id,
    refetchOnMount: false,
    refetchOnWindowFocus: false,
  });

  const { data: catalogData } = useQuery({
    queryKey: ["syncs", "catalog", destinationId],
    queryFn: () => getCatalog(destinationId),
    enabled: !!destinationId,
    refetchOnMount: false,
    refetchOnWindowFocus: false,
  });

  if (!previewModelData || !catalogData) return null;

  const modelColumns = Object.keys(previewModelData?.data?.data?.[0]);

  const handleOnStreamChange = (stream: Stream) => {
    setSelectedStream(stream);
  };

  return (
    <Box width="100%" display="flex" justifyContent="center">
      <ContentContainer>
        <SelectStreams
          onChange={handleOnStreamChange}
          streams={catalogData?.data?.attributes?.catalog?.streams}
        />
      </ContentContainer>
    </Box>
  );
};

export default ConfigureSyncs;
