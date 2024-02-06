import { Box, Image, Text } from "@chakra-ui/react";

type EntityItem = {
  icon: string;
  name: string;
};

const EntityItem = ({ icon, name }: EntityItem): JSX.Element => {
  return (
    <Box display="flex" alignItems="center">
      <Box
        height="40px"
        width="40px"
        marginRight="10px"
        borderWidth="thin"
        padding="5px"
        borderRadius="8px"
        backgroundColor="#fff"
      >
        <Image src={icon} alt="destination icon" maxHeight="100%" />
      </Box>
      <Text>{name}</Text>
    </Box>
  );
};

export default EntityItem;
