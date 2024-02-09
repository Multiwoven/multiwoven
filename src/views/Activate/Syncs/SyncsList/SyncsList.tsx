import ContentContainer from "@/components/ContentContainer";
import TopBar from "@/components/TopBar";
import { fetchSyncs } from "@/services/syncs";
import { Badge, Box, Spinner, Text } from "@chakra-ui/react";
import { useQuery } from "@tanstack/react-query";
import { useMemo } from "react";
import { FiPlus } from "react-icons/fi";
import { useNavigate } from "react-router-dom";
import { SYNC_TABLE_COLUMS } from "../constants";
import { CreateSyncResponse, SyncColumnFields } from "../types";
import EntityItem from "@/components/EntityItem";
import Table from "@/components/Table";
import moment from "moment";
import Loader from "@/components/Loader";

type TableItem = {
  field: SyncColumnFields;
  data: CreateSyncResponse;
};

const TableItem = ({ field, data }: TableItem): JSX.Element => {
  switch (field) {
    case "model":
      return (
        <EntityItem
          icon={data.attributes.source.icon}
          name={data.attributes.source.connector_name}
        />
      );

    case "destination":
      return (
        <EntityItem
          icon={data.attributes.destination.icon}
          name={data.attributes.destination.connector_name}
        />
      );

    case "lastUpdated":
      return <Text>{moment().format("DD/MM/YYYY")}</Text>;

    case "status":
      return (
        <Badge colorScheme="green" variant="outline">
          Active
        </Badge>
      );
  }
};

const SyncsList = (): JSX.Element => {
  const navigate = useNavigate();
  const { data, isLoading } = useQuery({
    queryKey: ["activate", "syncs"],
    queryFn: () => fetchSyncs(),
    refetchOnMount: false,
    refetchOnWindowFocus: false,
  });

  const syncList = data?.data;

  const tableData = useMemo(() => {
    const rows = (syncList ?? [])?.map((data) => {
      return SYNC_TABLE_COLUMS.reduce(
        (acc, { key }) => ({
          [key]: <TableItem field={key} data={data} />,
          id: data.id,
          ...acc,
        }),
        {}
      );
    });

    return {
      columns: SYNC_TABLE_COLUMS,
      data: rows,
    };
  }, [data]);

  const handleOnSyncClick = (row: Record<"id", string>) => {
    navigate(`${row.id}`);
  };

  return (
    <Box width="100%" display="flex" flexDirection="column" alignItems="center">
      <ContentContainer>
        <TopBar
          name="Syncs"
          ctaName="Add sync"
          ctaIcon={<FiPlus color="gray.100" />}
          onCtaClicked={() => navigate("new")}
          ctaBgColor="orange.500"
          ctaColor="gray.900"
          ctaHoverBgColor="orange.400"
          isCtaVisible
        />
        {!syncList && isLoading ? (
          <Loader />
        ) : (
          <Table data={tableData} onRowClick={handleOnSyncClick} />
        )}
      </ContentContainer>
    </Box>
  );
};

export default SyncsList;
