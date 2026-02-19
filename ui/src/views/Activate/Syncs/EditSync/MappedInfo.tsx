import EntityItem from '@/components/EntityItem';
import { Box } from '@chakra-ui/react';
import { ArrowRightIcon } from '@heroicons/react/24/outline';

type Info = {
  name: string;
  icon: string;
};

type MappedInfo = Info[];

const MappedInfo = ({ info }: { info: MappedInfo }): JSX.Element => {
  const len = info.length;
  return (
    <Box display='flex' alignItems='center'>
      {info.map((item, index) => (
        <Box key={index} display='flex' alignItems='center'>
          <EntityItem icon={item.icon} name={item.name} />
          {index < len - 1 && (
            <Box width='55px' padding='20px' position='relative' color='gray.600'>
              <ArrowRightIcon />
            </Box>
          )}
        </Box>
      ))}
    </Box>
  );
};

export default MappedInfo;
