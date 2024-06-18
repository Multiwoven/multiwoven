import { ApiResponse } from '@/services/common';
import { SyncRecordResponse, SyncRecordStatus } from '../types';
import { TabList } from '@chakra-ui/react';
import TabItem from '@/components/TabItem';

type FilterTabsType = {
  setFilter: (filterValue: SyncRecordStatus) => void;
  syncRunRecords: ApiResponse<SyncRecordResponse[]> | undefined;
};

export const FilterTabs = ({ setFilter, syncRunRecords }: FilterTabsType) => {
  return (
    <TabList gap='8px'>
      <TabItem
        text='Successful'
        action={() => setFilter(SyncRecordStatus.success)}
        isBadgeVisible
        badgeText={syncRunRecords?.data
          ?.filter((record) => record.attributes.status === SyncRecordStatus.success)
          .length.toString()}
      />
      <TabItem
        text='Failed'
        action={() => setFilter(SyncRecordStatus.failed)}
        isBadgeVisible
        badgeText={syncRunRecords?.data
          ?.filter((record) => record.attributes.status === SyncRecordStatus.failed)
          .length.toString()}
      />
    </TabList>
  );
};
