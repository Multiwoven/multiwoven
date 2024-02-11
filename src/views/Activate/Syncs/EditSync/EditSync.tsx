import ContentContainer from "@/components/ContentContainer";
import TopBar from "@/components/TopBar";
import { Box, Divider, Text, useToast } from "@chakra-ui/react";
import { EDIT_SYNC_FORM_STEPS } from "@/views/Activate/Syncs/constants";
import { useParams } from "react-router-dom";
import { useQuery } from "@tanstack/react-query";
import { getSyncById } from "@/services/syncs";
import Loader from "@/components/Loader";
import React, { useEffect, useState } from "react";
import MappedInfo from "./MappedInfo";
import moment from "moment";
import SelectStreams from "@/views/Activate/Syncs/SyncForm/ConfigureSyncs/SelectStreams";
import MapFields from "../SyncForm/ConfigureSyncs/MapFields";
import { getConnectorInfo } from "@/services/connectors";
import {
  DiscoverResponse,
  FinalizeSyncFormFields,
  Stream,
} from "@/views/Activate/Syncs/types";
import ScheduleForm from "./ScheduleForm";
import { FormikProps, useFormik } from "formik";

const EditSync = (): JSX.Element | null => {
  const [selectedStream, setSelectedStream] = useState<Stream | null>(null);
  const [configuration, setConfiguration] = useState<Record<
    string,
    string
  > | null>(null);
  const { syncId } = useParams();
  const toast = useToast();
  const {
    data: syncFetchResponse,
    isLoading,
    isError,
  } = useQuery({
    queryKey: ["sync", syncId],
    queryFn: () => getSyncById(syncId as string),
    refetchOnMount: false,
    refetchOnWindowFocus: false,
    enabled: !!syncId,
  });

  const syncData = syncFetchResponse?.data.attributes;

  const { data: destinationFetchResponse, isLoading: isConnectorInfoLoading } =
    useQuery({
      queryKey: ["sync", "destination", syncData?.destination.id],
      queryFn: () => getConnectorInfo(syncData?.destination.id as string),
      refetchOnMount: true,
      refetchOnWindowFocus: false,
      enabled: !!syncData?.destination.id,
    });

  const formik: FormikProps<FinalizeSyncFormFields> = useFormik({
    initialValues: {
      sync_mode: "full_refresh",
      sync_interval: 0,
      sync_interval_unit: "minutes",
      schedule_type: "automated",
    },
    onSubmit: (data) => {
      console.log("Submitted", configuration, data);
    },
  });

  useEffect(() => {
    if (isError) {
      toast({
        status: "error",
        title: "Error!!",
        description: "Something went wrong",
        position: "bottom-right",
        isClosable: true,
      });
    }
  }, [isError]);

  useEffect(() => {
    if (syncFetchResponse) {
      formik.setValues({
        sync_interval: syncData?.sync_interval ?? 0,
        sync_interval_unit: syncData?.sync_interval_unit ?? "minutes",
        sync_mode: syncData?.sync_mode ?? "full_refresh",
        schedule_type: syncData?.schedule_type ?? "automated",
      });
    }
  }, [syncFetchResponse]);

  const handleOnStreamsLoad = (catalog: DiscoverResponse) => {
    const { streams } = catalog.data.attributes.catalog;
    const selectedStream = streams.find(
      ({ name }) => name === syncData?.stream_name
    );
    if (selectedStream) {
      setSelectedStream(selectedStream);
    }
  };
  const handleOnConfigChange = (config: Record<string, string>) => {
    setConfiguration(config);
  };

  return (
    <form onSubmit={formik.handleSubmit}>
      <ContentContainer>
        <TopBar
          name="Sync"
          breadcrumbSteps={EDIT_SYNC_FORM_STEPS}
          extra={
            syncData?.model ? (
              <Box display="flex" alignItems="center">
                <MappedInfo
                  source={{
                    name: syncData?.model.connector.name,
                    icon: syncData?.model.connector.icon,
                  }}
                  destination={{
                    name: syncData?.destination.name,
                    icon: syncData?.destination.icon,
                  }}
                />
                <Divider
                  orientation="vertical"
                  height="24px"
                  borderColor="gray.600"
                  opacity="1"
                  marginX="13px"
                />
                <Text size="sm" fontWeight={600}>
                  Last updated :{" "}
                  <b>{moment(syncData.updated_at).format("DD/MM/YYYY")}</b>
                </Text>
              </Box>
            ) : null
          }
        />
        {(isLoading || isConnectorInfoLoading) && !syncData ? <Loader /> : null}
        {syncData && destinationFetchResponse?.data ? (
          <React.Fragment>
            <SelectStreams
              model={syncData?.model}
              destination={destinationFetchResponse?.data}
              onStreamsLoad={handleOnStreamsLoad}
              isEdit
            />
            <MapFields
              model={syncData?.model}
              destination={destinationFetchResponse?.data}
              stream={selectedStream}
              handleOnConfigChange={handleOnConfigChange}
              data={syncData.configuration}
              isEdit
            />
            <ScheduleForm formik={formik} />
          </React.Fragment>
        ) : null}
      </ContentContainer>
    </form>
  );
};

export default EditSync;
