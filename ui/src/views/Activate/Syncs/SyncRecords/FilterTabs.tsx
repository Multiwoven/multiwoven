import { SyncRecordStatus } from '../types';
import { TabList } from '@chakra-ui/react';
import TabItem from '@/components/TabItem';

type FilterTabsType = {
  setFilter: (filterValue: SyncRecordStatus) => void;
};

export const FilterTabs = ({ setFilter }: FilterTabsType) => {
  return (
    <TabList gap='8px'>
      <TabItem text='Successful' action={() => setFilter(SyncRecordStatus.success)} />
      <TabItem text='Rejected' action={() => setFilter(SyncRecordStatus.failed)} />
    </TabList>
  );
};
