import { ConnectorItem } from "@/views/Connectors/types";
import { ModelEntity } from "@/views/Models/types";
import { Box, Button, IconButton, Select, Text } from "@chakra-ui/react";
import { getModelPreview } from "@/services/models";
import { useQuery } from "@tanstack/react-query";
import { Stream } from "../../types";
import EntityItem from "@/components/EntityItem";
import FieldMap from "./FieldMap";
import { convertSchemaToObject, getPathFromObject } from "../../utils";
import React, { useMemo, useState } from "react";
import { ArrowRightIcon } from "@heroicons/react/24/outline";
import { FiDelete } from "react-icons/fi";

type MapFieldsProps = {
  model: ModelEntity;
  destination: ConnectorItem;
  stream: Stream | null;
};

const FieldStruct = {
  modelColumn: null,
  destinationColumn: null,
};

const MapFields = ({
  model,
  destination,
  stream,
}: MapFieldsProps): JSX.Element | null => {
  const [fields, setFields] = useState([FieldStruct]);
  const { data: previewModelData } = useQuery({
    queryKey: ["syncs", "preview-model", model?.id],
    queryFn: () => getModelPreview(model?.query, model?.id),
    enabled: !!model?.id,
    refetchOnMount: false,
    refetchOnWindowFocus: false,
  });

  if (!previewModelData) return null;

  const sourceId = model?.connector?.id;
  const modelColumns = Object.keys(previewModelData?.data?.data?.[0] ?? {});

  const destinationColumns = useMemo(
    () => getPathFromObject(stream?.json_schema),
    [stream]
  );

  const handleOnAppendField = () => {
    setFields([...fields, FieldStruct]);
  };

  const handleOnChange = () => {};

  return (
    <Box backgroundColor="gray.200" padding="20px" borderRadius="8px">
      <Text fontWeight="600">
        Map fields to {destination?.attributes?.connector_name}
      </Text>
      <Text fontSize="sm" marginBottom="30px">
        Select the API from the destination that you wish to map.
      </Text>

      {fields.map(() => (
        <Box display="flex" alignItems="flex-end" marginBottom="30px">
          <FieldMap
            fieldType="model"
            entityName={model.connector.connector_name}
            icon={model.icon}
            options={modelColumns}
            onChange={handleOnChange}
            isDisabled={!stream}
          />
          <Box width="80px" padding="20px" position="relative" top="8px">
            <ArrowRightIcon />
          </Box>
          <FieldMap
            fieldType="destination"
            entityName={destination.attributes.connector_name}
            icon={destination.attributes.icon}
            options={destinationColumns}
            onChange={handleOnChange}
            isDisabled={!stream}
          />
        </Box>
      ))}

      <Box>
        <Button variant="secondary" onClick={handleOnAppendField}>
          Add mapping
        </Button>
      </Box>
    </Box>
  );
};

export default MapFields;
