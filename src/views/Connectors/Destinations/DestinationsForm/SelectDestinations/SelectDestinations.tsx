import { useQuery } from "@tanstack/react-query";
import { getConnectorsDefintions } from "@/services/connectors";
import { getDestinationCategories } from "@/views/Connectors/helpers";
import { useState } from "react";
import { Box, Text } from "@chakra-ui/react";
import ContentContainer from "@/components/ContentContainer";
import { ALL_DESTINATIONS_CATEGORY } from "@/views/Connectors/constant";

const SelectDestinations = (): JSX.Element => {
  const [selectedCategory, setSelectedCategory] = useState<string>(
    ALL_DESTINATIONS_CATEGORY
  );
  const { data } = useQuery({
    queryKey: ["datasources", "destination"],
    queryFn: () => getConnectorsDefintions("destination"),
    refetchOnWindowFocus: false,
    refetchOnMount: false,
    gcTime: Infinity,
  });

  const datasources = data?.data ?? [];
  const destinationCategories = getDestinationCategories(datasources);

  return (
    <Box display="flex" alignItems="center">
      <ContentContainer>
        <Box marginBottom="40px" display="flex" justifyContent="center">
          {destinationCategories.map((category) => {
            const isSelected = category === selectedCategory;
            return (
              <Box
                padding="10px 15px"
                borderRadius="100px"
                backgroundColor={isSelected ? "brand.400" : "none"}
                color={isSelected ? "#fff" : "none"}
                borderWidth={isSelected ? "none" : "thin"}
                marginRight="20px"
                cursor="pointer"
                _hover={{
                  backgroundColor: isSelected ? "brand.400" : "gray.100",
                }}
                onClick={() => setSelectedCategory(category)}
              >
                <Text>{category}</Text>
              </Box>
            );
          })}
        </Box>
        <Box display="flex" justifyContent="center">
          <Box display="grid" gridTemplateColumns="350px 350px 350px">
            {datasources.map((datasource) =>
              selectedCategory === ALL_DESTINATIONS_CATEGORY ||
              selectedCategory === datasource.category ? (
                <Box
                  marginX="20px"
                  display="flex"
                  borderWidth="thin"
                  padding="20px"
                  borderRadius="8px"
                  marginY="20px"
                  cursor="pointer"
                  _hover={{
                    backgroundColor: "gray.100",
                  }}
                >
                  <Text fontSize="md">{datasource.name}</Text>
                </Box>
              ) : null
            )}
          </Box>
        </Box>
      </ContentContainer>
    </Box>
  );
};

export default SelectDestinations;
