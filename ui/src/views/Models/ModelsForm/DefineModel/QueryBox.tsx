import { Button, Flex, HStack, Icon } from '@chakra-ui/react';

import { Box } from '@chakra-ui/react';
import RefreshModelCatalog from './RefreshModelCatalog';
import { FiEye } from 'react-icons/fi';
import SearchBar from '@/components/SearchBar/SearchBar';
import { SetStateAction } from 'react';
import { Dispatch } from 'react';

type QueryBoxProps = {
  connectorIcon: JSX.Element;
  connectorId: string;
  handleQueryRun: () => void;
  runQuery: boolean;
  loading: boolean;
  children: React.ReactNode;
  extra?: JSX.Element;
  showSearchBar?: boolean;
  setSearchTerm?: Dispatch<SetStateAction<string>>;
};

const QueryBox = ({
  connectorIcon,
  connectorId,
  handleQueryRun,
  runQuery,
  loading,
  children,
  extra,
  showSearchBar,
  setSearchTerm,
}: QueryBoxProps) => {
  return (
    <Box border='1px' borderColor='gray.400' w='full' minW='4xl' minH='100%' h='330px' rounded='xl'>
      <Flex bgColor='gray.200' roundedTop='xl' justifyContent='space-between' p='12px'>
        <Flex w='300px' alignItems='center'>
          {connectorIcon}
        </Flex>
        {showSearchBar && setSearchTerm && (
          <SearchBar
            setSearchTerm={setSearchTerm}
            placeholder='Search for tables'
            borderColor='white'
          />
        )}

        <HStack spacing={3}>
          <RefreshModelCatalog source_id={connectorId} />
          <Button
            variant='shell'
            size='sm'
            w='fit-content'
            fontSize='xs'
            onClick={handleQueryRun}
            isDisabled={!runQuery}
            isLoading={loading}
            display='flex'
            alignItems='center'
            gap={'8px'}
            px='16px'
            data-testid='query-run-button'
          >
            <Icon as={FiEye} />
            Show Preview
          </Button>
          {extra}
        </HStack>
      </Flex>
      <Box p={'8px'} w='100%' maxH='250px' bgColor='gray.100'>
        {children}
      </Box>
    </Box>
  );
};

export default QueryBox;
