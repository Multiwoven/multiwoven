import { WorkspaceAPIResponse, getWorkspaces } from '@/services/settings';
import {
  Box,
  Popover,
  PopoverBody,
  PopoverContent,
  PopoverTrigger,
  Text,
  VStack,
} from '@chakra-ui/react';
import { useQuery } from '@tanstack/react-query';
import { FiChevronDown, FiCheck } from 'react-icons/fi';
import { useStore } from '@/stores';
import { useEffect, useState } from 'react';
import ManageWorkspaceModal from './ManageWorkspaceModal';
import { useNavigate } from 'react-router-dom';

const Workspace = () => {
  const [isPopOverOpen, setIsPopOverOpen] = useState(false);
  const navigate = useNavigate();

  const { data, refetch } = useQuery({
    queryKey: ['workspace'],
    queryFn: () => getWorkspaces(),
    refetchOnMount: false,
    refetchOnWindowFocus: false,
  });

  const workspaceData = data?.data;

  const activeWorkspaceId = useStore((state) => state.workspaceId);
  const setActiveWorkspaceId = useStore((state) => state.setActiveWorkspaceId);
  const activeWorkspaceDetails = workspaceData?.find?.(
    (workspace) => workspace?.id === activeWorkspaceId,
  );

  const handleWorkspaceSelect = (workspaceId: number) => {
    setActiveWorkspaceId(workspaceId);
    setIsPopOverOpen(false);

    // navigate to reports screen to reset the state of application
    navigate('/', { replace: true });
  };

  useEffect(() => {
    if (workspaceData && workspaceData.length > 0 && +activeWorkspaceId === 0) {
      setActiveWorkspaceId(workspaceData[0]?.id);
    }
  }, [workspaceData]);

  return (
    <>
      <Popover closeOnEsc isOpen={isPopOverOpen} onClose={() => setIsPopOverOpen(false)}>
        <PopoverTrigger>
          <Box cursor='pointer'>
            <Box
              bgColor='gray.300'
              px={2}
              py={2}
              rounded='lg'
              _hover={{ bgColor: 'gray.300' }}
              borderWidth='1px'
              borderColor='gray.400'
              borderStyle='solid'
            >
              <Box
                display='flex'
                justifyContent='space-between'
                alignItems='center'
                onClick={() => setIsPopOverOpen((prevState) => !prevState)}
              >
                <VStack spacing={0} align='start'>
                  <Box w='128px' maxW='128px'>
                    <Text size='xs' fontWeight={400} noOfLines={1} color='black.200'>
                      {workspaceData?.[0]?.attributes?.organization_name}
                    </Text>
                    <Text color='black.500' size='sm' fontWeight='semibold' noOfLines={1}>
                      {activeWorkspaceDetails?.attributes?.name}
                    </Text>
                  </Box>
                </VStack>
                <Box color='gray.600'>
                  <FiChevronDown />
                </Box>
              </Box>
            </Box>
          </Box>
        </PopoverTrigger>
        <PopoverContent width='207px' border='1px' borderColor='gray.400'>
          <PopoverBody margin={0} p={1}>
            <ManageWorkspaceModal
              workspaces={data as WorkspaceAPIResponse}
              refetchWorkspace={refetch}
            />
            {workspaceData?.map?.((workspace) => (
              <Box
                _hover={{ bgColor: 'gray.300' }}
                w='100%'
                py='8px'
                px='12px'
                display='flex'
                flexDir='row'
                alignItems='center'
                bgColor={activeWorkspaceId === workspace?.id ? 'gray.300' : ''}
                onClick={() => handleWorkspaceSelect(workspace?.id)}
                justifyContent='space-between'
                border={0}
                cursor='pointer'
                key={workspace?.id}
                borderRadius='4px'
              >
                <Text size='sm' fontWeight={400} color='black.500'>
                  {workspace?.attributes?.name}
                </Text>
                {activeWorkspaceId === workspace?.id && (
                  <Box color='brand.400'>
                    <FiCheck />
                  </Box>
                )}
              </Box>
            ))}
          </PopoverBody>
        </PopoverContent>
      </Popover>
    </>
  );
};

export default Workspace;
