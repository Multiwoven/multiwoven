import {
  Box,
  Stack,
  TabList,
  Tab,
  Text,
  TabIndicator,
  Tabs,
  Popover,
  PopoverTrigger,
  PopoverContent,
  Input,
  Button,
} from '@chakra-ui/react';
import Columns from './Columns';
import { useQuery } from '@tanstack/react-query';
import { useState } from 'react';
import { getSyncsConfiguration } from '@/services/syncs';
import StaticOptions from './StaticOptions';
import TemplateOptions from './TemplateOptions';

export enum OPTION_TYPE {
  STANDARD = 'standard',
  STATIC = 'static',
  TEMPLATE = 'template',
}

type TemplateMappingProps = {
  entityName: string;
  isDisabled: boolean;
  columnOptions: string[];
  handleUpdateConfig: (
    id: number,
    type: 'model' | 'destination',
    value: string,
    mappingType?: OPTION_TYPE,
  ) => void;
  mappingId: number;
  selectedConfig?: string;
};

const TabName = ({ title, handleActiveTab }: { title: string; handleActiveTab: () => void }) => (
  <Tab
    _selected={{
      backgroundColor: 'gray.100',
      borderRadius: '4px',
      color: 'black.500',
    }}
    color='black.200'
    onClick={handleActiveTab}
    padding='6px 24px'
  >
    <Text size='xs' fontWeight='semibold'>
      {title}
    </Text>
  </Tab>
);

const TemplateMapping = ({
  entityName,
  isDisabled,
  columnOptions,
  handleUpdateConfig,
  mappingId,
  selectedConfig,
}: TemplateMappingProps): JSX.Element => {
  const [activeTab, setActiveTab] = useState(OPTION_TYPE.STANDARD);
  const [selectedTemplate, setSelectedTemplate] = useState('');
  const [isPopOverOpen, setIsPopOverOpen] = useState(false);
  const [selectedStaticOptionValue, setSelectedStaticOptionValue] = useState<string | boolean>('');

  const { data } = useQuery({
    queryKey: ['syncsConfiguration'],
    queryFn: () => getSyncsConfiguration(),
    refetchOnMount: true,
    refetchOnWindowFocus: false,
  });

  const staticValueOptions = Object.keys(
    data?.data?.configurations?.catalog_mapping_types?.static || {},
  );

  const templateFilterOptions = Object.keys(
    data?.data?.configurations?.catalog_mapping_types?.template?.filter || {},
  );

  const applyConfigs = () => {
    if (activeTab === OPTION_TYPE.TEMPLATE) {
      handleUpdateConfig(
        mappingId,
        'model',
        selectedTemplate > '' ? selectedTemplate : 'current_timestamp',
        activeTab,
      );
      setIsPopOverOpen(false);
    } else {
      handleUpdateConfig(
        mappingId,
        'model',
        selectedStaticOptionValue > '' ? selectedStaticOptionValue.toString() : 'null',
        activeTab,
      );
    }
    setIsPopOverOpen(false);
  };

  return (
    <Popover
      placement='bottom-start'
      isOpen={isPopOverOpen}
      onClose={() => setIsPopOverOpen(false)}
    >
      <PopoverTrigger>
        <Input
          placeholder={`Select a field from ${entityName}`}
          backgroundColor={isDisabled ? 'gray.300' : 'gray.100'}
          isDisabled={isDisabled}
          isRequired
          borderWidth='1px'
          borderStyle='solid'
          borderColor={isDisabled ? 'gray.500' : 'gray.400'}
          _placeholder={{ color: isDisabled ? 'black.500' : 'gray.600' }}
          value={selectedConfig}
          onClick={() => setIsPopOverOpen((prevState) => !prevState)}
        />
      </PopoverTrigger>
      <PopoverContent>
        <Box
          height='314px'
          width='100vw'
          maxWidth='768px'
          borderWidth={1}
          borderStyle='solid'
          borderColor='gray.400'
          position='absolute'
          backgroundColor='gray.100'
          zIndex={5}
          borderRadius='6px'
          padding='3'
          marginBottom={4}
          display='flex'
          flexDirection='column'
          flex='1 1 0%'
        >
          <Stack gap='12px' height='100%'>
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
                width='fit-content'
              >
                <TabList gap='8px'>
                  <TabName
                    title='Column'
                    handleActiveTab={() => setActiveTab(OPTION_TYPE.STANDARD)}
                  />
                  <TabName
                    title='Static Value'
                    handleActiveTab={() => setActiveTab(OPTION_TYPE.STATIC)}
                  />
                  <TabName
                    title='Template'
                    handleActiveTab={() => setActiveTab(OPTION_TYPE.TEMPLATE)}
                  />
                </TabList>
                <TabIndicator />
              </Tabs>
            </Stack>
            <Box backgroundColor='gray.100' height='100%'>
              {activeTab === OPTION_TYPE.STANDARD && (
                <Columns
                  columnOptions={columnOptions}
                  showFilter
                  onSelect={(value) => {
                    handleUpdateConfig(mappingId, 'model', value, activeTab);
                    setIsPopOverOpen(false);
                  }}
                />
              )}
              {activeTab === OPTION_TYPE.STATIC && (
                <StaticOptions
                  staticValues={staticValueOptions}
                  selectedStaticOptionValue={selectedStaticOptionValue}
                  setSelectedStaticOptionValue={setSelectedStaticOptionValue}
                />
              )}
              {activeTab === OPTION_TYPE.TEMPLATE && (
                <TemplateOptions
                  columnOptions={columnOptions}
                  filterOptions={templateFilterOptions}
                  catalogMapping={data}
                  selectedTemplate={selectedTemplate}
                  setSelectedTemplate={setSelectedTemplate}
                />
              )}
            </Box>
          </Stack>
          {(activeTab === OPTION_TYPE.STATIC || activeTab === OPTION_TYPE.TEMPLATE) && (
            <Box display='flex' width='100%' justifyContent='flex-end'>
              <Button onClick={applyConfigs} minWidth={0} width='auto'>
                Apply
              </Button>
            </Box>
          )}
        </Box>
      </PopoverContent>
    </Popover>
  );
};

export default TemplateMapping;
