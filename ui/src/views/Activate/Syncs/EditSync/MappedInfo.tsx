import EntityItem from '@/components/EntityItem';
import { Box } from '@chakra-ui/react';
import { ArrowRightIcon } from '@heroicons/react/24/outline';

type MappedInfo = {
  source: {
    name: string;
    icon: string;
  };
  destination: {
    name: string;
    icon: string;
  };
};

const MappedInfo = ({ source, destination }: MappedInfo): JSX.Element => {
  return (
    <Box display='flex' alignItems='center'>
      <EntityItem icon={source.icon} name={source.name} />
      <Box width='55px' padding='20px' position='relative' color='gray.600'>
        <ArrowRightIcon />
      </Box>
      <EntityItem icon={destination.icon} name={destination.name} />
    </Box>
  );
};

export default MappedInfo;
