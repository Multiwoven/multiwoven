import { ConnectorItem } from "@/views/Connectors/types";
import { ModelEntity } from "@/views/Models/types";
import { Box, Button, CloseButton, Text } from "@chakra-ui/react";
import { getModelPreviewById } from "@/services/models";
import { useQuery } from "@tanstack/react-query";
import { FieldMap as FieldMapType, Stream } from "@/views/Activate/Syncs/types";
import FieldMap from "./FieldMap";
import {
  convertFieldMapToConfig,
  getPathFromObject,
} from "@/views/Activate/Syncs/utils";
import { useEffect, useMemo, useState } from "react";
import { ArrowRightIcon } from "@heroicons/react/24/outline";

type MapFieldsProps = {
  model: ModelEntity;
  destination: ConnectorItem;
  stream: Stream | null;
  data?: Record<string, string>;
  isEdit?: boolean;
  handleOnConfigChange: (args: Record<string, string>) => void;
};

const FieldStruct: FieldMapType = {
  model: "",
  destination: "",
};

const MapFields = ({
  model,
  destination,
  stream,
  data,
  isEdit,
  handleOnConfigChange,
}: MapFieldsProps): JSX.Element | null => {
  const [fields, setFields] = useState<FieldMapType[]>([FieldStruct]);
  const { data: previewModelData } = useQuery({
    queryKey: ["syncs", "preview-model", model?.connector?.id],
    queryFn: () =>
      getModelPreviewById(model?.query, String(model?.connector?.id)),
    enabled: !!model?.connector?.id,
    refetchOnMount: true,
    refetchOnWindowFocus: false,
  });

  const destinationColumns = useMemo(
    () => getPathFromObject(stream?.json_schema),
    [stream]
  );

  useEffect(() => {
    if (data) {
      const fields = Object.keys(data).map((modelKey) => ({
        model: modelKey,
        destination: data[modelKey],
      }));
      setFields(fields);
    }
  }, [data]);

  if (!previewModelData || !Array.isArray(previewModelData)) return null;

  const firstRow = previewModelData[0];

  const modelColumns = Object.keys(firstRow ?? {});

  const handleOnAppendField = () => {
    setFields([...fields, FieldStruct]);
  };

  const handleOnChange = (
    id: number,
    type: "model" | "destination",
    value: string
  ) => {
    const fieldsClone = [...fields];
    fieldsClone[id] = {
      ...fieldsClone[id],
      [type]: value,
    };
    setFields(fieldsClone);
    handleOnConfigChange(convertFieldMapToConfig(fieldsClone));
  };

  const handleRemoveMap = (id: number) => {
    const newFields = fields.filter((_, index) => index !== id);
    setFields(newFields);
    handleOnConfigChange(convertFieldMapToConfig(newFields));
  };

  const mappedColumns = fields.map((item) => item.model);

  return (
    <Box
      backgroundColor="gray.300"
      padding="20px"
      borderRadius="8px"
      marginBottom={isEdit ? "20px" : "100px"}
    >
      <Text fontWeight="600">
        Map fields to {destination?.attributes?.connector_name}
      </Text>
      <Text fontSize="sm" marginBottom="30px">
        Select the API from the destination that you wish to map.
      </Text>
      {fields.map((_, index) => (
        <Box
          key={`field-map-${index}`}
          display="flex"
          alignItems="flex-end"
          marginBottom="30px"
        >
          <FieldMap
            id={index}
            fieldType="model"
            entityName={model.connector.connector_name}
            icon={model.connector.icon}
            options={modelColumns}
            disabledOptions={mappedColumns}
            value={fields[index].model}
            onChange={handleOnChange}
            isDisabled={!stream}
          />
          <Box width="80px" padding="20px" position="relative" top="8px">
            <ArrowRightIcon />
          </Box>
          <FieldMap
            id={index}
            fieldType="destination"
            entityName={destination.attributes.connector_name}
            icon={destination.attributes.icon}
            options={destinationColumns}
            value={fields[index].destination}
            onChange={handleOnChange}
            isDisabled={!stream}
          />
          <Box>
            <CloseButton
              size="sm"
              marginLeft="10px"
              _hover={{ backgroundColor: "none" }}
              onClick={() => handleRemoveMap(index)}
            />
          </Box>
        </Box>
      ))}
      <Box>
        <Button
          variant="secondary"
          onClick={handleOnAppendField}
          isDisabled={fields.length === modelColumns.length || !stream}
          backgroundColor="#fff"
        >
          Add mapping
        </Button>
      </Box>
    </Box>
  );
};

export default MapFields;
