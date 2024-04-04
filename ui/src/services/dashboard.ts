import { multiwovenFetch } from './common';

export type ReportObject = {
  time_slice: string;
  total_count: number;
  failed_count: number;
  success_count: number;
};

export type Report = {
  data: {
    sync_run_triggered: Array<ReportObject>;
    total_sync_run_rows: Array<ReportObject>;
  };
};

export type ReportTimePeriod = 'one_week' | 'one_day';

type ReportOptions = {
  metric?: 'sync_run_triggered' | 'total_sync_run_rows' | 'all';
  connector_ids?: Array<number>;
  time_period?: 'one_week' | 'one_day';
};

export const getReport = async ({
  metric = 'all',
  time_period = 'one_week',
  connector_ids = [],
}: ReportOptions): Promise<Report> => {
  const connectorIdsQueryParam = connector_ids.map((id) => `connector_ids[]=${id}`).join('&');
  const url = `/reports?type=workspace_activity&metric=${metric}&time_period=${time_period}&${connectorIdsQueryParam}`;

  return multiwovenFetch<null, Report>({
    method: 'get',
    url: url,
  });
};
