import EntityItem from "@/components/EntityItem";
import { Box, Select } from "@chakra-ui/react";

type FieldMapProps = {
  fieldType: "model" | "destination";
  icon: string;
  entityName: string;
  options: string[];
  isDisabled: boolean;
  onChange: () => void;
};

const FieldMap = ({
  icon,
  entityName,
  options,
  isDisabled,
}: FieldMapProps): JSX.Element => {
  return (
    <Box width="100%">
      <Box marginBottom="10px">
        <EntityItem icon={icon} name={entityName} />
      </Box>
      <Box>
        <Select
          placeholder={`Select a field from ${entityName}`}
          backgroundColor="#fff"
          isDisabled={isDisabled}
        >
          {options.map((option) => (
            <option key={option}> {option}</option>
          ))}
        </Select>
      </Box>
    </Box>
  );
};

export default FieldMap;
