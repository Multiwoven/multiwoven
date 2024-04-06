import {
  Stack,
  Tab,
  TabIndicator,
  TabList,
  Tabs,
  Box,
  Text,
  Checkbox,
  VStack,
} from '@chakra-ui/react';
import EntityItem from '@/components/EntityItem';
import { ConnectorItem } from '../Connectors/types';
import { useState } from 'react';
import NoConnectorsFound from '@/assets/images/empty-state-illustration.svg';

import Pagination from '@/components/Pagination';

const ITEMS_PER_PAGE = 6;

enum CONNECTOR_TYPE {
  ALL = 'all',
  DESTINATION = 'destination',
  SOURCE = 'source',
}

const TabName = ({ title, filterConnectors }: { title: string; filterConnectors: () => void }) => (
  <Tab
    _selected={{
      backgroundColor: 'gray.100',
      borderRadius: '4px',
      color: 'black.500',
    }}
    color='black.200'
    onClick={filterConnectors}
  >
    <Text size='xs' fontWeight='semibold'>
      {title}
    </Text>
  </Tab>
);

const ListConnectors = ({
  connectorsList,
  filteredConnectorsList,
  setFilteredConnectorsList,
  setCheckedConnectorIds,
  checkedConnectorIds,
}: {
  setFilteredConnectorsList: React.Dispatch<React.SetStateAction<ConnectorItem[] | undefined>>;
  setCheckedConnectorIds: React.Dispatch<React.SetStateAction<number[]>>;
  checkedConnectorIds: number[];
  connectorsList?: ConnectorItem[];
  filteredConnectorsList?: ConnectorItem[];
}): JSX.Element => {
  const [currentPage, setCurrentPage] = useState(1);

  // Calculate the start and end index of the items to display for the current page
  const startIndex = (currentPage - 1) * ITEMS_PER_PAGE;
  const endIndex = startIndex + ITEMS_PER_PAGE;

  // Slice the array to display only the items for the current page
  const currentPageConnectorsList = filteredConnectorsList?.slice(startIndex, endIndex);

  const totalPages = filteredConnectorsList
    ? Math.ceil(filteredConnectorsList?.length / ITEMS_PER_PAGE)
    : 1;

  const handleNextPage = () => {
    setCurrentPage((prevPage) => Math.min(prevPage + 1, totalPages));
  };

  const handlePrevPage = () => {
    setCurrentPage((prevPage) => Math.max(prevPage - 1, 1));
  };

  const filterConnectors = (filterBy: string) => {
    if (filterBy === 'all') {
      setFilteredConnectorsList(connectorsList);
      return;
    }

    const updatedFilteredConnectors = connectorsList?.filter(
      (connector) => connector?.attributes?.connector_type === filterBy,
    );
    setFilteredConnectorsList(updatedFilteredConnectors);
  };

  const handleCheckboxChange = (checked: boolean, connectorId: string) => {
    // If the checkbox is checked, add the connector ID to the list
    if (checked) {
      setCheckedConnectorIds((prevIds) => [...prevIds, +connectorId]);
    } else {
      // If the checkbox is unchecked, remove the connector ID from the list
      setCheckedConnectorIds((prevIds) => prevIds.filter((id) => id !== +connectorId));
    }
  };

  return (
    <Stack gap='12px'>
      <Stack spacing='16'>
        <Tabs
          size='md'
          variant='indicator'
          background='gray.300'
          padding={1}
          borderRadius='8px'
          borderStyle='solid'
          borderWidth='1px'
          borderColor='gray.400'
          width='352px'
        >
          <TabList gap='8px'>
            <TabName
              title='All Connectors'
              filterConnectors={() => filterConnectors(CONNECTOR_TYPE.ALL)}
            />
            <TabName
              title='By Destination'
              filterConnectors={() => filterConnectors(CONNECTOR_TYPE.DESTINATION)}
            />
            <TabName
              title='By Source'
              filterConnectors={() => filterConnectors(CONNECTOR_TYPE.SOURCE)}
            />
          </TabList>
          <TabIndicator />
        </Tabs>
      </Stack>
      <Box
        height='460px'
        backgroundColor='gray.100'
        width='352px'
        borderRadius='8px'
        borderStyle='solid'
        borderWidth='1px'
        borderColor='gray.400'
      >
        <Stack gap='12px' height='100%'>
          {currentPageConnectorsList?.length === 0 && (
            <VStack justify='center' height='100%'>
              <img src={NoConnectorsFound} alt='no-connectors-found' />
              <Text color='gray.600' size='xs' fontWeight='semibold'>
                No connectors found
              </Text>
            </VStack>
          )}
          {currentPageConnectorsList?.map((connector, index) => (
            <Box
              key={index}
              paddingY='10px'
              paddingX='16px'
              display='flex'
              gap='12px'
              _hover={{
                backgroundColor: 'gray.200',
              }}
            >
              <Checkbox
                isChecked={
                  checkedConnectorIds?.findIndex((connectorId) => connectorId === +connector.id) !==
                  -1
                }
                size='lg'
                borderColor='gray.300'
                _checked={{
                  '& .chakra-checkbox__control': {
                    background: 'brand.400',
                    borderColor: 'brand.400',
                  },
                  '& .chakra-checkbox__control:hover': {
                    background: 'brand.400',
                    borderColor: 'brand.400',
                  },
                }}
                onChange={({ target: { checked } }) => handleCheckboxChange(checked, connector.id)}
              />
              <EntityItem icon={connector?.attributes?.icon} name={connector?.attributes?.name} />
            </Box>
          ))}
        </Stack>
      </Box>
      <Pagination
        currentPage={currentPage}
        isNextPageEnabled={currentPage < totalPages}
        isPrevPageEnabled={currentPage > 1}
        handlePrevPage={handlePrevPage}
        handleNextPage={handleNextPage}
      />
    </Stack>
  );
};

export default ListConnectors;
