import { useQuery } from "@tanstack/react-query";
import DefineSQL from "../ModelsForm/DefineModel/DefineSQL";
import { useParams } from "react-router-dom";
import { Box } from "@chakra-ui/react";
import { getModelById } from "@/services/models";
import { PrefillValue } from "../ModelsForm/DefineModel/DefineSQL/types";
import TopBar from "@/components/TopBar";
import { useRef } from "react";
import ContentContainer from "@/components/ContentContainer";
import EntityItem from "@/components/EntityItem";

const EditModel = (): JSX.Element => {
  const params = useParams();
  const containerRef = useRef(null);

  const model_id = params.id || "";

  const { data, isLoading, isError } = useQuery({
    queryKey: ["modelByID"],
    queryFn: () => getModelById(model_id || ""),
    refetchOnMount: true,
    refetchOnWindowFocus: true,
  });

  console.log(data);

  const prefillValues: PrefillValue = {
    connector_id: data?.data?.attributes.connector.id || "",
    connector_icon: (
      <EntityItem
        name={data?.data?.attributes.connector.name || ""}
        icon={data?.data?.attributes.connector.icon || ""}
      />
    ),
    connector_name: data?.data?.attributes.connector.name || "",
    model_name: data?.data?.attributes.name || "",
    model_description: data?.data?.attributes.description || "",
    primary_key: data?.data?.attributes.primary_key || "",
    query: data?.data?.attributes.query || "",
    query_type: data?.data?.attributes.query_type || "",
    model_id: model_id,
  };

  if (isLoading) {
    return <>Loading....</>;
  }

  if (isError) {
    return <>Error....</>;
  }

  return (
    <Box width="100%" display="flex" justifyContent="center">
      <ContentContainer containerRef={containerRef}>
        <TopBar name={prefillValues.model_name} />
        <DefineSQL
          isFooterVisible={false}
          hasPrefilledValues={true}
          prefillValues={prefillValues}
          isUpdateButtonVisible={true}
        />
      </ContentContainer>
    </Box>
  );
};

export default EditModel;
