import { Box, Text, Stack, Divider, Tooltip, Image } from '@chakra-ui/react';
import { useState } from 'react';
import IconEntity from '@/components/IconEntity';
import { TbLayoutSidebarRightExpand, TbLayoutSidebarRightCollapse } from 'react-icons/tb';
import SearchBar from '@/components/SearchBar/SearchBar';
import EntityItem from '@/components/EntityItem';
import { FiMenu } from 'react-icons/fi';
import useAgentQueries from '@/enterprise/hooks/queries/useAgentQueries';

import { COMPONENT_CATEGORIES } from '../../constants';
import { FlowComponent } from '../../types';

const ComponentContainer = ({ component }: { component: FlowComponent }) => {
  return (
    <EntityItem
      icon={component.data.icon}
      name={component.data.label}
      iconWidth='16px'
      iconHeight='16px'
      iconContainerHeight='32px'
      iconContainerWidth='32px'
    />
  );
};

const Sidebar = ({
  handleDragEnd,
}: {
  handleDragEnd: (event: React.DragEvent<HTMLDivElement>, component: FlowComponent) => void;
}) => {
  const [searchTerm, setSearchTerm] = useState('');
  const [isCollapsed, setIsCollapsed] = useState(true);
  const { useGetWorkflowComponents } = useAgentQueries();
  const { data: workflowComponents } = useGetWorkflowComponents();

  const filteredComponents = workflowComponents?.schemas.filter((component) =>
    component?.data?.label?.toLowerCase()?.includes(searchTerm.toLowerCase()),
  );

  const toggleSidebar = () => {
    setIsCollapsed(!isCollapsed);
  };

  return (
    <Box
      display='flex'
      flexDirection='column'
      position={isCollapsed ? 'inherit' : 'absolute'}
      top={isCollapsed ? 0 : '16px'}
      left={isCollapsed ? 0 : '16px'}
      height={isCollapsed ? '100%' : 'fit-content'}
      minWidth={isCollapsed ? '330px' : '200px'}
      maxWidth={isCollapsed ? '330px' : '200px'}
      padding={isCollapsed ? '20px' : '16px'}
      border={isCollapsed ? 'none' : '1px solid'}
      borderRadius={isCollapsed ? 0 : '8px'}
      borderRight={'1px solid'}
      borderColor='gray.400'
      gap='20px'
      boxSizing='border-box'
      overflowY='auto'
      transition='all 0.3s ease'
      zIndex={3}
      bgColor='gray.100'
    >
      <Box
        display='flex'
        flexDirection='row'
        justifyContent='space-between'
        alignItems={isCollapsed ? 'start' : 'center'}
      >
        <Box display='flex' flexDirection='column' gap='4px'>
          <Text size='sm' fontWeight={600}>
            {' '}
            Components
          </Text>
          {isCollapsed && (
            <Text size='sm' color='black.100' fontWeight={400}>
              Select a component for your workflow
            </Text>
          )}
        </Box>

        <IconEntity
          icon={!isCollapsed ? TbLayoutSidebarRightExpand : TbLayoutSidebarRightCollapse}
          marginRight='0px'
          onClick={toggleSidebar}
          cursor='pointer'
        />
      </Box>

      {isCollapsed && (
        <>
          <SearchBar
            setSearchTerm={setSearchTerm}
            placeholder='Search components'
            borderColor='gray.400'
            data-testid='workflow-sidebar-search'
          />
          <Box>
            {COMPONENT_CATEGORIES.map((category, index) => {
              const categoryComponents = filteredComponents?.filter(
                (component) => component.data.category === category.value,
              );

              // Only render category if it has components matching the search
              if (categoryComponents?.length === 0) return null;

              return (
                <Box key={category.value} display='flex' flexDirection='column' gap='12px'>
                  <Text size='xs' color='gray.600' fontWeight={700} letterSpacing='2.4px'>
                    {category.name}
                  </Text>
                  <Stack spacing={3}>
                    {categoryComponents?.map((component) => (
                      <Tooltip
                        key={component.data.component}
                        label={
                          <Box>
                            <Box display='flex' flexDirection='row' gap='8px' alignItems='center'>
                              <Image
                                src={component.data.icon}
                                alt={component.data.label}
                                width='16px'
                                height='16px'
                              />
                              <Text fontWeight={600} size='sm'>
                                {component.data.label}
                              </Text>
                            </Box>
                            <Text size='sm' fontWeight={400} color='black.100'>
                              {component.data.description}
                            </Text>
                          </Box>
                        }
                        placement='right'
                        hasArrow
                        bg='white'
                        color='black'
                        boxShadow='md'
                        p={3}
                        borderRadius='md'
                        minW='220px'
                      >
                        <Box
                          padding='8px'
                          borderWidth='1px'
                          borderColor='gray.400'
                          borderRadius='8px'
                          backgroundColor='gray.200'
                          data-testid={`sidebar-component-${component.data.component}`}
                          cursor='grab'
                          _hover={{ bg: 'gray.300' }}
                          draggable
                          onDragEnd={(event) => {
                            handleDragEnd(event, component);
                          }}
                          display='flex'
                          flexDirection='row'
                          justifyContent='space-between'
                          alignItems='center'
                          role='group'
                        >
                          <ComponentContainer component={component} />
                          <Box color='gray.600' _groupHover={{ color: 'black.300' }}>
                            <FiMenu />
                          </Box>
                        </Box>
                      </Tooltip>
                    ))}
                  </Stack>
                  {index !== COMPONENT_CATEGORIES.length - 1 &&
                    categoryComponents?.length &&
                    categoryComponents?.length > 0 && (
                      <Divider borderColor='gray.400' marginBottom='20px' marginTop='8px' />
                    )}
                </Box>
              );
            })}
          </Box>
        </>
      )}
    </Box>
  );
};

export default Sidebar;
