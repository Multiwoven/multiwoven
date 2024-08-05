import { Box, Icon, Spinner, Text } from '@chakra-ui/react';
import { CONNECTION_STATUS } from '@/views/Connectors/constant';
import { FiAlertOctagon, FiCheck } from 'react-icons/fi';
import { TestConnectionResponse } from '../types';

const STATUS_COLOR_MAP = {
  success: 'green.400',
  failed: 'red.400',
  loading: 'gray.800',
};

const STATUS_TEXT_COLOR = {
  success: 'success.500',
  failed: 'error.500',
  loading: 'black.100',
};

const ConnectorConnectionTest = ({
  connectionResponse,
  isFetching,
  connectorConfig,
  selectedConnectorSource,
}: {
  connectionResponse?: TestConnectionResponse;
  isFetching: boolean;
  connectorConfig: unknown;
  selectedConnectorSource: string;
}) => {
  return (
    <>
      {CONNECTION_STATUS.map(({ status }) => {
        const statusMetaInfo = status({
          data: connectionResponse,
          isLoading: isFetching,
          configFormData: connectorConfig,
          datasource: selectedConnectorSource,
        });

        return (
          <Box
            key={statusMetaInfo.text}
            display='flex'
            marginBottom='24px'
            alignItems='center'
            height='30px'
          >
            <Box>
              {statusMetaInfo.status === 'loading' ? (
                <Spinner
                  display='flex'
                  emptyColor='gray.400'
                  color='black.100'
                  height='20px'
                  width='20px'
                />
              ) : null}
              {statusMetaInfo.status === 'success' ? (
                <Box
                  display='flex'
                  alignItems='center'
                  justifyContent='center'
                  backgroundColor={STATUS_COLOR_MAP.success}
                  padding='5px'
                  borderRadius='50%'
                  height='20px'
                  width='20px'
                >
                  <Icon as={FiCheck} boxSize={4} color='gray.100' />
                </Box>
              ) : null}

              {statusMetaInfo.status === 'failed' ? (
                <Box
                  display='flex'
                  alignItems='center'
                  justifyContent='center'
                  backgroundColor={STATUS_COLOR_MAP.failed}
                  padding='5px'
                  borderRadius='50%'
                  height='20px'
                  width='20px'
                >
                  <Icon as={FiAlertOctagon} boxSize={4} color='gray.100' />
                </Box>
              ) : null}
            </Box>
            <Box marginLeft='10px'>
              <Text
                fontWeight='semibold'
                size='md'
                color={STATUS_TEXT_COLOR[statusMetaInfo.status]}
              >
                {statusMetaInfo.text}
              </Text>
            </Box>
          </Box>
        );
      })}
    </>
  );
};

export default ConnectorConnectionTest;
